# Test Karmada with Kind

> ref:
> - https://github.com/karmada-io/karmada
> - https://mp.weixin.qq.com/s/xPQbFSPgXtlhVNAL0-wfDg
> - https://zhuanlan.zhihu.com/p/379449374

## Install karmada control plane

```BASH
# clone repo
$ git clone https://github.com/karmada-io/karmada.git
$ cd karmada

# install karmada control plane
# using k8s v1.20.2 (optional)
$ export CLUSTER_VERSION="kindest/node:v1.20.2"
$ hack/local-up-karmada.sh

# during the waiting for the karmada-apiserver ready
# do these on another terminal
$ docker pull k8s.gcr.io/kube-apiserver:v1.19.1
$ kind load docker-image k8s.gcr.io/kube-apiserver:v1.19.1 --name karmada-host
$ docker pull k8s.gcr.io/kube-controller-manager:v1.19.1
$ kind load docker-image k8s.gcr.io/kube-controller-manager:v1.19.1 --name karmada-host

# After minutes, you can got this:
Local Karmada is running.

Kubeconfig for karmada in file: /root/.kube/karmada.config, so you can run:
  export KUBECONFIG="/root/.kube/karmada.config"
Or use kubectl with --kubeconfig=/root/.kube/karmada.config
Please use 'kubectl config use-context <Context_Name>' to switch cluster to operate, the following is context intro:
  ------------------------------------------------------
  |    Context Name   |          Purpose               |
  |----------------------------------------------------|
  | karmada-host      | the cluster karmada install in |
  |----------------------------------------------------|
  | karmada-apiserver | karmada control plane          |
  ------------------------------------------------------
```

## Install push cluster

```BASH
# Run at another terminal
$ export KUBECONFIG="/root/.kube/karmada.config"

# create a cluster member1
$ hack/create-cluster.sh member1 $HOME/.kube/karmada.config

# change context
$ kubectl config use-context karmada-apiserver

# install util
# need to add $GOPATH/bin to $PATH
$ go get github.com/karmada-io/karmada/cmd/karmadactl

# join cluster
$ karmadactl join member1 --cluster-kubeconfig=$HOME/.kube/karmada.config
```

## Install pull cluster

```BASH
# continue on push terminal
# create cluster member2
$ hack/create-cluster.sh member2 $HOME/.kube/karmada.config

# join cluster2
# hack/deploy-karmada-agent.sh <karmada_apiserver_kubeconfig> <karmada_apiserver_context_name> <member_cluster_kubeconfig> <member_cluster_context_name>
$ hack/deploy-karmada-agent.sh $HOME/.kube/karmada.config karmada-apiserver $HOME/.kube/karmada.config member2
```

## Testing

```BASH
$ export KUBECONFIG="/root/.kube/karmada.config"
$ kubectl config get-contexts
CURRENT   NAME                CLUSTER             AUTHINFO            NAMESPACE
          karmada-apiserver   karmada-apiserver   karmada-apiserver
          karmada-host        kind-karmada-host   kind-karmada-host
          member1             kind-member1        kind-member1
*         member2             kind-member2        kind-member2

$ kubectl config use-context karmada-apiserver
$ kubectl get clusters
NAME      VERSION   MODE   READY   AGE
member1   v1.20.2   Push   True    11m
member2   v1.20.2   Pull   True    3m36s

# load image
$ kind load docker-image nginx:alpine --name member1
$ kind load docker-image nginx:alpine --name member2

# ns will be automatically synchronized
$ kubectl create ns test
$ kubectl get ns --context member1 | grep test 
test                 Active   7s
$ kubectl get ns --context member2 | grep test 
test                 Active   10s
```

```yaml
---
# kubectl apply -f deploy.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:alpine
        imagePullPolicy: IfNotPresent
        name: nginx
        volumeMounts:
        - name: web-file
          mountPath: /usr/share/nginx/html/
      volumes:
      - name: web-file
        configMap:
          name: nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx
  labels:
    cm: app
data:
  foo: bar
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - name: http
      port: 80
      nodePort: 30080

---
# kubectl apply -f propagationpolicy.yaml
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: nginx-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: nginx
    - apiVersion: v1
      kind: ConfigMap
      labelSelector:
        matchLabels:
          cm: app
    - apiVersion: v1
      kind: Service
  placement:
    clusterAffinity:
      clusterNames:
        - member1
        - member2
---
```

```BASH
$ kubectl get po --context member2
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6966cf99fd-qtb4n   1/1     Running   0          6s
$ kubectl get po --context member1
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6966cf99fd-mnnvm   1/1     Running   0          8s

# cluster     ip
# member1     172.19.0.6
# member2     172.19.0.7
$ curl 172.19.0.6:30080/foo
bar
$ curl 172.19.0.7:30080/foo
bar
```

```yaml
# kubectl apply -f overridepolicy.yaml
---
apiVersion: policy.karmada.io/v1alpha1
kind: OverridePolicy
metadata:
  name: example-override
spec:
  resourceSelectors:
  - apiVersion: apps/v1
    kind: Deployment
    name: nginx
  targetCluster:
    clusterNames:
    - member1
  overriders:
    plaintext:
    - operator: replace
      path: /spec/replicas
      value: 2
    - operator: add
      path: /metadata/annotations
      value:
        foo: bar
    - operator: remove
      path: /spec/template/spec/containers/0/volumeMounts
```

```BASH
$ kubectl get po --context member1
NAME                     READY   STATUS    RESTARTS   AGE
nginx-5b79c848bf-g8gkn   1/1     Running   0          52s
nginx-5b79c848bf-tvzbh   1/1     Running   0          55s
$ kubectl get deploy --context member1
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   2/2     2            2           8m26s
$ curl 172.19.0.6:30080/foo
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
<hr><center>nginx/1.19.4</center>
</body>
</html>

$ kubectl get deploy nginx --context member1 -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "2"
    foo: bar
...
```

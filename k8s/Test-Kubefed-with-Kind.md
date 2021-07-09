# Test Kubefed with Kind

> ref:
> https://github.com/kubernetes-sigs/kubefed/blob/master/docs/installation.md
> https://github.com/kubernetes-sigs/kubefed/blob/master/docs/environments/kind.md
> https://github.com/kubernetes-sigs/kubefed/blob/master/charts/kubefed/README.md

## Installation

Install `kubefedctl`

```BASH
# get all releases here: https://github.com/kubernetes-sigs/kubefed/releases
$ wget https://github.com/kubernetes-sigs/kubefed/releases/download/v0.8.1/kubefedctl-0.8.1-linux-amd64.tgz
$ tar -zxvf kubefedctl-*.tgz
$ chmod u+x kubefedctl
$ sudo mv kubefedctl /usr/local/bin/    # make sure the location is in the PATH
# check it
$ kubefedctl version
kubefedctl version: version.Info{Version:"v0.8.1", GitCommit:"f6cd2fbb71c96dca1507ab22ca7cc611aa94b64a", GitTreeState:"clean", BuildDate:"2021-06-28T19:32:09Z", GoVersion:"go1.16.5", Compiler:"gc", Platform:"linux/amd64"}
```

Create clusters (If your kind is not ready, get more information here: https://kind.sigs.k8s.io/)

```BASH
$ wget https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/scripts/util.sh
$ wget https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/scripts/create-clusters.sh
$ chmod +x util.sh
$ chmod +x create-clusters.sh
# by default, the num is 2, the tag is the latest version
$ NUM_CLUSTERS=3 KIND_TAG=v1.20.2@sha256:8f7ea6e7642c0da54f04a7ee10431549c0257315b3a634f6ef2fecaaedb19bab ./create-clusters.sh
# If you get this error:
#   docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "process_linux.go:319: getting the final child's pid from pipe caused \"EOF\"": unknown.
# you can try `systemctl restart docker` and clear existing clusters by `kind delete cluster --name <cluster-name> && kubectl config delete-context <cluster-name>`
# and then retry the command.
# **ref**: https://stackoverflow.com/questions/66452096/starting-container-process-caused-process-linux-go303-getting-the-final-child

# check your kubectl context
$ kubectl config get-contexts
CURRENT   NAME                          CLUSTER         AUTHINFO           NAMESPACE
*         cluster1                      kind-cluster1   kind-cluster1
          cluster2                      kind-cluster2   kind-cluster2
          cluster3                      kind-cluster3   kind-cluster3

# prepare images
$ docker pull quay.io/kubernetes-multicluster/kubefed:v0.8.1
$ docker pull bitnami/kubectl:1.17.16
$ docker pull nginx:alpine
$ kind load docker-image quay.io/kubernetes-multicluster/kubefed:v0.8.1 --name cluster1
$ kind load docker-image bitnami/kubectl:1.17.16 --name cluster1
$ kind load docker-image nginx:alpine --name cluster1
$ kind load docker-image nginx:alpine --name cluster2
$ kind load docker-image nginx:alpine --name cluster3
```

Install `Controller Plan`

```BASH
# deploy by helm3
$ helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts
$ helm repo list
NAME            URL
kubefed-charts   https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts
$ helm --namespace kube-federation-system upgrade -i kubefed kubefed-charts/kubefed --version=0.8.1 --create-namespace
# helm install --namespace kube-federation-system kubefed kubefed-0.8.1.tgz --create-namespace
```

Join cluster

```BASH
# kubefedctl join <cluster-name> --cluster-context <context-to-be-add> --host-cluster-context <HOST-context>

# join host cluster
$ kubefedctl join c1 --cluster-context cluster1 --host-cluster-context cluster1 --v=2
# join other clusters
$ kubefedctl join c2 --cluster-context cluster2 --host-cluster-context cluster1 --v=2
$ kubefedctl join c3 --cluster-context cluster3 --host-cluster-context cluster1 --v=2

# check
$ kubectl -n kube-federation-system get kubefedclusters
NAME   AGE   READY
c1     14m   True
c2     18s   True
c3     6s    True
```

## Testing

**create namespace**

`kubectl apply -f fed-ns.yaml`

```yaml
# fed-ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: fed-test
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedNamespace
metadata:
  name: fed-test
  namespace: fed-test
spec:
  placement:
    clusters:
    - name: c1
    - name: c2
    - name: c3
```

**create configmap**

`kubectl apply -f fed-cm.yaml`

```yaml
# fed-cm.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedConfigMap
metadata:
  name: fed-cm
  namespace: fed-test
spec:
  placement:
    clusters:
    - name: c1
    - name: c2
  template:
    data:
      fed.how: very
      fed.type: charm
  overrides:
  - clusterName: c1
    clusterOverrides:
    - op: add
      path: "/data/foo"
      value: c1
    - op: remove
      path: "/data/fed.how"
    - path: "/data/fed.type"
      value: "aaaaaaaa"
```

**create deployment**

`kubectl apply -f fed-deploy.yaml`

```yaml
# fed-deploy.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: fed-deploy
  namespace: fed-test
spec:
  template:
    metadata:
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
            name: nginx
            volumeMounts:
            - name: web-file
              mountPath: /usr/share/nginx/html/
          volumes:
          - name: web-file
            configMap:
                name: fed-cm
  placement:
    clusters:
    - name: c1
    - name: c2
    - name: c3
  overrides:
  - clusterName: c3
    clusterOverrides:
    - path: "/spec/template/spec/containers/0/volumeMounts"
      op: "remove"
    - path: "/spec/template/spec/volumes"
      op: "remove"
  - clusterName: c2
    clusterOverrides:
    - path: "/spec/replicas"
      value: 2
```

**create service**

`kubectl apply -f fed-svc.yaml`

```yaml
# fed-svc.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedService
metadata:
  name: fed-svc
  namespace: fed-test
spec:
  template:
    spec:
      selector:
        app: nginx
      type: NodePort
      ports:
        - name: http
          port: 80
          nodePort: 30080
  placement:
    clusters:
    - name: c1
    - name: c2
    - name: c3
```

**verify**

```BASH
$ kubectl get po -n fed-test -owide --context cluster1
NAME                          READY   STATUS    RESTARTS   AGE   IP            NODE                     NOMINATED NODE   READINESS GATES
fed-deploy-6744c979d4-2lttl   1/1     Running   0          72s   10.244.0.16   cluster1-control-plane   <none>           <none>

$ kubectl get po -n fed-test -owide --context cluster2
NAME                          READY   STATUS    RESTARTS   AGE   IP           NODE                     NOMINATED NODE   READINESS GATES
fed-deploy-6744c979d4-54xql   1/1     Running   0          82s   10.244.0.5   cluster2-control-plane   <none>           <none>
fed-deploy-6744c979d4-8hrl7   1/1     Running   0          82s   10.244.0.6   cluster2-control-plane   <none>           <none>

$ kubectl get po -n fed-test -owide --context cluster3
NAME                          READY   STATUS    RESTARTS   AGE   IP           NODE                     NOMINATED NODE   READINESS GATES
fed-deploy-565785f75c-7fzjw   1/1     Running   0          89s   10.244.0.5   cluster3-control-plane   <none>           <none>

$ kubectl exec -i fed-deploy-6744c979d4-2lttl -n fed-test --context cluster1 -- ls /usr/share/nginx/html/
fed.type
foo

$ kubectl exec -i fed-deploy-6744c979d4-54xql -n fed-test --context cluster2 -- ls /usr/share/nginx/html/
fed.how
fed.type

$ kubectl exec -i fed-deploy-565785f75c-7fzjw -n fed-test --context cluster3 -- ls /usr/share/nginx/html/
50x.html
index.html

# clusterName       IP
# cluster1          172.19.0.5
# cluster2          172.19.0.6
# cluster3          172.19.0.7
$ kubectl get svc  -n fed-test --context cluster1
NAME      TYPE       CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
fed-svc   NodePort   10.96.8.120   <none>        80:30080/TCP   26s

$ kubectl get svc  -n fed-test --context cluster2
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
fed-svc   NodePort   10.96.239.65   <none>        80:30080/TCP   38s

$ kubectl get svc  -n fed-test --context cluster3
NAME      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
fed-svc   NodePort   10.96.236.62   <none>        80:30080/TCP   45s

$ curl 172.19.0.5:30080/fed.type
aaaaaaaa
$ curl 172.19.0.5:30080/foo
c1
$ curl 172.19.0.6:30080/fed.how
very
$ curl 172.19.0.6:30080/fed.type
charm
$ curl 172.19.0.7:30080
```

**update deployment scheduling**

`kubectl apply -f fed-rsp.yaml`

```yaml
# fed-rsp.yaml
apiVersion: scheduling.kubefed.io/v1alpha1
kind: ReplicaSchedulingPreference
metadata:
  name: fed-deploy # need to be same as FederatedDeployment
  namespace: fed-test
spec:
  targetKind: FederatedDeployment
  totalReplicas: 6
  clusters:
    c1:
      minReplicas: 2
      maxReplicas: 3
      weight: 1
    c2:
      minReplicas: 2
      maxReplicas: 5
      weight: 2
    c3:
      weight: 1
```

**after scheduling**

```BASH
$ kubectl get deploy -n fed-test -owide --context cluster1
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
fed-deploy   2/2     2            2           23h   nginx        nginx:alpine   app=nginx

$ kubectl get deploy -n fed-test -owide --context cluster2
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
fed-deploy   3/3     3            3           23h   nginx        nginx:alpine   app=nginx

$ kubectl get deploy -n fed-test -owide --context cluster3
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES         SELECTOR
fed-deploy   1/1     1            1           23h   nginx        nginx:alpine   app=nginx
```

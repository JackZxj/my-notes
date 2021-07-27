# kubefed rbac

实际上与在 k8s 上实现 rbac 没太多区别。参考 [k8s rbac实现租户隔离](../k8s%20rbac实现租户隔离.md)

```yaml
# kubectl apply -f fed-ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: fed-rbac
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedNamespace
metadata:
  name: fed-rbac
  namespace: fed-rbac
spec:
  placement:
    clusters:
    - name: c1
    - name: c2
    - name: c3


---
# kubectl apply -f deploy.yaml
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: nginx-rbac
  namespace: fed-rbac
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: nginx-rbac
      template:
        metadata:
          labels:
            app: nginx-rbac
        spec:
          containers:
          - image: nginx:alpine
            name: nginx-rbac
            ports:
            - containerPort: 80


---
# kubefedctl enable role
# kubefedctl enable RoleBinding
# kubectl apply -f rbac.yaml
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedRole
metadata:
  name: myrole
  namespace: fed-rbac
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    rules:
    - apiGroups: ["*"]
      resources: ["*"]
      verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
---
apiVersion: types.kubefed.io/v1beta1
kind: FederatedRoleBinding
metadata:
  name: myrole-rolebinding
  namespace: fed-rbac
spec:
  placement:
    clusterSelector:
      matchLabels: {}
  template:
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: myrole
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: User
      name: jack
```

创建证书和 kubeconfig (下面的方法按集群弄了3个 config 文件，需要切换不同的文件访问集群。你愿意的话也可以把每个集群的 ca 拷贝到同一个机器上然后在同一个 config 里创建访问)

```BASH
# cluster1
$ docker exec -it `docker ps -q -f name=cluster1-*` bash
$ openssl genrsa -out jack.key 2048
$ openssl req -new -key jack.key -out jack.csr -subj "/CN=jack/O=test"
$ openssl x509 -req -in jack.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out jack.crt -days 30
$ kubectl config set-credentials jack-c1 --client-certificate=jack.crt --client-key=jack.key --embed-certs=true  --kubeconfig config
$ kubectl config set-cluster kind-cluster1 --server=https://172.19.0.5:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig config
$ kubectl config set-context cluster1 --cluster=kind-cluster1 --user=jack-c1 --namespace=fed-rbac --kubeconfig config
$ kubectl config use-context cluster1 --kubeconfig config
$ kubectl get po --kubeconfig config
$ exit
# 有bug无法cp
# $ docker cp `docker ps -q -f name=cluster1-*`:/config ./c1-config
# $ docker exec -it `docker ps -q -f name=cluster1-*` bash
# $ cat config
# $ exit
# $ vi c1-config # then paste

# again in cluster2, cluster3
$ docker exec -it `docker ps -q -f name=cluster2-*` bash
$ openssl genrsa -out jack.key 2048
$ openssl req -new -key jack.key -out jack.csr -subj "/CN=jack/O=test"
$ openssl x509 -req -in jack.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out jack.crt -days 30
$ kubectl config set-credentials jack-c2 --client-certificate=jack.crt --client-key=jack.key --embed-certs=true  --kubeconfig config
$ kubectl config set-cluster kind-cluster2 --server=https://172.19.0.6:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig config
$ kubectl config set-context cluster2 --cluster=kind-cluster2 --user=jack-c2 --namespace=fed-rbac --kubeconfig config
$ kubectl config use-context cluster2 --kubeconfig config
$ kubectl get po --kubeconfig config
$ docker cp `docker ps -q -f name=cluster2-*`:/config ./c2-config
$ exit

$ docker exec -it `docker ps -q -f name=cluster3-*` bash
$ openssl genrsa -out jack.key 2048
$ openssl req -new -key jack.key -out jack.csr -subj "/CN=jack/O=test"
$ openssl x509 -req -in jack.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out jack.crt -days 30
$ kubectl config set-credentials jack-c3 --client-certificate=jack.crt --client-key=jack.key --embed-certs=true  --kubeconfig config
$ kubectl config set-cluster kind-cluster3 --server=https://172.19.0.7:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig config
$ kubectl config set-context cluster3 --cluster=kind-cluster3 --user=jack-c3 --namespace=fed-rbac --kubeconfig config
$ kubectl config use-context cluster3 --kubeconfig config
$ kubectl get po --kubeconfig config
$ docker cp `docker ps -q -f name=cluster3-*`:/config ./c3-config
$ exit

# 结果
$ kubectl get FederatedDeployment --kubeconfig c1-config
$ kubectl get deploy --kubeconfig c1-config
$ kubectl get deploy --kubeconfig c2-config
$ kubectl get deploy --kubeconfig c3-config
```

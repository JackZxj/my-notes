# k8s rbac实现租户隔离

## Role 和 ClusterRole

* Role 用于限制一个 namespace 下的资源, 使用 RoleBinding 绑定 User/Group/ServiceAccount
* ClusterRole 可以查看任意 namespace 下的资源, 使用 ClusterRoleBinding 绑定 User/Group/ServiceAccount
* User/Group/ServiceAccount 可以使用 RoleBinding 绑定到 ClusterRole，但只能访问 RoleBinding 对应的 namespace

## 基于 Role

在已有的k8s master上运行

``` BASH
$ mkdir testRBAC && cd testRBAC

# 创建新的 namespace
$ kubectl create ns test
# 在新 namespace 里创建一个 pod
$ kubectl run nginx --image=nginx:alpine -n test

#   ref: https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac
# 创建 Role 和 RoleBinding
$ cat > rbac.yaml <<EOF
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: test   # 上述新建的 ns
  name: myrole
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "watch", "list", "create", "update", "patch", "delete"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: myrole-rolebinding
  # RoleBinding 的名字空间决定了访问权限的授予范围。
  # 这里仅授权在 "test" 名字空间内的访问权限。
  namespace: test
subjects:
- kind: User
  name: jack    # 绑定的用户，下面会进行创建
  apiGroup: rbac.authorization.k8s.io
roleRef:        # 可以引用当前命名空间中的 Role 或全局命名空间中的 ClusterRole
  kind: Role
  name: myrole
  apiGroup: rbac.authorization.k8s.io
EOF
# 部署
$ kubectl apply -f rbac.yaml

# 创建证书
$ openssl genrsa -out jack.key 2048
# CN 是 common name
# O 是 Organization
#   ref: https://stackoverflow.com/a/58708162/14129013
# 注意，最后的 "/CN=jack" 中的 jack, 就是 User, "/O=test" 就是 Group
$ openssl req -new -key jack.key -out jack.csr -subj "/CN=jack/O=test"
$ openssl x509 -req -in jack.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out jack.crt -days 30
# 创建一个新的连接配置，保存到 config
$ kubectl config set-credentials jack --client-certificate=jack.crt --client-key=jack.key --embed-certs=true  --kubeconfig config
$ kubectl config set-cluster k8s --server=https://172.31.0.7:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig config
# 新建 context, 默认空间为 test
$ kubectl config set-context jack-context --cluster=k8s --user=jack --namespace=test --kubeconfig config
# 设置默认 context
$ kubectl config use-context jack-context --kubeconfig config

# 创建远程目录
# 192.168.122.242 需要提前安装好 kubectl
$ ssh 192.168.122.242 "mkdir /root/.kube"
$ scp config 192.168.122.242:/root/.kube

# 默认访问 test namespace
$ ssh 192.168.122.242 "kubectl get po"
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          44m

# 无法访问其他空间
$ ssh 192.168.122.242 "kubectl get po -n default"
Error from server (Forbidden): pods is forbidden: User "jack" cannot list resource "pods" in API group "" in the namespace "default"
```

## 基于 ClusterRole

在已有的k8s master上运行

``` BASH
$ cat > rbac-clusterrole.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pods-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
subjects:
- kind: Group
  name: test
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: pods-reader
  apiGroup: rbac.authorization.k8s.io
EOF
# 部署
$ kubectl apply -f rbac-clusterrole.yaml

# 可以读取其他 namespace 的 pod
$ ssh 192.168.122.242 "kubectl get po -n default"
NAME                                    READY   STATUS      RESTARTS   AGE
example-full-r-7b7d755d85-2dhnb         1/1     Running     0          3d5h
example-full-w-55dd96779f-kmxc5         1/1     Running     0          3d5h
```

## 参考

> https://stackoverflow.com/a/58708162/14129013
> https://kubernetes.io/zh/docs/reference/access-authn-authz/rbac
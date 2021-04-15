# k8s context manager

``` BASH
# 查看 k8s 配置
$ kubectl config view
# 等同于 cat ~/.kube/config ，不过上面的会隐藏认证信息

# 显示当前的 context
$ kubectl config current-context
# 设置 context
$ kubectl config use-context my-cluster-name

# 新增 context
$ kubectl config set-context my-context --user=cluster-admin --namespace=foo

# 新增一个 k8s 认证用户
$ kubectl config set-credentials --help
# 获取 e2e 用户的密码
$ kubectl config view -o jsonpath='{.users[?(@.name == "e2e")].user.password}'
```

# certs failed

x509: certificate is valid for 10.96.0.1, 172.31.0.73, not 10.110.26.200

```BASH
# 备份
$ cp -r /etc/kubernetes/pki /etc/kubernetes/pki-bak

# 新建全部的证书
# 全部证书参考 https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta2
# k8s-init.yaml 中添加ip列表
# apiServer:
#   extraArgs:
#     authorization-mode: "Node,RBAC"
#   timeoutForControlPlane: 4m0s
#   certSANs:       # 添加这一项内容以支持其他ip访问
#   - "172.31.0.73" 
#   - "10.110.26.200"
$ kubeadm alpha certs renew all --config k8s-init.yaml
# 重启apiserver
$ docker rm -f `docker ps -q -f 'name=k8s_kube-apiserver*'`
# 重启 kubelet
$ systemctl restart kubelet
# 更新k8s config
$ cp /etc/kubernetes/admin.conf ~/.kube/config
# 验证正常
$ kubectl get no
$ curl https://10.110.26.200:6443/version --cacert /etc/kubernetes/pki/ca.crt
{
  "major": "1",
  "minor": "18",
  "gitVersion": "v1.18.3",
  "gitCommit": "2e7996e3e2712684bc73f0dec0200d64eec7fe40",
  "gitTreeState": "clean",
  "buildDate": "2020-05-20T12:43:34Z",
  "goVersion": "go1.13.9",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

## 20210918 更新

今天操作的时候发现 renew 后并没有生效，更新后的证书还是不支持额外的 ip 访问，不知道是环境的问题还是 bug

解决的办法: 

> 参考: https://www.jianshu.com/p/35ac252b5045

```BASH
# 第一步和上面的一样，修改 k8s-init.yaml，添加额外的 IP
# 第二步备份原来的 apiserver 证书
$ mv /etc/kubernetes/pki/apiserver.{crt,key} ~
# 第三步重建 apiserver 证书
$ kubeadm init phase certs apiserver --config kubeadm-init.yaml
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [ecs-20210916101324-0002 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.110.32.240 172.31.0.246]
# 最后就是重启 apiserver
$ docker rm -f `docker ps -q -f 'name=k8s_kube-apiserver*'`
```

验证 apiserver 证书添加了额外的访问地址

```BASH
$ openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text | grep DNS
                DNS:ecs-20210916101324-0002, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, IP Address:10.96.0.1, IP Address:10.110.32.240, IP Address:172.31.0.246
```

更新了证书了的话还需要将相关的信息上传到 `kube-system` 命名空间下，这样以后使用 kubeadm 升级k8s集群时能够保留证书IP

```BASH
# 上传 config
$ kubeadm init phase upload-config kubeadm --config kubeadm-init.yaml
# 查看该 config
$ kubectl -n kube-system get configmap kubeadm-config -o yaml
```

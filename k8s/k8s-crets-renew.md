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

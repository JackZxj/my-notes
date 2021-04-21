# Calico 网络无法用服务名访问服务

环境：

* ubuntu 18.04
* k8s v1.20.5
* calico 1.18

## Calico 安装

参考 https://docs.projectcalico.org/getting-started/kubernetes/quickstart

``` BASH
$ wget https://docs.projectcalico.org/manifests/tigera-operator.yaml
$ wget https://docs.projectcalico.org/manifests/custom-resources.yaml
# 修改网络范围
$ vi custom-resources.yaml
# 部署
$ kubectl apply -f tigera-operator.yaml
$ kubectl apply -f custom-resources.yaml
```

## 无法用服务名访问服务

具体表现的问题为: 

* 无法用 `service_name..default.svc.cluster.local` 访问部署的服务
* `kubectl get po -n calico-system -owide` 发现 master 上的 calico node 不是 ready 状态
* `kubectl describe po calico-node-vr5hl -n calico-system` 结尾显示 `calico/node is not ready: BIRD is not ready: BGP not established with ...`

debug 过程可参考 https://blog.csdn.net/nklinsirui/article/details/109424100

**解决方法:**

修改 `custom-resources.yaml` :

``` yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.projectcalico.org/v3.18/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 26
      # 修改此处为 k8s 网络范围
      cidr: 10.244.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
    # 下面这两句不是默认的
    # 如果出现 calico/node is not ready: BIRD is not ready: BGP not established with ...
    # 添加下面两句， interface 的值写主机的网络设备前缀，一般 eth.* 或者 ens.*
    nodeAddressAutodetectionV4:
      interface: ens.*
```

重新创建 Calico 网络

``` BASH
$ kubectl delete -f custom-resources.yaml
$ kubectl apply -f custom-resources.yaml
```

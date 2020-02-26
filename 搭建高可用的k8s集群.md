# 搭建高可用的 k8s 集群

## 需要高可用的组件

- etcd
- kube-apiserver
- kube-scheduler, kube-controller-manager, kube-proxy, kubedns...

高可用方案：

### etcd

![独立 etcd](https://github.com/JackZxj/my-notes/blob/master/images/%E6%90%AD%E5%BB%BA%E9%AB%98%E5%8F%AF%E7%94%A8%E7%9A%84k8s%E9%9B%86%E7%BE%A4/etcd01.png)
一是使用独立的 etcd 集群，使用 3 台或者 5 台服务器只运行 etcd，独立维护和升级。甚至可以使用 CoreOS 的 update-engine 和 locksmith，让服务器完全自主的完成升级。这个 etcd 集群将作为基石用于构建整个集群。 采用这项策略的主要动机是 etcd 集群的节点增减都需要显式的通知集群，保证 etcd 集群节点稳定可以更方便的用程序完成集群滚动升级，减轻维护负担。

![k8s etcd](https://raw.githubusercontent.com/JackZxj/my-notes/master/images/%E6%90%AD%E5%BB%BA%E9%AB%98%E5%8F%AF%E7%94%A8%E7%9A%84k8s%E9%9B%86%E7%BE%A4/etcd02.png)
二是在 Kubernetes Master 上用 static pod 的形式来运行 etcd，并将多台 Kubernetes Master 上的 etcd 组成集群。 在这一模式下，各个服务器的 etcd 实例被注册进了 Kubernetes 当中，虽然无法直接使用 kubectl 来管理这部分实例，但是监控以及日志搜集组件均可正常工作。在这一模式运行下的 etcd 可管理性更强。

![self-hosted etcd](https://raw.githubusercontent.com/JackZxj/my-notes/master/images/%E6%90%AD%E5%BB%BA%E9%AB%98%E5%8F%AF%E7%94%A8%E7%9A%84k8s%E9%9B%86%E7%BE%A4/etcd03.png)
三是使用 CoreOS 提出的 self-hosted etcd 方案，将本应在底层为 Kubernetes 提供服务的 etcd 运行在 Kubernetes 之上。 实现 Kubernetes 对自身依赖组件的管理。在这一模式下的 etcd 集群可以直接使用 etcd-operator 来自动化运维，最符合 Kubernetes 的使用习惯。

### apiserver

一是使用外部负载均衡器，不管是使用公有云提供的负载均衡器服务或是在私有云中使用 LVS 或者 HaProxy 自建负载均衡器都可以归到这一类。 负载均衡器是非常成熟的方案，在这里略过不做过多介绍。如何保证负载均衡器的高可用，则是选择这一方案需要考虑的新问题。

二是在网络层做负载均衡。比如在 Master 节点上用 BGP 做 ECMP，或者在 Node 节点上用 iptables 做 NAT 都可以实现。采用这一方案不需要额外的外部服务，但是对网络配置有一定的要求。

三是在 Node 节点上使用反向代理对多个 Master 做负载均衡。这一方案同样不需要依赖外部的组件，但是当 Master 节点有增减时，如何动态配置 Node 节点上的负载均衡器成为了另外一个需要解决的问题。

### others

可以依赖 kubernetes 本身的 pod 多副本实现。

## HA(High Availability) k8s

选择 kubeadm 一键安装 etcd，采用 Haproxy 做负载均衡, keepalived 做浮动 ip。

env：
- Vmware Virtual Machine * 4
  - CPU Core: 1
  - RAM: 2Gi
  - Disk: 40Gi
- Clusters
  - master * 3 (as node)
  - node * 1
- Support
  - k8s: v1.15.3
  - docker: v19.03.5

### All master

``` bash
# haproxy configuration
mkdir -p /etc/kubernetes
cat > /etc/kubernetes/kube-haproxy.cfg << EOF
global
  log 127.0.0.1 local0 err
  maxconn 50000
  uid 99
  gid 99
  #daemon             # 以后台形式运行haproxy
  nbproc 1            # 启动1个haproxy实例。# #工作进程数量(CPU数量) ，实际工作中，应该设置成和CPU核心数一样。 这样可以发挥出最大的性能。
  pidfile haproxy.pid # 将所有进程写入pid文件

defaults
  mode http
  log 127.0.0.1 local0 err
  maxconn 50000
  retries 3
  timeout connect 5s
  timeout client 30s
  timeout server 30s
  timeout check 2s

listen stats
  mode http
  bind 0.0.0.0:9090
  log 127.0.0.1 local0 err
  stats refresh 30s
  stats uri /haproxy-status
  stats realm Haproxy\ Statistics
  stats auth admin:admin123
  stats hide-version
  stats admin if TRUE

frontend kube-apiserver-https
  mode tcp
  bind :6443                              # 负载平衡的端口
  default_backend kube-apiserver-backend

backend kube-apiserver-backend
  mode tcp
  balance roundrobin
  server apiserver1 192.168.122.44:6443 weight 3 minconn 100 maxconn 50000 check inter 5000 rise 2 fall 5     # ip 要改为 master1 的ip
  server apiserver2 192.168.122.208:6443 weight 3 minconn 100 maxconn 50000 check inter 5000 rise 2 fall 5     # ip 要改为 master2 的ip
  server apiserver3 192.168.122.175:6443 weight 3 minconn 100 maxconn 50000 check inter 5000 rise 2 fall 5     # ip 要改为 master3 的ip
EOF

# haproxy & keeplived yaml
mkdir -p /etc/kubernetes/manifests
cat > /etc/kubernetes/manifests/kube-haproxy.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: haproxy
    tier: control-plane
  name: kube-haproxy
  namespace: kube-system
spec:
  hostNetwork: true
  priorityClassName: system-cluster-critical
  containers:
  - name: kube-haproxy
    image: haproxy:2.1.0-alpine
    volumeMounts:
    - name: haproxy-cfg
      readOnly: true
      mountPath: /usr/local/etc/haproxy/haproxy.cfg
    resources:
      requests:
        cpu: 100m
  volumes:
  - name: haproxy-cfg
    hostPath:
      path: /etc/kubernetes/kube-haproxy.cfg
EOF

cat > /etc/kubernetes/manifests/kube-keepalived.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  annotations:
    scheduler.alpha.kubernetes.io/critical-pod: ""
  labels:
    component: keepalived
    tier: control-plane
  name: kube-keepalived
  namespace: kube-system
spec:
  hostNetwork: true
  priorityClassName: system-cluster-critical
  containers:
  - name: kube-keepalived
    image: docker.io/osixia/keepalived:2.0.19
    env:
    - name: KEEPALIVED_VIRTUAL_IPS
      value: 192.168.122.100        # 浮动 ip， 用于多 master 高可用
    - name: KEEPALIVED_INTERFACE
      value: ens33                  # 应该修改为几台master之间用于通信的网卡名
    - name: KEEPALIVED_UNICAST_PEERS
      value: "#PYTHON2BASH:['192.168.122.44','192.168.122.208','192.168.122.175']"     # master 节点列表
    - name: KEEPALIVED_PASSWORD
      value: docker
    - name: KEEPALIVED_PRIORITY
      value: "100"
    - name: KEEPALIVED_ROUTER_ID
      value: "51"
    resources:
      requests:
        cpu: 100m
    securityContext:
      privileged: true
      capabilities:
        add:
        - NET_ADMIN
EOF

```

### Master1

``` bash
cat > kube-init.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.15.3
controlPlaneEndpoint: "10.164.17.100:6443"                    # master 负载平衡 ip，就是上面的浮动 ip + haproxy 的端口
apiServer:
  extraArgs:
    authorization-mode: "Node,RBAC"
  timeoutForControlPlane: 4m0s
  certSANs:
  - "10.164.17.100"             # 负载平衡 IP
networking:
  podSubnet: "10.253.0.0/16"        # 修改为目标网络插件的地址
imageRepository: "registry.aliyuncs.com/google_containers"      # 安装镜像仓库的地址
EOF

# init master
kubeadm init --config kube-init.yaml --upload-certs
```
``` text
···
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 10.164.17.100:8443 --token tyrs3f.d3z2gd231sj21nck \
    --discovery-token-ca-cert-hash sha256:00c26bf8352ffc6094ac93a2230ab5d13b49c038792ff1f74d6f1417dae0c7ba \
    --control-plane --certificate-key 2e0a4b8b9c96625e62d94f7784b5a5cf8f2256eed707377b5208931284046eff

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use 
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.164.17.100:8443 --token tyrs3f.d3z2gd231sj21nck \
    --discovery-token-ca-cert-hash sha256:00c26bf8352ffc6094ac93a2230ab5d13b49c038792ff1f74d6f1417dae0c7ba 
```

``` bash
# kubectl config
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 在第一个master上使用如下命令生成加入新master所需的证书密钥（生成中附带了一些说明，只需取最后一行的hash值即可）
kubeadm init phase upload-certs --upload-certs > join-k8s-master-certificate-key.txt

# 生成加master的指令
echo `kubeadm token create --print-join-command` --control-plane --certificate-key `tail -n 1 join-k8s-master-certificate-key.txt` --ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests

```

### Other master

``` bash
# join master1
kubeadm join 192.168.122.100:6443 --token ohf0yg.zk0nrhrldxmwh272 --discovery-token-ca-cert-hash sha256:747c214cf08d35f51a303255382c47eaf77639e01ca0d60cf64ab937a7dc14b9 --control-plane --certificate-key 33dd2e73ebecd24ab82423c8449bb7541dc2881bd45d22676fb3b9a35c3c4f17 --ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests

# After success
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Add node
``` bash
kubeadm join 10.164.17.100:8443 --token tyrs3f.d3z2gd231sj21nck \
    --discovery-token-ca-cert-hash sha256:00c26bf8352ffc6094ac93a2230ab5d13b49c038792ff1f74d6f1417dae0c7ba 
```
## 前言

k8s 全称为 kubernetes，是一个由谷歌开发并开源的，用于管理云平台中多主机上服务容器化的应用。可以参考的资料有：

* [Kubernetes 中文社区 | 中文文档](http://docs.kubernetes.org.cn/)
* [Kubernetes 指南 | GitBook](https://legacy.gitbook.com/book/feisky/kubernetes/details)

-------------------------------

## 准备工作

### 安装操作系统

k8s 的集群至少需要3台主机，其中一台为 master 节点，另外的两台为 node 节点。本次安装使用 VMware 虚拟机安装，操作系统采用 CentOS Linux release 7.3.1611 ( 可以通过 `cat /etc/centos-release` 查看当前的发行版本 )，安装过程省略。node 节点可以采用最小化安装，master 节点根据需求可以最小化安装也可以全量安装。

### 配置虚拟机为静态 IP

Q: 为啥要配置虚拟机为静态 IP？
A: 因为 k8s 的服务集群内的主机 IP 如果是随机分配的话，在集群内的主机就互相找不到了（摊手）

1、VMware 安装虚拟机的时候默认是 NAT 模式，如果被修改过，可通过 `编辑-虚拟网络编辑器-VMnet8` 下勾选 NAT 模式开启。

2、在上一步的窗口的下方填写子网 IP，格式为 `192.168.*.0`，例如我的子网 IP 为 192.168.189.0，同时填写子网掩码为 `255.255.255.0`。

3、点击 `NAT设置` 按钮，修改网关 IP 为 `192.168.*.*`，需要与子网同一网段，例如我的网关为 192.168.189.2，点击确定

4、（**可选步骤**）取消勾选 `使用本地DHCP服务将 IP 地址分配给虚拟机`（取消后使用 NAT 连接方式新建的虚拟机都不会再自动分配 IP，需要通过手动设置分配 IP）

5、点击确定按钮保存 VMnet8 的相关配置

6、控制面板-查看网络状态和任务-更改适配器设置-VMware Network Adapter VMnet8-（右键）属性-Internet 协议版本 4(TCP/IPv4)：
* 勾选 `使用下面的 IP 地址`，在 IP 地址中填入 `192.168.*.*`，需要与上述子网同一网段，例如我的 IP 地址为 192.168.189.1，填写子网掩码为 `255.255.255.0`，填写默认网关为第3步设置的网关，例如我的网关为 192.168.189.2
* 勾选 `使用下面的 DNS 服务器地址`，分别填入 `8.8.8.8`，`114.114.114.114`
* 点击确认保存设置

7、进入 linux 系统：
* 命令行输入 `ifconfig` 查询本地网络连接
* 一般来说连接名为 ens33 或者 eth0 之类的就是本机的网卡配置了。确定了本机的网卡名称后，通过命令行输入 `vi /etc/sysconfig/network-scripts/ifcfg-ens33` 修改网络配置。修改内容如下后保存。
``` bash
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=ens33
UUID=32d0b554-bec8-4c6f-b1dd-4894a3321378
DEVICE=ens33
ONBOOT=yes
IPADDR=192.168.189.3
GATEWAY=192.168.189.2
NETMASK=255.255.255.0
DNS1=192.168.189.2
```
注意：BOOTPROTO 改为 static；UUID 每台机子不同，不用修改；ONBOOT 设置开机自启；IPADDR 为手动配置的当前主机的 IP 地址；GATEWAY 为前面设置的网关地址；NETMASK 为子网掩码；DNS1 随网关 IP 即可。
* `service network restart` 重启网络
* 按照上述步骤将3台主机配置好，注意3台主机的 IP 不能相同。配置完成后使用 `ping 192.168.*.*` 命令确认三台主机之间网络能够互联则说明配置成功。

### 关闭 Linux 防火墙

* 关闭并禁用防火墙
``` bash
systemctl stop firewalld && systemctl disable firewalld
```
* 禁用SELINUX
``` bash
setenforce 0
# 永久禁用 需要重启生效
sudo sed -i 's/\(^SELINUX=\)\(enforcing\|permissive\)/\1disabled/' /etc/selinux/config
```
* 禁用SWAP
``` bash
swapoff -a
# 永久禁用的话在此基础上将 /etc/fstab 中 swap的那一行注释了即可
```
### k8s 准备配置

* 创建 `/etc/sysctl.d/k8s.conf` 文件，添加如下内容：
``` text
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```
* 执行如下命令生效配置
``` bash
modprobe br_netfilter

sysctl -p /etc/sysctl.d/k8s.conf
```

### 修改主机名称（可选）

* 设置 hostname
``` bash
hostnamectl set-hostname k8s-master
```
* 设置 IP 主机名
在 /etc/hosts 文件末尾追加 `192.168.*.* k8s-master`， IP 地址为当前主机的 IP 地址，后面的名称可以根据需求改。
* 对另外两台 node 节点也做同样的设置。

修改配置后重启系统就可以看到了。如果使用 SSH 远程连接的话，断开重连也能看到成功修改。

------------------------------------------------

## 安装 Docker

详见 [Docker 安装教程]()一文，此处不再重复。

## 安装 Kubernetes

### 安装 kubelet kubeadm kubectl

* 新建 `/etc/yum.repos.d/kubernetes.repo` 文件，在文件中写入如下内容:
``` text
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
```
* 使用 yum 安装
``` bash
yum makecache fast

yum install -y kubelet kubeadm kubectl
```
* 启动 kubelet
``` bash
systemctl start kubelet && systemctl enable kubelet
```

集群中的三台主机都是按照这个步骤执行。

### 创建 master 节点

``` bash
kubeadm init --pod-network-cidr=10.244.0.0/16 --image-repository=registry.aliyuncs.com/google_containers
```
* --pod-network-cidr = 指定Pod网络的IP地址范围。 我们正在使用'flannel'虚拟网络。 如果要使用其他pod网络（如weave-net或calico），请更改范围IP地址。[参考文档](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)
* --image-repository ：指定镜像仓库

* 如果成功了，则输出如下信息：
``` bash
······ 太长省略 ······
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstraptoken] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstraptoken] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstraptoken] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstraptoken] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  /docs/concepts/cluster-administration/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

* 将上文中提到的指令输入到命令行
``` bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 创建 node 节点

* 切换到 root 用户
* 运行 master 节点初始化的最后一行 `kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>` 。例如我的 master 节点返回的结果：
```
kubeadm join 192.168.189.3:6443 --token w6emtd.u350k9ts17b8mmmz \
    --discovery-token-ca-cert-hash sha256:9d9112ab9d0d2fd03eba7a34796e32dc5f77a3e8251e60359f298d794efc0228
```
直接在 node 节点中运行上述命令即可。
* 如果忘记保存上述的 token 命令，可以使用 `kubeadm token list` 命令来获取，输出结果类似于：
```
TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION                                                EXTRA GROUPS
w6emtd.u350k9ts17b8mmmz   23h        2019-08-08T18:53:49+08:00   authentication,signing   The default bootstrap token generated by 'kubeadm init'.   system:bootstrappers:kubeadm:default-node-token
```
默认情况下，令牌有效期为24小时。如果当前令牌已经过期，则可以通过在 master 节点上运行 `kubeadm token create` 命令来创建新令牌，输出的结果类似于 `5didvk.d09sbcov8ph2amjw`
* 如果没有 `--discovery-token-ca-cert-hash` 的值，则可以通过在 master 节点上运行以下命令来生成：
```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
   openssl dgst -sha256 -hex | sed 's/^.* //'
```
生成的结果类似于 `9d9112ab9d0d2fd03eba7a34796e32dc5f77a3e8251e60359f298d794efc0228`，可以看到就是前面初始化 master 时返回的结果。

* **一步生成指令**
在 master 节点中执行 `kubeadm token create --print-join-command` 直接返回
``` bash
kubeadm join 192.168.189.3:6443 --token pjuvf8.zuzdz9vr4j2hqvmb     --discovery-token-ca-cert-hash sha256:9d9112ab9d0d2fd03eba7a34796e32dc5f77a3e8251e60359f298d794efc0228 
```

### 查看集群

在节点都连接上 master 节点后，在 master 节点输入 `kubectl get nodes` 就能看到已经成功运行的 k8s 集群。
```
NAME                    STATUS     ROLES    AGE    VERSION
k8s-node1               Ready      <none>   7h4m   v1.15.2
k8s-node2               NotReady   <none>   9s     v1.15.2
localhost.localdomain   Ready      master   21h    v1.15.2

--- minutes later ---

NAME                    STATUS   ROLES    AGE     VERSION
k8s-node1               Ready    <none>   7h21m   v1.15.2
k8s-node2               Ready    <none>   17m     v1.15.2
localhost.localdomain   Ready    master   21h     v1.15.2
```
当所有的节点都为 `Ready` 状态时，说明部署成功了。

### 节点部署失败

可以尝试使用 `kubeadm reset` 命令删除了节点再重新初始化或者重新连接 master 节点。

----------------------------------

## Question

### Error: cni config uninitialized

``` bash
# k8s master 初始化后一直处于 NotReady 状态
$ kubectl get nodes
NAME     STATUS     ROLES    AGE     VERSION
master   NotReady   master   2m10s   v1.15.3
```

``` bash
# 查看问题日志
$ journalctl -f -u kubelet.service
-- Logs begin at 三 2019-08-28 16:25:04 CST. --
8月 29 05:30:01 master kubelet[11090]: E0829 05:30:01.965483   11090 kubelet.go:2169] Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
8月 29 05:30:04 master kubelet[11090]: W0829 05:30:04.671478   11090 cni.go:213] Unable to update cni config: No networks found in /etc/cni/net.d
```

**问题所在：** cni 未初始化
- **解决1：** 去掉网络插件cni
``` bash
$ vi /var/lib/kubelet/kubeadm-flags.env

# 修改前
KUBELET_KUBEADM_ARGS="--cgroup-driver=cgroupfs --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.1"

# 修改后
KUBELET_KUBEADM_ARGS="--cgroup-driver=cgroupfs --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.1"

# 重启 kubelet
$ systemctl restart kubelet

$ kubectl get nodes
NAME     STATUS   ROLES    AGE   VERSION
master   Ready    master   20m   v1.15.3
```
在每一台节点上都执行该操作即可。

PS: 在 `centos 7.3` `k8s v1.15.2` `docker v19.03.1` 上可以直接初始化成功而不需要改 cni，在 `centos 7.4` `k8s v1.15.3` `docker v19.03.1` 上则初始化失败了，需要修改 cni 才可以，原因未知。。。

- **解决2：** 手动安装cni网络插件

待续*
PS: [安装Kubernetes报错：STATUS NotReady](https://www.jianshu.com/p/1bbb32c02e77)

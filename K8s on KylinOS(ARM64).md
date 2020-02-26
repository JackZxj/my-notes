# K8s on KylinOS base on Phytium FT1500a(ARM64)

These steps are similar to K8s on the Raspberry Pi

## Environment
- mechine
  - KylinOS 4.0.2sp2-server
  - Arch: arm64 (Phytium FT1500a)
- Docker
  - version 18.09.7
- Kubernetes
  - version 1.15.3

## preparation

``` bash
# Use admin account
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat > /etc/apt/sources.list << EOF
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-backports main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-proposed main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main multiverse restricted universe
deb http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-backports main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-proposed main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-security main multiverse restricted universe
deb-src http://mirrors.ustc.edu.cn/ubuntu-ports/ xenial-updates main multiverse restricted universe
EOF

apt-get install apt-transport-https
# if error
# then
wget http://ftp.cn.debian.org/debian/pool/main/a/apt/apt-transport-https_1.4.9_arm64.deb
dpkg -i apt-transport-https_1.4.9_arm64.deb
  # if error like this:
    # dpkg: 依赖关系问题使得 apt-transport-https 的配置工作不能继续：
    #  apt-transport-https 依赖于 libapt-pkg5.0 (>= 1.3~rc2)；然而：
    # 系统中 libapt-pkg5.0:arm64 的版本为 1.2.15kord0.2k2。
    # 
    # dpkg: 处理软件包 apt-transport-https (--install)时出错：
    #  依赖关系问题 - 仍未被配置
    # 在处理时有错误发生：
    #  apt-transport-https
  # then
  wget http://ftp.cn.debian.org/debian/pool/main/a/apt/libapt-pkg5.0_1.4.9_arm64.deb
  dpkg -i libapt-pkg5.0_1.4.9_arm64.deb
  dpkg -i apt-transport-https_1.4.9_arm64.deb
  # fi
# fi
apt-get update
```

## installation

``` bash
# disable SELinux
sudo setenforce 0
# disable forever, need to reboot
sudo sed -i 's/\(^SELINUX=\)\(enforcing\|permissive\)/\1disabled/' /etc/selinux/config

# disable swap
swapoff -a

# enable br_netfilter for Packet forwarding
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# Take effect
sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.d/k8s.conf

# add k8s repo
sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -

sudo cat > /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF

sudo apt-get update

# get available versions
apt-cache madison kubeadm

# install target version
sudo apt-get install -y kubelet=1.15.3-00 kubeadm=1.15.3-00 kubectl=1.15.3-00
# if error like this:
  # 正在读取软件包列表... 完成
  # 正在分析软件包的依赖关系树       
  # 正在读取状态信息... 完成       
  # 您可能需要运行“apt-get -f install”来纠正下列错误：
  # 下列软件包有未满足的依赖关系：
  #  g++ : 依赖: cpp (>= 4:5.3.1-1ubuntu1) 但是 4:5.3.1-1kord1 正要被安装
  #  gcc : 依赖: cpp (>= 4:5.3.1-1ubuntu1) 但是 4:5.3.1-1kord1 正要被安装
  #  gstreamer1.0-plugins-good : 依赖: libtag1v5 (>= 1.9.1-2.4ubuntu1) 但是 1.9.1-2.4kord1 正要被安装
  #  kubeadm : 依赖: kubernetes-cni (>= 0.7.5) 但是它将不会被安装
  #            依赖: cri-tools (>= 1.13.0) 但是它将不会被安装
  #  kubelet : 依赖: kubernetes-cni (>= 0.7.5) 但是它将不会被安装
  #            依赖: socat 但是它将不会被安装
  #            依赖: ebtables 但是它将不会被安装
  #            依赖: conntrack 但是它将不会被安装
  #  libjpeg-turbo8 : 破坏: libjpeg8 (< 8c-2ubuntu5) 但是 8c-2kord8 正要被安装
  #  libjpeg8-dev : 依赖: libjpeg8 (= 8c-2ubuntu8) 但是 8c-2kord8 正要被安装
  #  libsasl2-2 : 依赖: libsasl2-modules-db (>= 2.1.26.dfsg1-14ubuntu0.1) 但是 2.1.26.dfsg1-14kord2 正要被安装
  # E: 有未能满足的依赖关系。请尝试不指明软件包的名字来运行“apt-get -f install”(也可以指定一个解决办法)。
# then
apt-get -f install
  # 正在读取软件包列表... 完成
  # 正在分析软件包的依赖关系树       
  # 正在读取状态信息... 完成       
  # 正在修复依赖关系... 完成
  # 下列软件包是自动安装的并且现在不需要了：
  #   bigtop-tomcat
  # 使用'apt autoremove'来卸载它(它们)。
  # 将会同时安装下列软件：
  #   cpp cyrus-sasl2-dbg libjpeg-turbo8 libjpeg-turbo8-dev libjpeg8 libsasl2-2 libsasl2-modules-db libtag1v5 libtag1v5-vanilla
  # 建议安装：
  #   cpp-doc
  # 推荐安装：
  #   cyrus-sasl2-mit-dbg | cyrus-sasl2-heimdal-dbg libsasl2-modules
  # 下列软件包将被升级：
  #   cpp cyrus-sasl2-dbg libjpeg-turbo8 libjpeg-turbo8-dev libjpeg8 libsasl2-2 libsasl2-modules-db libtag1v5 libtag1v5-vanilla
  # 升级了 9 个软件包，新安装了 0 个软件包，要卸载 0 个软件包，有 631 个软件包未被升级。
  # 需要下载 1,446 kB 的归档。
  # 解压缩后会消耗 18.4 kB 的额外空间。
  # 您希望继续执行吗？ [Y/n] Y
  # ········

# install target version
sudo apt-get install -y kubelet=1.15.3-00 kubeadm=1.15.3-00 kubectl=1.15.3-00
sudo apt-mark hold kubelet=1.15.3-00 kubeadm=1.15.3-00 kubectl=1.15.3-00

# self-starting on boot
sudo systemctl enable kubelet && sudo systemctl restart kubelet

```

### master

``` bash
# get image list of k8s
kubeadm config images list --kubernetes-version=v1.15.3

# pull images
sudo docker pull gcr.azk8s.cn/google_containers/kube-apiserver-arm64:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-controller-manager-arm64:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-scheduler-arm64:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-proxy-arm64:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/pause-arm64:3.1
sudo docker pull gcr.azk8s.cn/google_containers/etcd-arm64:3.3.10
# coredns is not supported on arm at v1.3.1, so replace it to v1.5.0 
sudo docker pull coredns/coredns:1.5.0

# tag image to official name
sudo docker tag gcr.azk8s.cn/google_containers/kube-apiserver-arm64:v1.15.3 k8s.gcr.io/kube-apiserver:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-controller-manager-arm64:v1.15.3 k8s.gcr.io/kube-controller-manager:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-scheduler-arm64:v1.15.3 k8s.gcr.io/kube-scheduler:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-proxy-arm64:v1.15.3 k8s.gcr.io/kube-proxy:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/pause-arm64:3.1 k8s.gcr.io/pause:3.1
sudo docker tag gcr.azk8s.cn/google_containers/etcd-arm64:3.3.10 k8s.gcr.io/etcd:3.3.10
sudo docker tag coredns/coredns:1.5.0 k8s.gcr.io/coredns:1.3.1

# install
sudo kubeadm init --pod-network-cidr=10.253.0.0/16 --kubernetes-version=v1.15.3

# if success
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

```

##  for test
``` bash
kubectl run --image=nginx:alpine nginx-app --port=80
kubectl expose deployment nginx-app --port=80 --target-port=80 --type=NodePort
```

## upgrade

You can upgrade `1.X.Y` to `1.X+1.Z`, but unable to upgrade to `1.A.B(A > X+1)`.

``` bash
# upgrade kubeadm
apt-get install kubeadm=1.16.0-00

# check upgrade plan
kubeadm upgrade plan

# get image list
kubeadm config images list --kubernetes-version=v1.16.0

# pull images
docker pull gcr.azk8s.cn/google_containers/kube-apiserver-arm64:v1.16.0
docker pull gcr.azk8s.cn/google_containers/kube-controller-manager-arm64:v1.16.0
docker pull gcr.azk8s.cn/google_containers/kube-scheduler-arm64:v1.16.0
docker pull gcr.azk8s.cn/google_containers/kube-proxy-arm64:v1.16.0
docker pull gcr.azk8s.cn/google_containers/pause-arm64:3.1
docker pull gcr.azk8s.cn/google_containers/etcd-arm64:3.3.15-0
docker pull coredns/coredns:1.6.2

# tag images
docker tag gcr.azk8s.cn/google_containers/kube-apiserver-arm64:v1.16.0 k8s.gcr.io/kube-apiserver:v1.16.0
docker tag gcr.azk8s.cn/google_containers/kube-controller-manager-arm64:v1.16.0 k8s.gcr.io/kube-controller-manager:v1.16.0
docker tag gcr.azk8s.cn/google_containers/kube-scheduler-arm64:v1.16.0 k8s.gcr.io/kube-scheduler:v1.16.0
docker tag gcr.azk8s.cn/google_containers/kube-proxy-arm64:v1.16.0 k8s.gcr.io/kube-proxy:v1.16.0
docker tag gcr.azk8s.cn/google_containers/pause-arm64:3.1 k8s.gcr.io/pause:3.1
docker tag gcr.azk8s.cn/google_containers/etcd-arm64:3.3.15-0 k8s.gcr.io/etcd:3.3.15-0
docker tag coredns/coredns:1.6.2 k8s.gcr.io/coredns:1.6.2

# Reading configuration from the cluster (optional)
# kubectl -n kube-system get cm kubeadm-config -oyaml

# upgrade cluster
kubeadm upgrade apply v1.16.0
# upgrade without updating certificate
# kubeadm upgrade apply v1.16.0 --certificate-renewal=false

# upgrade kubelet & kubectl
apt-get install kubelet=1.16.0-00 kubectl=1.16.0-00

# reboot kubelet
systemctl daemon-reload && systemctl restart kubelet

# check
kubeadm version
kubectl version
kubelet --version
kubectl get no
```

## degrade

It's as same as in upgrade. `kubeadm upgrade` can also be used to degrade a cluster.
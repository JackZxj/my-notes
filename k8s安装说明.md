## All

``` bash
# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld


# 禁用 SELinux
setenforce 0
# 永久禁用 需要重启生效
sudo sed -i 's/\(^SELINUX=\)\(enforcing\|permissive\)/\1disabled/' /etc/selinux/config

# 禁用 SWAP
swapoff -a
# 永久禁用 swap
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab


# 启用 br_netfilter 网桥模块
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# 生效命令
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf


# 配置集群 host 列表
cat > /etc/hosts << EOF
$ip1    master
$ip2    node01
$ip3    node03
...
EOF


# 安装 docker


# 添加 yum 源
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


# 安装最新版
yum install -y kubelet kubeadm kubectl
# 安装指定版本
# yum install -y kubelet-1.15.0 kubeadm-1.15.0 kubectl-1.15.0


# 启动 kubelet
systemctl restart kubelet && systemctl enable kubelet
```

------------------------------------------------------

## master

``` bash
# master 节点既做 master 也做 node
# kubectl taint nodes --all node-role.kubernetes.io/master-


# 初始化 master 节点
kubeadm init --pod-network-cidr=10.253.0.0/16 --image-repository=registry.aliyuncs.com/google_containers
# 注:
# --pod-network-cidr 用于指定 pod 访问的网段，在网络插件的定义文件 (kube-flannel.yml) 中声明
# --image-repository 用于指定安装网络的镜像源，默认是 "k8s.gcr.io"


# kubenetes 配置
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# 安装 Flannel 网络插件
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f kube-flannel.yml


# 一步生成 join 命令
kubeadm token create --print-join-command
```

## node

``` bash
# 执行 master 节点 init 生成的最后一行
# 或者执行 master 一步生成的 join 命令
kubeadm join <master-ip>:<master-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```
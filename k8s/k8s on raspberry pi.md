# Kubernetes on Raspberry Pi 3B

## Environment

* mechine
  + raspberry pi 3B * 2
  + RAM 1GB, ROM 16GB
  + Raspbian GNU/Linux 10 (buster)
  + Arch: armv7l
* Docker
  + version 19.03.5 (The latest version as of January 15, 2020)
* Kubernetes
  + version 1.15.3

## Steps

### Preparation (optional)

``` bash
# set root password
sudo passwd root

# enable root
sudo passwd --unlock root

## disable root

# sudo passwd --lock root
```

### Docker

``` bash
# install one-step
sudo curl -sSL https://get.docker.com | sh

# set image-registry (optional)
mkdir -p /etc/docker && touch /etc/docker/daemon.json
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": [
        "http://hub-mirror.c.163.com",
        "https://reg-mirror.qiniu.com"
    ]
}
EOF
sudo systemctl daemon-reload

# self-starting on boot
sudo systemctl enable docker && sudo systemctl restart docker

# test
sudo docker run hello-world
```

### Kubernetes

#### Common Steps

``` bash
## disable firewalld
# sudo ufw disable

# disable SELinux
sudo setenforce 0
# disable forever, need to reboot
sudo sed -i 's/\(^SELINUX=\)\(enforcing\|permissive\)/\1disabled/' /etc/selinux/config

# disable swap
sudo systemctl disable dphys-swapfile

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
sudo apt-mark hold kubelet=1.15.3-00 kubeadm=1.15.3-00 kubectl=1.15.3-00

# self-starting on boot
sudo systemctl enable kubelet && sudo systemctl restart kubelet
```

#### Master steps

``` bash
# get image list of k8s
kubeadm config images list

# pull images
sudo docker pull gcr.azk8s.cn/google_containers/kube-apiserver-arm:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-controller-manager-arm:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-scheduler-arm:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/kube-proxy-arm:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/pause-arm:3.1
sudo docker pull gcr.azk8s.cn/google_containers/etcd-arm:3.3.10
# coredns not supported on arm at v1.3.1, so replace it to v1.5.0 
sudo docker pull coredns/coredns:1.5.0

# tag image to official name
sudo docker tag gcr.azk8s.cn/google_containers/kube-apiserver-arm:v1.15.3 gcr.azk8s.cn/google_containers/kube-apiserver:v1.15.3 
sudo docker tag gcr.azk8s.cn/google_containers/kube-controller-manager-arm:v1.15.3 gcr.azk8s.cn/google_containers/kube-controller-manager:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-scheduler-arm:v1.15.3 gcr.azk8s.cn/google_containers/kube-scheduler:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-proxy-arm:v1.15.3 gcr.azk8s.cn/google_containers/kube-proxy:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/pause-arm:3.1 gcr.azk8s.cn/google_containers/pause:3.1
sudo docker tag gcr.azk8s.cn/google_containers/etcd-arm:3.3.10 gcr.azk8s.cn/google_containers/etcd:3.3.10
sudo docker tag coredns/coredns:1.5.0 gcr.azk8s.cn/google_containers/coredns:1.3.1

# init master
# we use flannel as cni network
sudo kubeadm init --pod-network-cidr=10.253.0.0/16 --image-repository=gcr.azk8s.cn/google_containers

# if success
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# set flannel network
# official: https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# mine: https://github.com/JackZxj/my-notes/blob/master/kube-flannel.yml
kubectl apply -f kube-flannel.yml
# if unable to pull flannel image
docker pull quay-mirror.qiniu.com/coreos/flannel:v0.11.0-arm
docker tag quay-mirror.qiniu.com/coreos/flannel:v0.11.0-arm quay.io/coreos/flannel:v0.11.0-arm

# get join-command
kubeadm token create --print-join-command
```

#### Node steps

``` bash
# pull images
sudo docker pull gcr.azk8s.cn/google_containers/kube-proxy-arm:v1.15.3
sudo docker tag gcr.azk8s.cn/google_containers/kube-proxy-arm:v1.15.3 gcr.azk8s.cn/google_containers/kube-proxy:v1.15.3
sudo docker pull gcr.azk8s.cn/google_containers/pause-arm:3.1
sudo docker tag gcr.azk8s.cn/google_containers/pause-arm:3.1 gcr.azk8s.cn/google_containers/pause:3.1

# join to master
kubeadm join 10.165.23.238:6443 --token msmiit.bxnh1igzcqddhdit \
--discovery-token-ca-cert-hash sha256:38bfbd2e02cfba9c6997b30e935e5a6e5c2d637d1eea5adf6359f7760a2b5479

# if unable to pull flannel image
docker pull quay-mirror.qiniu.com/coreos/flannel:v0.11.0-arm
docker tag quay-mirror.qiniu.com/coreos/flannel:v0.11.0-arm quay.io/coreos/flannel:v0.11.0-arm
```

#### Test

``` bash
kubectl run --image=arm32v7/nginx nginx-app --port=80
kubectl expose deployment nginx-app --port=80 --target-port=80 --type=NodePort
# Then you can access it on web
```

### Others

``` bash
# if you get error like this
pi@raspberrypi:~ $ sudo apt-get update
Hit:1 http://archive.raspberrypi.org/debian buster InRelease                     
Get:2 http://raspbian.raspberrypi.org/raspbian buster InRelease [15.0 kB]        
Reading package lists... Done                                                                                                                                          
E: Repository 'http://raspbian.raspberrypi.org/raspbian buster InRelease' changed its 'Suite' value from 'testing' to 'stable'
N: This must be accepted explicitly before updates for this repository can be applied. See apt-secure(8) manpage for details.

# you can do this to deal with
# Update manually
sudo apt update 
# enter y
# then you can update or upgrade normally
sudo apt-get update
```

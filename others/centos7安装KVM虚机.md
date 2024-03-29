## kvm 安装

``` BASH
# 安装kvm以及工具
yum install qemu-kvm qemu-kvm-tools virt-manager libvirt virt-install -y

# 定义虚拟机文件夹
mkdir -p /kvm/vm0
cd /kvm/vm0
# 创建虚机文件
qemu-img create -f raw c1-0.img 30G
# Formatting 'c1-0.img', fmt=raw size=32212254720

# 安装虚机
virt-install --virt-type=kvm \
    --name=centos78-0 \
    --vcpus=2 \
    --memory=2048 \
    --location=/kvm/os/CentOS-7-x86_64-Minimal-2003.iso \
    --disk path=/kvm/vm0/c1-0.img \
    --network bridge=virbr0 \
    --graphics none \
    --extra-args='console=ttyS0' \
    --force
# 弹出一个控制台安装界面，根据提示完成 [!] 的部分
# Installation
#
#  1) [x] Language settings                 2) [!] Timezone settings
#         (English (United States))                (Timezone is not set.)
#  3) [!] Installation source               4) [!] Software selection
#         (Processing...)                          (Processing...)
#  5) [!] Installation Destination          6) [x] Kdump
#         (No disks selected)                      (Kdump is enabled)
#  7) [ ] Network configuration             8) [!] Root password
#         (Not connected)                          (Password is not set.)
#  9) [!] User creation
#         (No user will be created)
#   Please make your choice from above ['q' to quit | 'b' to begin installation |
#   'r' to refresh]:

```

## 常用命令

``` BASH
# 复制虚机
# 关闭源虚机
# virt-clone --original centos6.5 --name centos6.5_new --file /home/images/centos6.5_new.img
virt-clone -o centos78-0 -n centos78-edge-0 -f /kvm/vm-centos78-edge-0.qcow2
# 修改新虚机的内存/cpu等配置
virsh edit centos78-edge-0
# 开机
uuidgen
# 复制的centos可能inet6地址重复，需要更新一个uuid
vi /etc/sysconfig/network-scripts/ifcfg-eth0
# 重启网络
service network restart
# 修改hostname
vi /etc/hostname
# 重启
reboot now

# 列出所有虚机
virsh list --all

VM_NAME='centos78-0'
# 虚机信息
virsh dominfo $VM_NAME

# 关机
virsh shutdown $VM_NAME

# 强制关机
virsh destroy $VM_NAME

# 开机
virsh start $VM_NAME

# 自启动
virsh autostart $VM_NAME

# 取消自启动
virsh autostart --disable $VM_NAME

# 删除虚机
virsh undefine $VM_NAME

# 进入虚机控制台
virsh console $VM_NAME

# 退出虚机控制台
快捷键： ctrl+]
```

## 坑了

要创建快照，raw格式不支持。。。

``` BASH
# 查看虚机磁盘信息
qemu-img info c1-0.img

# raw格式转qcow2
# qemu-img convert -f raw -O qcow2 <原文件名> <新文件名>
qemu-img convert -f raw -O qcow2 c1-0.img centos78-0.qcow2
# 修改kvm虚机信息
virsh edit centos78-0
# 替换里头的raw为qcow2，替换<原文件名>为<新文件名>
```

## 快照

``` BASH
# 创建快照
# virsh snapshot-create-as --domain <虚机名> --name <快照名>
virsh snapshot-create-as --domain centos78-0 --name centos78-0-snap-0 --description "initial os"

# 查看快照
virsh snapshot-list centos78-0
# cat /var/lib/libvirt/qemu/snapshot/<虚机名>/<快照名>.xml # 查看快照信息

# 还原快照，还原必须在关机状态下
virsh shutdown centos78-0
virsh snapshot-revert --domain centos78-0 centos78-0-snap-0

# 删除快照
virsh snapshot-delete --domain centos78-0 centos78-0-snap-0
```

## 内存扩容

```BASH
# 查看虚机
virsh list
# 查看目标原本信息
virsh dominfo node1
# 关闭虚机
virsh shutdown node1
# 等待关闭完成后设置可用最大内存 4194304 = 4GB  8388608 = 8GB
virsh setmaxmem node1 8388608
# 重启虚机
virsh start node1
# 设置虚机的内存
virsh setmem node1 8388608
# 查看扩容后信息
virsh dominfo node1
```

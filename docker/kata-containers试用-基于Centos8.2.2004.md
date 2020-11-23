# kata-containers试用-基于Centos8.2.2004

## CentOS8 安装

安装系统可参考[网友的详细教程](https://www.cnblogs.com/wzb0228/p/12653104.html)

我用的是VMware workstation 15 Pro， `选择客户机操作系统` 的选项里选择 `Linux` ，然后版本里没有 `centos8 64位` ，选 `centos7 64位` 就可以了。**注：** 系统选 `其他` ，版本选 `其他` 的话可能会无法识别到网卡。。别问我怎么知道的。。

安装好虚机记得给CPU添加虚拟化 `Intel VT-x/EPT 或 AMD-V/RVI` 支持

## 安装docker

参考[官方文档](https://docs.docker.com/engine/install/centos/)

可能遇到的问题：

``` BASH
# 问题1: 没有证书装不了工具
$ yum install -y yum-utils

You have enabled checking of packages via GPG keys. This is a good thing.
However, you do not have any GPG public keys installed. You need to download
the keys for packages you wish to install and install them.
You can do that by running the command:
    rpm --import public.gpg.key

Alternatively you can specify the url to the key you would like to use
for a repository in the 'gpgkey' option in a repository section and YUM
will install it for you.

For more information contact your distribution or package provider.

# 解决1：导入一个证书
$ rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
```

## 安装kata

官方支持[多种安装方式](https://github.com/kata-containers/kata-containers/tree/2.0-dev/docs/install)。选择比较简单方便的 `dnf(yum)` 安装。参考[官方文档](https://github.com/kata-containers/kata-containers/blob/2.0-dev/docs/install/centos-installation-guide.md)

``` BASH
# 问题2：GPG 检查失败
$ sudo -E dnf install -y kata-runtime
......
警告：/var/cache/dnf/advanced-virt-3e432ed1d72d75ce/packages/qemu-img-4.2.0-29.el8.6.x86_64.rpm: 头V4 RSA/SHA1 Signature, 密钥 ID 61e8806c: NOKEY
qemu-img-4.2.0-29.el8.6.x86_64.rpm 的公钥没有安装
qemu-kvm-common-4.2.0-29.el8.6.x86_64.rpm 的公钥没有安装
qemu-kvm-core-4.2.0-29.el8.6.x86_64.rpm 的公钥没有安装
seabios-bin-1.13.0-2.el8.noarch.rpm 的公钥没有安装
seavgabios-bin-1.13.0-2.el8.noarch.rpm 的公钥没有安装
sgabios-bin-0.20170427git-3.el8.noarch.rpm 的公钥没有安装
virglrenderer-0.8.2-1.el8.x86_64.rpm 的公钥没有安装
kata-agent-1.11.3-1.el8.x86_64.rpm 的公钥没有安装
kata-osbuilder-1.11.3-1.el8.x86_64.rpm 的公钥没有安装
kata-runtime-1.11.3-1.el8.x86_64.rpm 的公钥没有安装
kata-shim-1.11.3-1.el8.x86_64.rpm 的公钥没有安装
下载的软件包保存在缓存中，直到下次成功执行事务。
您可以通过执行 'dnf clean packages' 删除软件包缓存。
错误：GPG 检查失败

# 解决2：关闭GPG检查（虽然我觉得这个解决方法不正确，但是我确实不知道怎么解决。。。）
# 将/etc/yum.repos.d/kata-containers.repo /etc/yum.repos.d/kata-containers.repo 修改为 gpgcheck=0
```

## 给docker添加kata runtime支持

docker默认使用runc，添加一个额外的kata-runtime

``` BASH
$ cat /etc/docker/daemon.json 
{
  "runtimes": {
    "kata-runtime": {
      "path": "/usr/bin/kata-runtime"
    }
  }
}

# 完成后重启docker
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker

# 可以看见多了一个可用的运行时
$ sudo docker info | grep Runtime
 Runtimes: kata-runtime runc
 Default Runtime: runc
```

## 使用kata与使用runc

``` BASH
$ ps -ef | grep kata
root       30085   29898  0 14:59 pts/1    00:00:00 grep --color=auto kata

$ docker run -d -p 8080:80 nginx:alpine
65de73052c480a0c31ececacc54517c40447ce9cc03c917eb08d641d6690f479

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
65de73052c48        nginx:alpine        "/docker-entrypoint.…"   4 seconds ago       Up 3 seconds        0.0.0.0:8080->80/tcp   beautiful_bhaskara

$ ps -ef | grep docker
root       29721       1  0 14:52 ?        00:00:02 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root       30145   29721  0 15:01 ?        00:00:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 8080 -container-ip 172.17.0.2 -container-port 80
root       30150   24853  0 15:01 ?        00:00:00 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/65de73052c480a0c31ececacc54517c40447ce9cc03c917eb08d641d6690f479 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-runc
root       30241   29898  0 15:01 pts/1    00:00:00 grep --color=auto docker

$ docker run -d -p 8081:80 --runtime=kata-runtime nginx:alpine
eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7

$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                  NAMES
eebe74ac933f        nginx:alpine        "/docker-entrypoint.…"   10 seconds ago       Up 3 seconds        0.0.0.0:8081->80/tcp   tender_robinson
65de73052c48        nginx:alpine        "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp   beautiful_bhaskara

$ ps -ef | grep docker
root       29721       1  0 14:52 ?        00:00:02 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
root       30145   29721  0 15:01 ?        00:00:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 8080 -container-ip 172.17.0.2 -container-port 80
root       30150   24853  0 15:01 ?        00:00:00 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/65de73052c480a0c31ececacc54517c40447ce9cc03c917eb08d641d6690f479 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-runc
root       30261   29721  0 15:02 ?        00:00:00 /usr/bin/docker-proxy -proto tcp -host-ip 0.0.0.0 -host-port 8081 -container-ip 172.17.0.3 -container-port 80
root       30268   24853  0 15:02 ?        00:00:00 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-kata-runtime
root       30497   29898  0 15:02 pts/1    00:00:00 grep --color=auto docker

# kata跑了一个虚机
$ ps -ef | grep kata
root       30268   24853  0 15:02 ?        00:00:00 containerd-shim -namespace moby -workdir /var/lib/containerd/io.containerd.runtime.v1.linux/moby/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7 -address /run/containerd/containerd.sock -containerd-binary /usr/bin/containerd -runtime-root /var/run/docker/runtime-kata-runtime
root       30323   30268  0 15:02 ?        00:00:00 /usr/libexec/virtiofsd --fd=3 -o source=/run/kata-containers/shared/sandboxes/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/shared -o cache=always --syslog -o no_posix_lock -f
root       30328   30268 12 15:02 ?        00:00:06 /usr/libexec/qemu-kvm -name sandbox-eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7 -uuid c019b3c2-a720-41ba-ba77-7919a62e6fbe -machine q35,accel=kvm,kernel_irqchip -cpu host,pmu=off -qmp unix:/run/vc/vm/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/qmp.sock,server,nowait -m 2048M,slots=10,maxmem=2984M -device pci-bridge,bus=pcie.0,id=pci-bridge-0,chassis_nr=1,shpc=on,addr=2,romfile= -device virtio-serial-pci,disable-modern=true,id=serial0,romfile= -device virtconsole,chardev=charconsole0,id=console0 -chardev socket,id=charconsole0,path=/run/vc/vm/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/console.sock,server,nowait -device virtio-scsi-pci,id=scsi0,disable-modern=true,romfile= -object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0,romfile= -device vhost-vsock-pci,disable-modern=true,vhostfd=3,id=vsock-1408643417,guest-cid=1408643417,romfile= -chardev socket,id=char-f25e5a52981514e6,path=/run/vc/vm/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/vhost-fs.sock -device vhost-user-fs-pci,chardev=char-f25e5a52981514e6,tag=kataShared,romfile= -netdev tap,id=network-0,vhost=on,vhostfds=4,fds=5 -device driver=virtio-net-pci,netdev=network-0,mac=02:42:ac:11:00:03,disable-modern=true,mq=on,vectors=4,romfile= -global kvm-pit.lost_tick_policy=discard -vga none -no-user-config -nodefaults -nographic -daemonize -object memory-backend-file,id=dimm1,size=2048M,mem-path=/dev/shm,share=on -numa node,memdev=dimm1 -kernel /usr/lib/modules/4.18.0-193.el8.x86_64/vmlinuz -initrd /var/cache/kata-containers/osbuilder-images/4.18.0-193.el8.x86_64/"centos"-kata-4.18.0-193.el8.x86_64.initrd -append tsc=reliable no_timer_check rcupdate.rcu_expedited=1 i8042.direct=1 i8042.dumbkbd=1 i8042.nopnp=1 i8042.noaux=1 noreplace-smp reboot=k console=hvc0 console=hvc1 iommu=off cryptomgr.notests net.ifnames=0 pci=lastbus=0 quiet panic=1 nr_cpus=2 agent.use_vsock=true scsi_mod.scan=none -pidfile /run/vc/vm/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/pid -smp 1,cores=1,threads=1,sockets=2,maxcpus=2
root       30332   30323  0 15:02 ?        00:00:00 /usr/libexec/virtiofsd --fd=3 -o source=/run/kata-containers/shared/sandboxes/eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7/shared -o cache=always --syslog -o no_posix_lock -f
root       30470   30268  0 15:02 ?        00:00:00 /usr/libexec/kata-containers/kata-shim -agent vsock://1408643417:1024 -container eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7 -exec-id eebe74ac933f160c74a63b86bf0ab34ee5599ad37abd720de8231fce8d9344b7
root       30500   29898  0 15:03 pts/1    00:00:00 grep --color=auto kata

```

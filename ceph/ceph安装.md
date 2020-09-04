# Ceph 安装

## Background

安装环境：

* CentOS 7.4

安装节点为

* 192.168.154.3 (monitor, node0) 名称为 master
* 192.168.154.4 (node1) 名称为 node-1
* 192.168.154.5 (node2) 名称为 node-2

修改方式见k8s安装，修改 3 台主机的 /etc/hosts 文件，末尾加入
192.168.154.3 master
192.168.154.4 node-1
192.168.154.5 node-2

## Prepare

### 添加 yum 源

``` bash
$ cat > /etc/yum.repos.d/ceph.repo << EOF
[Ceph]
name=Ceph packages for x86_64
baseurl=https://mirrors.aliyun.com/ceph/rpm-jewel/el7/x86_64
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[Ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-jewel/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
[ceph-source]
name=Ceph source packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-jewel/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
EOF

$ yum makecache fast
```

### 关闭防火墙和 SELinux

``` bash
$ systemctl stop firewalld && systemctl disable firewalld

# 临时关闭
$ setenforce 0

# 永久关闭 selinux，重启生效
$ sed -i '/^SELINUX=/cSELINUX=disabled' /etc/selinux/config
```

### 安装时间同步服务

``` bash
# 不安装的话可能会使 ceph 集群死掉

###########################################

# master 节点
$ yum install -y ntp ntpdate

# 修改 master 节点的 /etc/ntp.conf 文件

# 注释掉中间的四个同步服务器
# server 0.centos.pool.ntp.org iburst
# server 1.centos.pool.ntp.org iburst
# server 2.centos.pool.ntp.org iburst
# server 3.centos.pool.ntp.org iburst

# 添加以下内容
server 127.127.1.0                         #以本机作为时间服务器
fudge 127.127.1.0 startnum 10              #设置服务器层级
restrict 127.0.0.1                         #允许本机使用这个时间服务器
restrict 192.168.154.0 netmask 255.255.255.0  #允许允许10.220.5.0/24网段的所有主机使用该时间服务器进行时间同步
driftfile /var/lib/ntp/                    #记录当前时间服务器，与上游服务器的时间差的文件
logfile /var/log/ntp/ntp.log               #指定日志文件位置，需要手动创建

# master 节点手动创建 log 文件
$ mkdir -p /var/lib/ntp && touch /var/lib/ntp/ntp.log

# master 启动服务
$ systemctl enable ntpd && systemctl restart ntpd

######################################

# node 节点
$ yum install -y ntp ntpdate

# 修改 node 节点的 /etc/ntp.conf 文件

# 注释掉中间的四个同步服务器
# server 0.centos.pool.ntp.org iburst
# server 1.centos.pool.ntp.org iburst
# server 2.centos.pool.ntp.org iburst
# server 3.centos.pool.ntp.org iburst

# 添加以下内容
server 192.168.154.3                       #以 master 作为时间服务器
restrict 127.0.0.1                         #允许本机使用这个时间服务器
logfile /var/log/ntp/ntp.log               #指定日志文件位置，需要手动创建

# node 节点手动创建 log 文件
$ mkdir -p /var/lib/ntp && touch /var/lib/ntp/ntp.log

# 先进行一次时间同步
$ ntpdate 192.168.154.3

# node 启动服务
$ systemctl enable ntpd && systemctl restart ntpd
```

**[说明](https://blog.csdn.net/cx55887/article/details/83868660)**: 在工作中我们一般都是使用ntpdate+ntp来完成时间同步，因为单独使用ntpdate同步时间虽然简单快捷但是会导致时间不连续，而时间不连续在数据库业务中影响是很大的，单独使用ntp做时间同步时，当服务器与时间服务器相差大的时候则无法启动ntpd来同步时间。由于ntpd做时间同步时是做的顺滑同步（可以简单理解为时间走得快，以便将落后的时间赶过来），所以同步到时间服务器的的时间不是瞬间完成的，开启ntpd之后稍等三五分钟就能完成时间同步。

### 创建 cephdeploy 用户，配置其免密 sudo

``` bash
# 所有 ceph 节点都需要添加，便于集群间的存储访问
$ useradd -m cephdeploy
$ passwd cephdeploy
$ echo "cephdeploy ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/cephdeploy
$ chmod 0440 /etc/sudoers.d/cephdeploy
```

### master 节点 ssh 免密连接 node

``` bash
$ ssh-keygen
$ ssh-copy-id node-1
$ ssh-copy-id node-2
```

## 安装 ceph

``` bash
# master 节点安装部署工具
$ yum install -y ceph-deploy

# 创建集群，以下命令需要在 ceph.conf 所在文件夹下执行
$ mkdir -p /root/ceph && cd /root/ceph
$ ceph-deploy new master node-1 node-2

# 在生成的 ceph.conf 末尾添加
public_network = 192.168.154.3/24       # 设置集群的公共网络，相当于192.168.154.0
osd_pool_default_size = 2               # 设置集群的副本数，不写的话默认应该是3个

# 安装 ceph
$ ceph-deploy install master node-1 node-2

# master 初始化监视器
$ ceph-deploy mon create-initial

# 查看 ceph 集群信息，每个 node 都能看得到
$ ceph -s
    cluster 0ac81b4e-aca9-499f-9246-84e705719016
     health HEALTH_ERR
            no osds
     monmap e1: 3 mons at {master=192.168.154.3:6789/0,node-1=192.168.154.4:6789/0,node-2=192.168.154.5:6789/0}
            election epoch 6, quorum 0,1,2 master,node-1,node-2
     osdmap e1: 0 osds: 0 up, 0 in
            flags sortbitwise,require_jewel_osds
      pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
            0 kB used, 0 kB / 0 kB avail
                  64 creating
```

## 可能的错误

* ** `ceph-deploy new node-2` 错误**

``` bash
# 由于网络问题可能会失败，比如遇到下面的情况
······
[node-2][DEBUG ] Downloading packages:
[node-2][DEBUG ] No Presto metadata available for Ceph
[node-2][WARNIN] No data was received after 300 seconds, disconnecting...
[node-2][INFO  ] Running command: ceph --version
[node-2][ERROR ] Traceback (most recent call last):
[node-2][ERROR ]   File "/usr/lib/python2.7/site-packages/ceph_deploy/lib/vendor/remoto/process.py", line 119, in run
[node-2][ERROR ]     reporting(conn, result, timeout)
[node-2][ERROR ]   File "/usr/lib/python2.7/site-packages/ceph_deploy/lib/vendor/remoto/log.py", line 13, in reporting
[node-2][ERROR ]     received = result.receive(timeout)
[node-2][ERROR ]   File "/usr/lib/python2.7/site-packages/ceph_deploy/lib/vendor/remoto/lib/vendor/execnet/gateway_base.py", line 704, in receive
[node-2][ERROR ]     raise self._getremoteerror() or EOFError()
[node-2][ERROR ] RemoteError: Traceback (most recent call last):
[node-2][ERROR ]   File "<string>", line 1036, in executetask
[node-2][ERROR ]   File "<remote exec>", line 12, in _remote_run
[node-2][ERROR ]   File "/usr/lib64/python2.7/subprocess.py", line 711, in __init__
[node-2][ERROR ]     errread, errwrite)
[node-2][ERROR ]   File "/usr/lib64/python2.7/subprocess.py", line 1327, in _execute_child
[node-2][ERROR ]     raise child_exception
[node-2][ERROR ] OSError: [Errno 2] No such file or directory
[node-2][ERROR ] 
[node-2][ERROR ] 
[ceph_deploy][ERROR ] RuntimeError: Failed to execute command: ceph --version
```

**解决方案：**

此时可以尝试在出错的节点上手动安装错误的那个包 `yum install -y ceph` , 然后再在 master 上单独执行安装程序 `ceph-deploy install node-2`
或者将所需的 rpm 包下载到本地后配置本地 yum 源安装。

PS：ceph 长时间下载失败时，可能会被自动替换为官方的源，如果被改了的话，记得自己得改回国内的源

* ** `ceph –s` 查看 ceph 情况时报错 `error connecting to the cluster` **

**解决方案：**

查看节点的 `/etc/ceph/` 目录下是否包含 `ceph.client.admin.keyring`  `ceph.conf` 两个文件，如果没有的话需要将 master 生成的这两个文件拷贝进去

* **`ceph –s` 查看 ceph 情况时报错 `HEALTH_WARN clock skew detected on mon.nodexxx`**

**解决方案：**

要做的是，修改ceph配置中的时间偏差阈值，那么，在admin节点：

``` bash
vi /root/cluster/ceph.conf
添加两个字段
mon clock drift allowed = 2
mon clock drift warn backoff = 30
#然后，向需要同步的mon节点推送配置文件
ceph-deploy --overwrite-conf admin master node-1 node-2
#然后，重启admin节点的mon服务（centos7环境下）
 systemctl restart ceph-mon@master.service
#最后使用ceph -s来验证一下，如果状态为ok，证明问题已经解决
```

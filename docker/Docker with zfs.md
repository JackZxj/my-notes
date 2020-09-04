# Docker with the zfs storage driver

ENV: Ubuntu 16.04 x86_64 with Docker 19.03

## Preparation

``` BASH

###################### Install Docker ######################

sudo apt-get update

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Verify fingerprint
sudo apt-key fingerprint 0EBFCD88
# pub   4096R/0EBFCD88 2017-02-22
#       密钥指纹 = 9DC8 5822 9FC7 DD38 854A  E2D8 8D81 803C 0EBF CD88
# uid                  Docker Release (CE deb) <docker@docker.com>
# sub   4096R/F273FCD8 2017-02-22

# Add docker repository
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

# Install
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Install other version of docker
# Get List of docker
apt-cache madison docker-ce
# Install your version
sudo apt-get install docker-ce=<VERSION_STRING> docker-ce-cli=<VERSION_STRING> containerd.io

###################### Install zfs-tool ######################

sudo apt install zfsutils-linux -y
```

## Configure Docker

``` BASH
# Stop docker
sudo systemctl stop docker
# backup your docker files
sudo cp -au /var/lib/docker /var/lib/docker.bk
sudo rm -rf /var/lib/docker/*

# create a new zpool
# add two disks for zpool(probably need to reboot system)
sudo fdisk -l
# Disk /dev/sdb: 10 GiB, 10737418240 bytes, 20971520 sectors
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes

# Disk /dev/sdc: 10 GiB, 10737418240 bytes, 20971520 sectors
# Units: sectors of 1 * 512 = 512 bytes
# Sector size (logical/physical): 512 bytes / 512 bytes
# I/O size (minimum/optimal): 512 bytes / 512 bytes

sudo zpool create -f zpool-docker -m /var/lib/docker /dev/sdb /dev/sdc
sudo zfs list
# NAME           USED  AVAIL  REFER  MOUNTPOINT
# zpool-docker   646K  19.3G    24K  /var/lib/docker

# update docker storage driver
sudo cat << EOF > /etc/docker/daemon.json
{
    "storage-driver": "zfs"
}
EOF

# restart docker
sudo systemctl restart docker
# Verify
sudo docker info
# Server:
#  Containers: 0
#   Running: 0
#   Paused: 0
#   Stopped: 0
#  Images: 0
#  Server Version: 19.03.12
#  Storage Driver: zfs
#   Zpool: zpool-docker
#   Zpool Health: ONLINE
#   Parent Dataset: zpool-docker
#   Space Used By Parent: 662016
#   Space Available: 20673062400
#   Parent Quota: no
#   Compression: off
```

# Using zfs in container

**WARNNING:** need privileged!

``` BASH
# /dev/sdd is a new disk
docker run -d -it --name=privileged-zfs --privileged --device=/dev/sdd ubuntu:16.04 bash
# enter the container
docker exec -it privileged-zfs bash

# install zfs tool
apt update
apt install zfsutils-linux -y
# check if ZFS was installed correctly by running
whereis zfs
# create zpool and mount it to /home/zfs-test
zpool create -f zpool-test -m /home/zfs-test /dev/sdd
# check if zpool was created correctly
zfs list
# NAME          USED  AVAIL  REFER  MOUNTPOINT
# zpool-test    262K  4.81G    24K  /home/zfs-test
```

# Ref

* https://docs.docker.com/engine/install/ubuntu/
* https://ubuntu.com/tutorials/setup-zfs-storage-pool#2-installing-zfs
* https://docs.docker.com/storage/storagedriver/zfs-driver/

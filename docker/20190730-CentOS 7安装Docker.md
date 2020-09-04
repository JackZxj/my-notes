## 一、准备工作

Docker 支持 64 位的 CentOS 7 系统，本次安装实在虚拟机环境下进行的。CentOS 7的安装此处省略。

## 二、修改 yum 源 (可选)

由于某些原因，国内使用官方 yum 源速度不是很理想，此时可以选择采用国内的 `aliyun` 或者其他国内公司提供的镜像。本次选用的是阿里的 yum 源。

以下命令行均通过命令行终端执行。

``` bash
# 创建备份文件夹
mkdir /etc/yum.repos.d/bak

# 将原本的配置文件移动到bak文件夹中
mv /etc/yum.repos.d/*.* /etc/yum.repos.d/bak

# 下载阿里yum的配置文件
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

# 更新yum配置
sudo yum clean all
sudo yum makecache fast
```

## 三、删除旧版本 Docker

``` bash
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
```

## 四、使用 yum 方式安装

除了采用yum安装外还有使用脚本自动安装的方式可以安装docker。本次安装采用yum的方式（较为复杂）。

``` bash
# 安装依赖包
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# 配置docker的源（国内建议使用国内的镜像，有阿里的、七牛云的等，此处使用阿里云的源，官方源地址为：https://download.docker.com/linux/centos/docker-ce.repo
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 更新yum的软件源缓存
sudo yum makecache fast

# 安装docker
sudo yum install docker-ce -y
```

## 五、使用 Docker CE

``` bash
# 启动docker
sudo systemctl enable docker && sudo systemctl restart docker

# 创建名为xxx的组
# sudo groupadd xxx

# 将当前用户加入到xxx组
# sudo usermod -aG xxx $USER

# 测试docker正常运行
docker run hello-world
```

如果成功执行，则在控制台输出很多信息，中间有一句为 `Hello from Docker!` ，那么说明配置成功。

## 六、配置 Docker Hub 镜像

Docker Hub的源拉取困难时，可以添加国内的其他服务商提供的镜像加速。建议配置两个以上的加速镜像，以防宕机。

在 `/etc/docker/daemon.json` 中写入以下内容（如果文件不存在，则新建该文件）。

``` json
{
    "registry-mirrors": [
        "https://dockerhub.azk8s.cn",
        "https://reg-mirror.qiniu.com"
    ]
}
```

之后，重启 docker 服务。

``` bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 七、安装完成

由此，docker 已经在 CentOS 7 中安装完毕，可以愉快的使用 docker 了。

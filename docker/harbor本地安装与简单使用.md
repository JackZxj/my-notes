# Harbor 本地安装与简单使用

## 准备环境

### 安装 docker

建议直接采用官方脚本安装更方便:

https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
``` BASH
$ curl -fsSL https://get.docker.com -o get-docker.sh
$ sudo sh get-docker.sh
$ sudo systemctl enable docker
```

### 安装 docker-compose

参考官方指导: https://docs.docker.com/compose/install/
``` BASH
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
$ docker-compose --version
```

## 安装 Harbor

为了方便选择离线安装

``` BASH
$ wget https://github.com/goharbor/harbor/releases/download/v2.2.1/harbor-offline-installer-v2.2.1.tgz
$ tar xvf harbor-offline-installer-v2.2.1.tgz
$ cd harbor
$ vi harbor.yml.tmpl
# 修改主机地址
hostname: 192.168.154.132

# 由于只是本地测试用，不需要https，故注释掉这部分
# https related config
#https:
  # https port for harbor, default is 443
#  port: 443
  # The path of cert and key files for nginx
#  certificate: /your/certificate/path
#  private_key: /your/private/key/path

# 修改镜像存放地址
data_volume: /harbor/images

# 其余部分保持默认也行，保存后退出

$ mv harbor.yml.tmpl harbor.yml
$ ./prepare
$ ./install.sh
# 完成后打开浏览器，访问 192.168.154.132 可以看到 Harbor 主界面，使用配置文件的密码登录，默认为 admin/Harbor12345

# 修改 docker 配置, 添加 insecure-registries 字段
$ vi /etc/docker/daemon.json
{
    "insecure-registries": [
        "192.168.154.132"
    ]
}
# 重启 docker
$ systemctl daemon-reload
$ systemctl restart docker

$ docker pull nginx:alpine
$ docker tag nginx:alpine 192.168.154.132/library/nginx:alpine
# docker 登录 Harbor，需要写 http，否则默认是 https，使用admin登录或者在harbor中创建用户，然后再登录
$ docker login http://192.168.154.132
$ docker push 192.168.154.132/library/nginx:alpine
# 浏览器中可以看到项目 library 以及一个镜像
```

## 集成 Dragonfly

docker 部署参见 https://d7y.io/zh-cn/docs/userguide/multi_machines_deployment.html

**使用 k8s 部署:**

``` yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: d7y-supernode
  name: d7y-supernode
spec:
  replicas: 1
  selector:
    matchLabels:
      app: d7y-supernode
  template:
    metadata:
      labels:
        app: d7y-supernode
    spec:
      containers:
      - image: dragonflyoss/supernode:1.0.6
        name: supernode
        ports:
        - containerPort: 8001
          name: download
          protocol: TCP
          hostPort: 8001
        - containerPort: 8002
          name: register
          protocol: TCP
          hostPort: 8002
      tolerations:    # vm0 是master，需要 tolerations
      - effect: NoSchedule
        operator: Exists
      nodeSelector:
        kubernetes.io/hostname: vm0
---
kind: Service
apiVersion: v1
metadata:
  name: d7y-supernode
spec:
  selector:
    app: d7y-supernode
  ports:
  - name: download
    protocol: TCP
    port: 8001
    targetPort: 8001
  - name: register
    protocol: TCP
    port: 8002
    targetPort: 8002
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: d7y-dfget-conf
data:
  dfget.yml: |
    nodes:
    - d7y-supernode.default.svc.cluster.local
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: d7y-dfdaemon
spec:
  selector:
    matchLabels:
      app: d7y-dfdaemon
  template:
    metadata:
      labels:
        app: d7y-dfdaemon
    spec:
      containers:
      - image: dragonflyoss/dfclient:1.0.6
        name: dfdaemon
        args:
        - --registry 
        - http://192.168.154.132     # 修改这里地址为 harbor 地址
        ports:
        - containerPort: 65001
          name: dfget
          hostPort: 65001
          protocol: TCP
        volumeMounts:
        - mountPath: /etc/dragonfly
          name: dragonconf
      restartPolicy: Always
      volumes:
      - name: dragonconf
        configMap:
          name: d7y-dfget-conf
```

**配置节点 Docker:**

编辑节点上 Docker 的配置 `/etc/docker/daemon.json`

``` json
{
    "registry-mirrors": [
        "http://127.0.0.1:65001"
    ],
    "insecure-registries": [
        "192.168.154.132"
    ]
}
```

``` BASH
# docker 设置转发
$ vi /lib/systemd/system/docker.service
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:65001"
# 重启节点 Docker
$ systemctl daemon-reload
$ systemctl restart docker
```

## 配置 Harbor p2p 预热

登录 Harbor 网页

注册 Dragonfly : `分布式分发` - `新建实例` - `名称: d7y-test` - `端点: http://192.168.154.132:8002` - `测试连接` - `确定`

添加 P2P 预热策略: `项目` - `library` - `P2P预热` - `新建策略` - `提供商` - `名称` - `仓库: **` - `Tags: **` - `手动` - `添加`

P2P 预热: `选中策略` - `其他操作` - `执行` - `等待执行记录结果`

验证 P2P:

``` BASH
# vm0
$ docker tag golang:1.16.3-stretch 192.168.154.132/library/golang:1.16.3-stretch
$ docker push 192.168.154.132/library/golang:1.16.3-stretch

# vm1
$ docker pull 192.168.154.132/library/golang:1.16.3-stretch

```


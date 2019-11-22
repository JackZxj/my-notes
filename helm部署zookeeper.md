## ENV
- Env
  - OS: CentOS 7.4
  - Arch: x86_64
- Docker
  - Version: 19.03.1
- Kubernetes
  - Version: v1.15.3

## helm installation
``` bash
wget https://get.helm.sh/helm-v3.0.0-linux-amd64.tar.gz
tar -zxvf helm-v3.0.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64/
# helm is ok, now you can use it.
helm help
```
**Tips:** There is no in-cluster (Tiller) component in version 3, so it is NO need to install additional till components.

## zookeeper installation
### chart from incubator (recommend)
You can get info at here: [ helm hub - incubator/zookeeper ](https://hub.helm.sh/charts/incubator/zookeeper)
You can see source at here: [incubator github - zookeeper](https://github.com/bitnami/charts/tree/master/bitnami/zookeeper)
```bash
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com

wget https://raw.githubusercontent.com/helm/charts/master/incubator/zookeeper/values.yaml

# by default, it's zookeeper:3.5.5. you should edit it to 3.5.6 by yourself
vi values.yaml

helm install --name my-release -f values.yaml incubator/zookeeper
```
### chart from bitnami
You can get info at here: [helm hub - bitnami/zookeeper](https://hub.helm.sh/charts/bitnami/zookeeper)
You can see source at here: [bitnami github - zookeeper](https://github.com/bitnami/charts/tree/master/bitnami/zookeeper)
```bash
helm repo add bitnami https://charts.bitnami.com

wget https://raw.githubusercontent.com/bitnami/charts/master/bitnami/zookeeper/values.yaml

vi values.yaml

helm install --name my-release -f values.yaml bitnami/zookeeper
```
### zookeeper in k8s

[github-zookeeper in k8s](https://github.com/JackZxj/zookeeper-in-k8s)


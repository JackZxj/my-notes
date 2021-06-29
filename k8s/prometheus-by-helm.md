# Prometheus by helm3

## install helm3

```BASH
$ wget https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
$ tar -zxvf helm-v3.6.0-linux-amd64.tar.gz
$ mv linux-amd64/helm /usr/local/bin/
$ helm version
version.BuildInfo{Version:"v3.6.0", GitCommit:"7f2df6467771a75f5646b7f12afb408590ed1755", GitTreeState:"clean", GoVersion:"go1.16.3"}
$ rm -rf linux-amd64/

$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
$ helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
$ helm repo add stable https://charts.helm.sh/stable
$ helm repo update
```
## install prometheus

```BASH
# run on master
# prepare for nfs
$ mkdir -p /somewhere/nfsshare/prometheus-server
$ mkdir -p /somewhere/nfsshare/prometheus-alertmanager
$ chown -R 65534:65534 /somewhere/nfsshare/prometheus-server
$ chown -R 65534:65534 /somewhere/nfsshare/prometheus-alertmanager
# create a nfs server for pv
$ docker run -d --name nfs --privileged --restart=always -v /somewhere/nfsshare:/nfsshare -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest
$ kubectl apply -f prometheus-pv.yaml
$ kubectl create ns ocm
$ helm install -n ocm my-prometheus prometheus-community/prometheus
# waiting for pod ready
$ export POD_NAME=$(kubectl get pods --namespace ocm -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
$ kubectl --namespace ocm port-forward --address 0.0.0.0 $POD_NAME 30090:9090
# access it on your browser
```

``` yaml
# prometheus-pv.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-server
spec:
  capacity:
    storage: 8Gi
  claimRef:
    name: my-prometheus-server  # 匹配 release name
    namespace: ocm              # 匹配 release namespace
  accessModes:
    - ReadWriteOnce
  nfs:
    server: 192.168.154.132
    path: "/prometheus-server"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-alertmanager
spec:
  capacity:
    storage: 2Gi
  claimRef:
    name: my-prometheus-alertmanager  # 匹配 release name
    namespace: ocm                    # 匹配 release namespace
  accessModes:
    - ReadWriteOnce
  nfs:
    server: 192.168.154.132
    path: "/prometheus-alertmanager"
```

```BASH
# if pulling images failed, run in all worker node
docker pull bitnami/kube-state-metrics:2.0.0
docker tag bitnami/kube-state-metrics:2.0.0  k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.0.0

docker pull bitnami/alertmanager:0.21.0
docker tag bitnami/alertmanager:0.21.0 quay.io/prometheus/alertmanager:v0.21.0

docker pull bitnami/prometheus:2.26.0
docker tag bitnami/prometheus:2.26.0 quay.io/prometheus/prometheus:v2.26.0
```

## add alert rule

```BASH
$ export CM_NAME=$(kubectl get cm --namespace ocm -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
$ kubectl edit cm $CM_NAME -n ocm
apiVersion: v1
data:
  alerting_rules.yml: |
    {}
  alerts: |
    {}
  example-rules.yaml: | # add this yaml
    groups:
    - name: example-0
      rules:
      - alert: test-alert
        expr: up < 1
        # for: 10s
        labels:
          test: alert
        annotations:
          summary: Instance not up
          last: "{{ $value }}"
  prometheus.yml: |
    global:
      evaluation_interval: 1m
      scrape_interval: 1m
      scrape_timeout: 10s
    rule_files:
    - /etc/config/recording_rules.yml
    - /etc/config/alerting_rules.yml
    - /etc/config/rules
    - /etc/config/alerts
    - /etc/config/example-rules.yaml # add this item
...
```

## uninstall

```BASH
# $ helm uninstall [RELEASE_NAME]
$ helm uninstall -n ocm my-prometheus
```

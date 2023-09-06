# Prometheus by docker-compose

ref: https://www.cnblogs.com/zydev/p/16768810.html

## install docker-compose

```BASH
# ref: https://docs.docker.com/compose/install/linux/#install-using-the-repository
$ sudo apt-get update
$ sudo apt-get install docker-compose-plugin
$ docker compose version
Docker Compose version v2.17.2
```

## prepare prometheus config

```BASH
$ mkdir /etc/prometheus
$ vi /etc/prometheus/prometheus.yml
$ vi /etc/prometheus/rules.yml
$ vi /etc/prometheus/docker-compose.yml
```

```yaml
# /etc/prometheus/prometheus.yml
# 全局配置
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  # scrape_timeout is set to the global default (10s).
# 告警配置
# alerting:
#   alertmanagers:
#     - static_configs:
#         - targets: ['192.168.1.200:9093']
# 加载一次规则，并根据全局“评估间隔”定期评估它们。
rule_files:
  - "/etc/prometheus/rules.yml"
# 控制Prometheus监视哪些资源
# 默认配置中，有一个名为prometheus的作业，它会收集Prometheus服务器公开的时间序列数据。
scrape_configs:
  # 作业名称将作为标签“job=<job_name>`添加到此配置中获取的任何数据。
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
#   - job_name: 'node'
#     static_configs:
#       - targets: ['localhost:9100']
#         labels:
#           env: dev
#           role: docker
```

```yaml
# /etc/prometheus/rules.yml
groups:
- name: example
  rules:
 # Alert for any instance that is unreachable for >5 minutes.
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      serverity: page
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."
```

```yaml
# /etc/prometheus/docker-compose.yml
services:
  prometheus:
   image: bitnami/prometheus
   volumes:
     - /etc/prometheus/:/etc/prometheus/
     - prometheus_data:/prometheus
   command:
     - '--config.file=/etc/prometheus/prometheus.yml'
     - '--storage.tsdb.path=/prometheus'
     - '--web.console.libraries=/usr/share/prometheus/console_libraries'
     - '--web.console.templates=/usr/share/prometheus/consoles'
     - '--web.external-url=http://0.0.0.0:9090/'
     - '--web.enable-lifecycle'
     - '--storage.tsdb.retention=7d'
   ports:
     - 9090:9090
   restart: always
  grafana:
   image: grafana/grafana
   ports:
     - 3000:3000
   volumes:
     - /etc/grafana/:/etc/grafana/provisioning/
     - grafana_data:/var/lib/grafana
#    environment:
#      - GF_INSTALL_PLUGINS=camptocamp-prometheus-alertmanager-datasource
   links:
     - prometheus:prometheus
   restart: always

volumes:
  prometheus_data: {}
  grafana_data: {}
```

## run prometheus

```BASH
$ docker compose  -f /etc/prometheus/docker-compose.yml up -d
$ docker compose  -f /etc/prometheus/docker-compose.yml ps
NAME                      IMAGE                COMMAND                  SERVICE             CREATED             STATUS              PORTS
prometheus-grafana-1      grafana/grafana      "/run.sh"                grafana             3 minutes ago       Up 16 seconds       0.0.0.0:3000->3000/tcp, :::3000->3000/tcp
prometheus-prometheus-1   bitnami/prometheus   "/opt/bitnami/promet…"   prometheus          3 minutes ago       Up 3 minutes        0.0.0.0:9090->9090/tcp, :::9090->9090/tcp

$ curl http://localhost:9090/graph # access it in you browser
$ curl http://localhost:3000/ # access it in you browser, use admin/admin to login at the first
# 1. goto /Home/Administration/Data sources
# 2. add data sources > prometheus > set URL = http://prometheus:9090 (you can use prometheus as domain name as that they are linked by docker-compose) > save & test (if successed) > back > you can see prometheus in your data source list
# 3. build a dashboard or import your dashboard as you like

```


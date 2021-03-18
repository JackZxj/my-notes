# Kubeedge 自定义消息路由简析及试用

## Background

* **实质:**

  通过k8s的crd创建消息路由，借助websocket消息通道，实现云边的消息

* **目标:**
  + cloud to edge (rest->eventbus)

    云端应用发送消息给cloudcore创建的Restful api，cloudcore接收消息后通过eventbus转发给边缘端，通过边缘端的eventbus发布到MQTT topic中

  + edge to cloud (eventbus->rest)

    边缘发布消息到MQTT topic中，通过边缘的eventbus将消息转发至云端，云端接收消息后调用restful api返给云端应用

  + cloud to edge (rest->servicebus) (v1.6尚不可用，预计v1.7上线)

    调用云端cloudcore的api，转发给边缘应用的api

## CRD definition

**RuleEndpoint:**

![RuleEndpoint](../images/kubeedge%20custom%20message/crd-definition-RuleEndpoint.png)

**Rule:**

![Rule](../images/kubeedge%20custom%20message/crd-definition-Rule.png)

## How it works

以 cloud to edge (rest->eventbus) 模式为例:

![Router](../images/kubeedge%20custom%20message/router.png)

## Trying out

### prepare

``` BASH
# On cloud node
$ vi /etc/kubeedge/config/config.yaml
# add "enable: true" to router

# restart cloudcore
$ pkill cloudcore
$ nohup cloudcore > /var/log/kubeedge/cloudcore.log 2>&1 &
```

### 1. cloud to edge (rest->eventbus)

``` yaml
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-rest
  labels:
    description: test
spec:
  ruleEndpointType: "rest"
  properties: {}
---
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-eventbus
  labels:
    description: test
spec:
  ruleEndpointType: "eventbus"
  properties: {}
---
apiVersion: rules.kubeedge.io/v1
kind: Rule
metadata:
  name: my-rule
  labels:
    description: test
spec:
  source: "my-rest"
  sourceResource: {"path":"/a"}
  target: "my-eventbus"
  targetResource: {"topic":"test"}
```

``` BASH
# On edge node:
$ mosquitto_sub -t 'test' -d
# On cloud node:
$ curl -X POST 127.0.0.1:9443/centos78-edge-0/default/a --header 'Content-Type: application/json' -d '{"message":"hello"}'
```

### 2. edge to cloud (eventbus->rest)

``` yaml
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-rest-1
  labels:
    description: test
spec:
  ruleEndpointType: "rest"
  properties: {}
---
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-eventbus-1
  labels:
    description: test
spec:
  ruleEndpointType: "eventbus"
  properties: {}
---
apiVersion: rules.kubeedge.io/v1
kind: Rule
metadata:
  name: my-rule-eventbus-rest
  labels:
    description: test
spec:
  source: "my-eventbus-1"
  sourceResource: {"topic": "test-1","node_name": "centos78-edge-0"}
  target: "my-rest-1"
  targetResource: {"resource":"http://127.0.0.1:8080/test-1"}
```

``` BASH
# on edge node
$ mosquitto_pub -t 'default/test-1' -d -m '{"edgemsg":"msgtocloud"}'
# on cloud node
# cloudcore would POST the message to http://127.0.0.1:8080/test-1
$ go run main.go
method: POST
json: {"edgemsg":"msgtocloud"}
```

### ~~3. cloud to edge (rest->servicebus)~~ plan on v1.7, not available on v1.6

``` yaml
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-rest-3
  labels:
    description: test
spec:
  ruleEndpointType: "rest"
  properties: {}
---
apiVersion: rules.kubeedge.io/v1
kind: RuleEndpoint
metadata:
  name: my-servicebus-1
  labels:
    description: test
spec:
  ruleEndpointType: "servicebus"
  properties: {"service_port":"8080"}
---
apiVersion: rules.kubeedge.io/v1
kind: Rule
metadata:
  name: my-rule-rest-servicebus-1
  labels:
    description: test
spec:
  source: "my-rest-3"
  sourceResource: {"path":"/source-1"}
  target: "my-servicebus-1"
  targetResource: {"path":"/test-1"}
```

``` BASH
# on edge node
$ vi /etc/kubeedge/config/edgecore.yaml
# set "enable: true"

# on cloud node
$ curl -X GET 127.0.0.1:9443/centos78-edge-0/default/source --header 'Content-Type: application/json' -d '{"message":"GET"}'
$ curl -X POST 127.0.0.1:9443/centos78-edge-0/default/source --header 'Content-Type: application/json' -d '{"message":"POST"}'
$ curl -X PUT 127.0.0.1:9443/centos78-edge-0/default/source --header 'Content-Type: application/json' -d '{"message":"PUT"}'
$ curl -X DELETE 127.0.0.1:9443/centos78-edge-0/default/source --header 'Content-Type: application/json' -d '{"message":"DELETE"}'
# on edge node
$ go run main.go

```

## Attachment

**main.go**

``` Go
package main

import (
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
)

func test(w http.ResponseWriter, r *http.Request) {
    defer fmt.Fprintf(w, "ok\n")

    fmt.Println("method:", r.Method)
    body, err := ioutil.ReadAll(r.Body)
    if err != nil {
        fmt.Printf("read body err, %v\n", err)
        return
    }
    println("json:", string(body))
}

func main() {
    http.HandleFunc("/test-1", test)
 
    err := http.ListenAndServe(":8080", nil)
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
```

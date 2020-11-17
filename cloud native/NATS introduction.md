# NATS

![NATS](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/00.png)

> ref: 
> * https://nats.io/
> * https://docs.nats.io/

## 分布式消息

**1. 消息分发模式**

* 请求/响应 或 RPC (Remote Procedure Call)模式
* 事件以及数据流

**2. 分布式计算需求**

* 保证微服务，边缘平台和设备的通信安全
* 单一分布式通信技术中的多租户安全
* 透明的位置寻址和发现
* 着重于系统的整体运行状况的弹性伸缩机制
* 易于大规模用于敏捷开发，CI / CD和操作
* 内置负载平衡和动态自动扩展功能，可高度扩展和高性能
* 从边缘设备到后端服务的一致身份和安全机制

## NATS 简介

NATS是一个**简单**，**安全**，**高性能**的开源消息队列系统，适用于云原生应用程序，IoT消息传递和微服务架构。

客户端通常通过单个URL连接到NATS系统，然后订阅或发布消息给Subject。如果Subscriber没有在监听该Subject，或者在发送消息时未处于活动状态，则不会接收到该消息。

![订阅模式](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/01.png)

## NATS 设计

### 连接

* 客户端使用[NATS协议](https://docs.nats.io/nats-protocol/nats-protocol)（基于文本）连接到服务端
* 基于TCP的[消息总线（message bus）](https://www.enterpriseintegrationpatterns.com/patterns/messaging/MessageBus.html)进行通信
* 所有客户端都在服务端中注册感兴趣的主题，由服务端控制消息分发

### 典型流程

* 建立与服务器的连接并设置错误/通知处理程序。
* （可选）订阅主题和设置处理程序以处理消息。
* （可选）发布消息。
* 完成后，客户端将与NATS服务端断开连接。

![订阅模式](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/02.png)

## NATS Subjects

**Subjects分类**

* Streams
* Topics

**Subjects分层**

* Subjects名由字符串，由字母、数字、“.”组成，区分大小写
* “.”将Subjects分割为不同层级

**Subscriber支持通配符匹配**

* “*”匹配一个层级，可以多次出现
    - a.*.d 匹配 a.b.d 和 a.c.d，不匹配 a.b.c.d
    - a.*.*.d 匹配 a.b.c.d
* “>”匹配一个或者多个层级，但只能出现一次且只能在最后匹配
    - a.b.> 匹配 a.b.c 和 a.b.c.d

![主题订阅](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/03.png)

## 支持模式

### 一对多模式

![一对多订阅](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/04.png)

### 队列组

* 通过内置负载平衡实现
* 可用于便捷实现规模伸缩
    - 伸：添加订阅者app
    - 缩：发送终止信号排空订阅者

![队列组订阅](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/05.png)

### 请求-回复模式

* 订阅者支持动态扩展规模
* 订阅者缩减规模前会保证先发出回复
* 支持以race模式接收回复
    - 仅接收第一个回复
* ACK回复
    - ACK可以为空消息，降低系统负载
    - 可以确认消息超时或者被正确接收

![请求回复](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/06.png)

![ack回复](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/07.png)

### 序列消息

可以在消息中嵌入序列ID或将其作为标记包含在主题中。例如发送者向updates.1, updates.2 ···发送消息，接收者订阅updates.*可以接收所有消息并按照ID确认要接收的消息

![序列消息](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/08.png)

## NATS Server 高可用

使用基于TCP的[集群协议](https://docs.nats.io/nats-protocol/nats-server-protocol)相互连接

* 保证消息不会在集群内循环，且不会在无关路由中传播消息
* 支持发现与集群的其他成员和客户端实时传播拓扑信息和更改
* 从客户端的角度来看，Server群集被视为一个整体，仅需要群集中一台服务器的地址即可连接

![高可用](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/09.png)

![Server路由转发](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/10.png)

## NATS Streaming

![NATS Streaming 1](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/11.png)

* Streaming是NATS的上层，其核心还是NATS
* NATS Streaming服务端与Streaming cluster-id关联，该id与客户端提供的唯一client-id一起用于设置Streaming客户端到服务端通信的内部唯一主题 `sc, err := stan.Connect(clusterID, clientID)`
* 唯一的client-id决定了Streaming无法并行运行
* Streaming客户端可以独立运行并连接到外部的NATS服务集群
* 支持使用Raft算法实现的群集和数据复制，以实现高可用（需要奇数个Server）
* 支持以分区进行扩展

![分区拓展](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/12.png)

## NATS Streaming 功能

![NATS Streaming 2](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/13.png)

* 增强的消息协议
    - 基于Google Protocol Buffers实现
* 消息/事件持久化
    - 支持内存、文件、数据库三种持久化方式
* 至少一次传递
    - 发布者-服务ack
    - 服务-订阅者ack
* 速率限制
    - 可限制单位时间内的最大消息发送量，阻塞多余消息直至限制解除
    - 可限制订阅者接收但未完成确认的数量，阻塞多余的订阅直到低于限制
* 按主题重播历史消息
    - 从最老/最新消息开始
    - 特定的日期（纳秒为单位）
    - 当前服务器时间的偏移量（如最近30秒）
    - 从特定序列号开始
* 持久订阅
    - 订阅名称独立存在
    - 服务会跟踪最后一个确认的持久订阅的消息序号
    - 支持客户端从中断的消息序号处恢复传输

## NATS和NATS Streaming的关系

* Streaming本身不提供服务，而是NATS服务的客户端；Streaming客户端通过NATS服务通信
* Streaming服务在特定主题上创建内部订阅，以与其客户端或其他Streaming服务进行通信
* NATS客户端和NATS Streaming客户端不能相互交换数据
* NATS不支持持久化，Streaming支持但是默认不持久化（存储在内存）
* NATS Streaming服务不支持通配符，即不能订阅foo.*或foo.>等

## NATS与竞品对比

**吞吐量对比**（注：测试时间为2014年）

![吞吐量对比](https://github.com/JackZxj/my-notes/blob/master/images/NATS%20introduction/14.png)

[图源: bravenewgeek](bravenewgeek.com/dissecting-message-queues)

* ActiveMQ（Java编写）
* KafKa（Scala编写）
* RabbitMq（Erlang编写）
* Nats（Go）
* Redis（C语言编写）
* Kestrel（Scala编写）
* NSQ（Go语言编写）

> 测试方法：
> 发送100万条长度为1KB的消息，对比单位时间发送端发送量和接收端接收量，单位为：条/每秒

## NATS 优缺点

### 优点

* 十分轻巧且易用，但保持高性能
* 持续服务能力
* 支持最多一次（fire and forget），最少一次（fire and know）的交付模式
* 支持可观察和可扩展的服务以及事件/数据流
* 客户支持30多种不同的编程语言
* 云原生，具有Kubernetes和Prometheus集成

### 缺点

* 缺少持久化
* 不支持事务处理
* 不支持增强的交付模式

## 使用场景

### NATS

* 云消息传递
    - 服务（微服务，服务网格）
        * 高吞吐量的消息分散
        * 负载均衡
        * 位置透明
        * 容错
    - 事件/数据流（可观察性，分析，ML/AI）
* 命令与控制
    - 物联网和边缘消息
        * 寻址和发现
    - 遥测/传感器数据/命令与控制
* 增强或替换旧消息系统

### NATS Streaming

* 消费者需要从特定时间或特定ID开始消费消息
* 消费者需要按照自己的节奏使用消息
* 消息有持久性需求
* 数据生产者和消费者之间高度脱钩，甚至上线时间都不同

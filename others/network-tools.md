# network tools

```BASH
#安装 dnsutils 可获得 dig。
$ apt install dnsutils

# 安装 netcat 可获得 nc。
$ apt install netcat

# 安装 traceroute (由Dmitry Butskoy开发) 或 inetutils-traceroute (由自由软件基金会开发) 可获得 traceroute。
$ apt install traceroute
$ apt install inetutils-traceroute
-i 指定网络接口，对于多个网络接口有用。比如 -i eth1 或-i ppp1等；
-m 把在外发探测试包中所用的最大生存期设置为max-ttl次转发，默认值为30次；
-n 显示IP地址，不查主机名。当DNS不起作用时常用到这个参数；
-p port 探测包使用的基本UDP端口设置为port ，默认值是33434
-q n 在每次设置生存期时，把探测包的个数设置为值n，默认时为3；
-r 绕过正常的路由表，直接发送到网络相连的主机；
-w n 把对外发探测包的等待响应时间设置为n秒，默认值为3秒；
traceroute -m 10 jb51.net # 把跳数设置为10次；
traceroute -n jb51.net # 注：显示IP地址，不查主机名。
traceroute -p 6888 jb51.net # 注：探测包使用的基本UDP端口设置6888
traceroute -q 4 jb51.net # 注：把探测包的个数设置为值4；
traceroute -r jb51.net # 注：绕过正常的路由表，直接发送到网络相连的主机；
traceroute -w 3 jb51.net # 注：把对外发探测包的等待响应时间设置为5秒；

# 安装 net-tools 可获得 ifconfig。
$ apt install net-tools
$ yum install net-tools

# 安装 iputils-ping 可获得 ping。
$ apt install iputils-ping
```


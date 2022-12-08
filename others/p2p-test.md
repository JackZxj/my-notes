# p2p test

server.go

```Go
package main
​
import (
    "fmt"
    "log"
    "net"
    "time"
)
​
func main() {
    listener, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.IPv4zero, Port: 9981})
    if err != nil {
        fmt.Println(err)
        return
    }
    log.Printf("本地地址: <%s> \n", listener.LocalAddr().String())
    peers := make([]net.UDPAddr, 0, 2)
    data := make([]byte, 1024)
    for {
        n, remoteAddr, err := listener.ReadFromUDP(data)
        if err != nil {
            fmt.Printf("error during read: %s", err)
        }
        log.Printf("<%s> %s\n", remoteAddr.String(), data[:n])
        peers = append(peers, *remoteAddr)
        if len(peers) == 2 {
            log.Printf("进行UDP打洞,建立 %s <--> %s 的连接\n", peers[0].String(), peers[1].String())
            listener.WriteToUDP([]byte(peers[1].String()), &peers[0])
            listener.WriteToUDP([]byte(peers[0].String()), &peers[1])
            time.Sleep(time.Second * 8)
            log.Println("中转服务器退出,仍不影响peers间通信")
            return
        }
    }
}
```


peers.go

``` Go
package main

import (
    "fmt"
    "log"
    "net"
    "os"
    "strconv"
    "strings"
    "time"
)

var tag string

const HAND_SHAKE_MSG = "我是打洞消息"

func main() {
    // 当前进程标记字符串,便于显示
    tag = os.Args[1]
    srcAddr := &net.UDPAddr{IP: net.IPv4zero, Port: 9982} // 注意端口必须固定
    dstAddr := &net.UDPAddr{IP: net.ParseIP("10.110.26.178"), Port: 9981}
    fmt.Println("connect to server...")
    conn, err := net.DialUDP("udp", srcAddr, dstAddr)
    if err != nil {
        fmt.Println(err)
    }
    if _, err = conn.Write([]byte("hello, I'm new peer:" + tag)); err != nil {
        log.Panic(err)
    }
    fmt.Println("connected")
    data := make([]byte, 1024)
    n, remoteAddr, err := conn.ReadFromUDP(data)
    if err != nil {
        fmt.Printf("error during read: %s", err)
    }
    conn.Close()
    anotherPeer := parseAddr(string(data[:n]))
    fmt.Printf("local:%s server:%s another:%s\n", srcAddr, remoteAddr, anotherPeer.String())

    // 开始打洞
    bidirectionHole(srcAddr, &anotherPeer)

}

func parseAddr(addr string) net.UDPAddr {
    t := strings.Split(addr, ":")
    port, _ := strconv.Atoi(t[1])
    return net.UDPAddr{
        IP:   net.ParseIP(t[0]),
        Port: port,
    }
}

func bidirectionHole(srcAddr *net.UDPAddr, anotherAddr *net.UDPAddr) {
    conn, err := net.DialUDP("udp", srcAddr, anotherAddr)
    if err != nil {
        fmt.Println(err)
    }
    defer conn.Close()
    // 向另一个peer发送一条udp消息(对方peer的nat设备会丢弃该消息,非法来源),用意是在自身的nat设备打开一条可进入的通道,这样对方peer就可以发过来udp消息
    if _, err = conn.Write([]byte(HAND_SHAKE_MSG)); err != nil {
        log.Println("send handshake:", err)
    }
    go func() {
        for {
            time.Sleep(10 * time.Second)
            if _, err = conn.Write([]byte("from [" + tag + "]")); err != nil {
                log.Println("send msg fail", err)
            }
        }
    }()
    for {
        data := make([]byte, 1024)
        n, _, err := conn.ReadFromUDP(data)
        if err != nil {
            log.Printf("error during read: %s\n", err)
        } else {
            log.Printf("收到数据:%s\n", data[:n])
        }
    }
}
```

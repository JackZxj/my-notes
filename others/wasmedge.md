# wasmedge

ref: 
* https://wasmedge.org/book/en/index.html
* https://tinygo.org/getting-started/install/
* https://wasmedge.org/wasm_docker/

WasmEdge 是轻量级、安全、高性能、实时的软件容器与运行环境。目前是 CNCF 沙箱项目。WasmEdge 被应用在 SaaS、云原生，service mesh、边缘计算、汽车等领域。

## about wasm

WebAssembly(wasm) 是一种新的编码方式，其编码结果可以产生一种低级的类汇编语句，具有紧凑的二进制格式，可以接近原生的性能运行。（wasm 的原生编程语言还在制定标准中）

简单来说，目前 wasm 不是一种新的编程语言，而是一种可以被 wasm runtime 解析并运行的二进制文本。类似于 java 程序会被编译成字节码 class，这个 class 的地位就跟 wasm 差不多：class 可以被 JVM 解析并运行，wasm 可以被 chrome V8 引擎或者 wasmedge 之类的运行时解析并运行。不同的是 java 的字节码是由 java 语言（及其方言）所编译生成，wasm 可以由多种语言编译生成 (未来也可能支持原生编写)。

```BASH
----------                                               
| golang |-----                                          
----------    |                                          
              |                                          
----------    |      -----------------        ---------- 
| C/C++  |---------->| LLVM Bytecode |------->| wasm   | 
----------    |      -----------------        ---------- 
              |                                          
----------    |                                          
| Rust   |-----                                          
----------    |                                          
              |                                          
----------    |                                          
| ...    |-----                                          
----------                                               
```

WebAssembly 是被设计成 JavaScript 的一个完善补充，而不是它的替代品。其想法是在浏览器中安全地运行由C/C++或Rust等语言编译的高性能应用程序。在现代浏览器中，WebAssembly可以与JavaScript并行运行。随着WebAssembly在云中的使用越来越多，它现在是云原生应用程序的通用运行时。与Linux容器相比，WebAssembly运行时以更低的资源消耗实现了更高的性能。

## about wasmedge

WasmEdge，曾用名 SSVM，是一个开源 WebAssembly 虚拟机，由 Second State 发起，其针对边缘设备进行了优化。根据 IEEE Software 杂志上发表的一篇研究论文，WasmEdge 具有先进的 AOT 编译器支持，是当今市场上最快的 runtime 。 (注：该结论来自 https://ieeexplore.ieee.org/document/9214403 , 该文章由 德克萨斯州立大学 与 Second State 的人员共同发布)

其主要由 `C++` 实现。

## install wasmedge

```BASH
$ curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
$ source $HOME/.bashrc
$ wasmedge -v
wasmedge version 0.11.1
```

**wasm for go runtime**

TinyGo 项目使用官方编译器完全相同的编程语言。然而，TinyGo 使用不同的编译器和工具使其适用于嵌入式系统和 WebAssembly。它主要通过创建更小的二进制文件和针对更广泛的系统来做到这一点。

```BASH
$ wget https://github.com/tinygo-org/tinygo/releases/download/v0.26.0/tinygo_0.26.0_amd64.deb
$ sudo dpkg -i tinygo_0.26.0_amd64.deb
$ tinygo version
tinygo version 0.26.0 linux/amd64 (using go version go1.18.7 and LLVM version 14.0.0)
```

## hello world test

```Go
// main.go
package main

func main() {
  println("Hello TinyGo from WasmEdge!")
}
```

```BASH
# go
$ time go build -o hello main.go # 编译非常快，程序最大
real    0m0.573s
user    0m0.225s
sys     0m0.105s
$ ./hello
Hello TinyGo from WasmEdge!

# tinygo
$ time tinygo build -o hellotinygo main.go # 编译较慢，程序很小
real    0m26.437s
user    0m0.822s
sys     0m0.804s
$ ./hellotinygo
Hello TinyGo from WasmEdge!

# tinygo with wasi
$ time tinygo build -o hellowasm -target wasi main.go # 编译最慢，程序最小，但不能直接运行，需要使用 wasm 运行时
real    0m59.728s
user    0m2.211s
sys     0m1.983s
$ ./hellowasm
-bash: ./hellowasm: cannot execute binary file: Exec format error
$ wasmedge hellowasm
Hello TinyGo from WasmEdge!

# 程序大小比较
$ ls -lh
total 1.3M
-rwxr-xr-x 1 root root 1.2M Oct 25 11:16 hello
-rwxr-xr-x 1 root root  67K Oct 25 11:17 hellotinygo
-rwxr-xr-x 1 root root  56K Oct 25 11:19 hellowasm
-rw-r--r-- 1 root root   82 Oct 25 11:09 main.go
```

## simple function test

注意:
* 无论是否需要 main 中的功能都需要声明一个 main 函数
* 需要使用 `//export` (注意不能带空格) 注释声明函数为导出的，再进行 wasm 编译，否则编译出来的程序无法运行函数

```Go
// main.go
package main

func main() {
  println("Hello TinyGo from WasmEdge!")
}

//export fibArray
func fibArray(n int32) int32{
  arr := make([]int32, n)
  for i := int32(0); i < n; i++ {
    switch {
    case i < 2:
      arr[i] = i
    default:
      arr[i] = arr[i-1] + arr[i-2]
    }
  }
  return arr[n-1]
}
```

```BASH
# 加了一个导出函数，编译时间大大提升
$ time tinygo build -o fib.wasm -target wasi main.go
real    1m34.413s
user    0m2.321s
sys     0m1.981s

# 体积并没有明显提升
$ ls -lh *wasm
-rwxr-xr-x 1 root root 57K Oct 25 11:34 fib.wasm
-rwxr-xr-x 1 root root 56K Oct 25 11:19 hellowasm

# 默认运行 main 函数
$ wasmedge fib.wasm
Hello TinyGo from WasmEdge!

# 使用 reactor 可以指定运行的程序及其参数
$ wasmedge --reactor fib.wasm fibArray 10
34
```

## improve performance test

使用AOT模式可以取得接近原生go的性能

**注：下面的性能测试仅为单次运行情况，可以表示量级区别，无法准确比较具体性能差异**

<details>
<summary>打开/关闭关于 AOT 和 JIT 的说明</summary>

ref: https://www.jianshu.com/p/9004cc1efecb
* JIT
  * 即时编译（Just in Time）
  * 开发效率高: 在开发周期中使用，可以动态下发和执行代码，开发测试效率高,在开发期使用 JIT 编译，可以缩短产品的开发周期。
  * 速度慢: 运行速度和执行性能则会因为运行时即时编译受到影响。
* AOT
  * 运行前编译（Ahead of Time）
  * 速度快：因为在编译的时候它们能够获取到更多的有关程序结构的信息，从而有机会对它们进行优化。
  * 适用性差：它们编译得到的二进制代码往往是CPU相关的，在需要适配多种CPU时，可能需要编译多次。开发效率低,每次调试都需要编译

</details>
<br>

更改 main.go，添加求解Pi的算法来模拟负载提升 (算法来自网络: https://blog.csdn.net/wang805447391/article/details/78301183)

<details>
<summary>打开/关闭 main.go</summary>

```Go
// main.go
package main

import "fmt"

func main() {
	println("Hello TinyGo from WasmEdge!")
	pi(10000)
}

//export fibArray
func fibArray(n int32) int32 {
	arr := make([]int32, n)
	for i := int32(0); i < n; i++ {
		switch {
		case i < 2:
			arr[i] = i
		default:
			arr[i] = arr[i-1] + arr[i-2]
		}
	}
	return arr[n-1]
}

//export pi
func pi(num int) {
	if num <= 0 {
		println("num should be a positive number, set to default: 1000")
		num = 1000
	}

	N := (num)/4 + 1
	s := make([]int, N+3)
	w := make([]int, N+3)
	v := make([]int, N+3)
	q := make([]int, N+3)
	n := (int)(float32(num)/1.39793 + 1)
	w[0] = 16 * 5
	v[0] = 4 * 239
	for k := 1; k <= n; k++ {
		div(w, 25, w, N)
		div(v, 57121, v, N)
		sub(w, v, q, N)
		div(q, 2*k-1, q, N)
		if k%2 != 0 {
			add(s, q, s, N)
		} else {
			sub(s, q, s, N)
		}
	}
	fmt.Printf("%d.", s[0])
	for k := 1; k < N; k++ {
		fmt.Printf("%04d", s[k])
	}
}

func add(a []int, b []int, c []int, N int) {
	i, carry := 0, 0
	for i = N + 1; i >= 0; i-- {
		c[i] = a[i] + b[i] + carry
		if c[i] < 10000 {
			carry = 0
		} else {
			c[i] = c[i] - 10000
			carry = 1
		}
	}
}

func sub(a []int, b []int, c []int, N int) {
	i, borrow := 0, 0
	for i = N + 1; i >= 0; i-- {
		c[i] = a[i] - b[i] - borrow
		if c[i] >= 0 {
			borrow = 0
		} else {
			c[i] = c[i] + 10000
			borrow = 1
		}
	}
}

func div(a []int, b int, c []int, N int) {
	i, tmp, remain := 0, 0, 0
	for i = 0; i <= N+1; i++ {
		tmp = a[i] + remain
		c[i] = tmp / b
		remain = (tmp % b) * 10000
	}
}
```

</details>


```BASH
# 添加了一些逻辑后编译时间大幅提升
$ time tinygo build -o pi.wasm -target wasi main.go
real    6m1.923s
user    0m29.754s
sys     0m14.792s

# 使用 wasmedgec 进行 AOT 编译
$ time wasmedgec pi.wasm piAOT.wasm
real    0m11.483s
user    0m11.396s
sys     0m0.090s

# 原生编译速度最快
$ time go build -o pi main.go
real    0m2.254s
user    0m0.774s
sys     0m0.435s

# 体积明显提升，但相对于原生的体积还是有优势
$ ls -lh pi*
-rwxr-xr-x 1 root root 1.7M Oct 25 17:25 pi
-rwxr-xr-x 1 root root 447K Oct 25 17:24 pi.wasm
-rw-r--r-- 1 root root 816K Oct 25 17:25 piAOT.wasm

# 测试，wasm性能较差
$ time wasmedge pi.wasm # 省略后面1w位
Hello TinyGo from WasmEdge!
3.141592653589793238462643383279502884197169399...
real    1m19.310s
user    1m19.188s
sys     0m0.120s
$ time wasmedge --reactor pi.wasm pi 1000 # 省略后面1k位
3.141592653589793238462643383279502884197169399... 
real    0m0.606s
user    0m0.550s
sys     0m0.049s

# AOT模式性能大幅提升
$ time wasmedge piAOT.wasm # 省略后面1w位
Hello TinyGo from WasmEdge!
3.141592653589793238462643383279502884197169399... 
real    0m0.657s
user    0m0.641s
sys     0m0.010s
$ time wasmedge --reactor piAOT.wasm pi 1000 # 省略后面1k位
3.141592653589793238462643383279502884197169399...
real    0m0.015s
user    0m0.008s
sys     0m0.000s

# 原生程序，性能最强
$ time ./pi # 省略后面1w位
Hello TinyGo from WasmEdge!
3.141592653589793238462643383279502884197169399...
real    0m0.407s
user    0m0.371s
sys     0m0.037s
```

## AOT Mode

wasmegdec 支持两种 AOT 模式，通过生成的后缀名区分

* 通用模式
  * 通用模式会将构建好的二进制程序包装到源 wasm 文件。该模式生成的 wasm 可以被其他 WebAssembly 运行，当使用 wasmedge 时会提取该二进制程序并运行
* 共享库模式
  * 使用特定格式的后缀构建会以共享库输出格式输出（linux: `.so`, macos: `.dylib`, windows: `.dll`），该模式生成的文件只能在 wasmedge 中运行

**注：下面的性能测试仅为单次运行情况，可以表示量级区别，无法准确比较具体性能差异**

```BASH
$ time wasmedgec pi.wasm piAOT.so
real    0m15.605s
user    0m14.173s
sys     0m1.462s

# 共享库模式生成的文件稍大一些
$ ls -lh pi*
-rwxr-xr-x 1 root root 1.7M Oct 25 17:25 pi
-rwxr-xr-x 1 root root 447K Oct 25 17:24 pi.wasm
-rwxr-xr-x 1 root root 837K Oct 26 10:45 piAOT.so
-rw-r--r-- 1 root root 816K Oct 25 17:25 piAOT.wasm

# 运行效率大致与通用模式相同，不知道更大的计算量会不会体现区别
$ time wasmedge piAOT.so # 省略后面1w位
Hello TinyGo from WasmEdge!
3.141592653589793238462643383279502884197169399...
real    0m0.617s
user    0m0.597s
sys     0m0.020s
```

## Embed WasmEdge Into A Host Application

wasmedge 现支持与其他语言的程序进行集成，即其他语言通过引入 wasmedge 的 SDK 工具包，来实现程序中启动一个 wasmedge 虚机，运行 wasm 程序并返回结果。

例如：
有一个 golang 程序，需要使用到一个由 Rust 编写的 AI 程序的结果，经过二次处理后返回给用户。那么目前主流的做法是分别为 go 程序、 rust 程序定义好接口调用方式，通过 restful 或者 rpc 调用实现多语言程序的协同。如果使用 wasm 的技术的话，就可以将该 rust 的程序编译成 wasm 文件，在 go 程序运行时可以按需要启动一个 wasmedge 虚机运行该 wasm 文件，使得单个go程序支持多语言的项目。

* 目前支持 `C` `Go` `Rust` `Node.js` 及一些 Serverless 服务如 aws Lambda
* 目前跨语言集成的参数传递与结果返回仅支持简单参数如字符串、数字等，`Go` `Rust` 可以通过 `bindgen` 支持了一些复杂参数的传递

examples: https://www.secondstate.io/articles/extend-golang-app-with-webassembly-rust/

## Manage WasmEdge apps in CRI-O

![container view](https://www.secondstate.io/articles/manage-webassembly-apps-in-wasmedge-using-docker-tools.png)

上图显示了容器技术栈的分层情况，wasmedge 所存在的位置大约在 Low-level container runtime 中，通过 crun 调用相关的接口实现 wasm 程序的运行。

因此在 Kubernetes 或者 CRI-O 的使用中就可以将 wasm 程序打包到标准容器镜像中，通过层级调用交付给通过 wasmedge 运行。

正因为 wasm 的容器镜像只需要 wasm 的程序文件，不需要额外的程序如 bash、curl、ping 等，因此可以使用最小镜像 scratch 来作为 base image（注：虽然一些编译型语言也可以使用 scratch 作为 baseimage，但毕竟 wasm 编译出来的结果可以更小一点），因此镜像包可以做到很小很精简，运行的安全性也大大提高

目前只有 `crun` 支持 wasm 的镜像，并且该镜像还需要使用 `module.wasm.image/variant=compat-smart` 的注解来标记是普通容器镜像还是 wasm 镜像。

编镜像的流程可参考下方的 [wasm images](#wasm-images) 或者官方文档：https://github.com/second-state/wasmedge-containers-examples/blob/29fe23561f58f5fb11d4009ccf98e8eac174e93c/simple_wasi_app.md

在 CRI-O 中使用的流程可参考 （主要把默认的 runc 改成 crun）：https://github.com/second-state/wasmedge-containers-examples/blob/29fe23561f58f5fb11d4009ccf98e8eac174e93c/crio/README.md

在 kubernetes 中使用的流程（主要是在初始化的时候选择使用 CRI-O 作为容器运行时，并且在 Pod 运行时需要添加 `module.wasm.image/variant=compat-smart` 的注解）可以参考：https://github.com/second-state/wasmedge-containers-examples/blob/a14642f47b25dd9622a16038d9031ea13750e600/kubernetes_crio/README-zh.md

### about crun

一个快速和低内存占用的完全符合 OCI 规范的容器运行时，完全使用 C 编写。

> 虽然 Linux 容器生态系统中使用的大多数工具都是用 Go 编写的，但官方认为 C 更适合于像容器运行时这样的低级工具。runc 是用 Go 编写的 OCI 运行时规范的最常用实现，它会在容器进程启动前重新运行自身，并使用C编写的模块设置一些运行环境。
> 
> crun 的目标也包括作为一个可以轻松地包含在程序中的库，而不需要外部进程来管理 OCI 容器。
> 
> -- from https://github.com/containers/crun#why-another-implementation

相比较 runc 的优势：

* 容器运行的速度更快
* 使用的内存更少 （runc 至少需要 4MB 内存， crun 可以少于 1MB）

### crun with wasmedge

crun 的默认版本同样不支持 wasmedge，因此需要使用 wasmedge 的配置进行编译

ref: https://github.com/containers/crun#dependencies

```BASH
# 安装依赖
$ sudo apt update
$ sudo apt install -y make git gcc build-essential pkgconf libtool \
   libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev \
   go-md2man libtool autoconf python3 automake

# 安装 wasmedge，会把一些依赖头文件导出到 PATH
$ curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
$ source $HOME/.bashrc

# 编译 crun
$ git clone https://github.com/containers/crun
$ cd crun
$ ./autogen.sh
$ ./configure --with-wasmedge   # 默认是不带这个参数的，不带这个参数就无法使用 wasmedge
$ make
$ sudo make install
```

centos7.8 上安装 （建议放弃在centos上安装使用新版本 crun，下面的尝试都失败了）

```BASH
# 安装依赖
$ install -y make automake \
    autoconf gettext \
    libtool gcc libcap-devel systemd-devel libgcrypt-devel \
    glibc-static libseccomp-devel python36 git

# 安装 wasmedge，会把一些依赖头文件导出到 PATH
$ curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
$ source $HOME/.bashrc

# 安装 yajl (yum安装的版本为老版本，不支持新版本)
$ wget https://github.com/lloyd/yajl/archive/refs/tags/2.1.0.tar.gz
$ tar -zxvf 2.1.0.tar.gz
$ cd yajl-2.1.0
$ ./configure # 如果报错  cmake: command not found 则 yum install -y cmake
$ make && make install # 安装
$ cd ..
$ ln -sv /usr/local/lib/libyajl.so.2.1.0 /usr/lib64/libyajl.so
$ ln -sv /usr/local/lib/libyajl.so.2.1.0 /usr/lib64/libyajl.so.2
$ ln -sv /usr/local/lib/libyajl.so.2.1.0 /usr/lib64/libyajl.so.2.1.0
$ ln -sv /usr/local/share/pkgconfig/yajl.pc /usr/lib64/pkgconfig/yajl.pc

# 编译 crun
$ git clone https://github.com/containers/crun
$ cd crun
$ ./autogen.sh
$ export CFLAGS="-g -O2 -std=gnu99" # 设置 gcc flag，默认安装的 gcc 参数不能正常编译
# 禁用 systemd 还有很多问题。因此不建议禁用

# # $ ./configure --with-wasmedge  --disable-systemd  # centos7.8 的 systemd 不满足，需要关闭。详见：https://github.com/containers/crun/issues/359
# $ make
# $ sudo make install

# # 使用 podman 测试 (因为其兼容 docker 命令)
# $ yum install podman
# $ podman version
# Version:            1.6.4
# RemoteAPI Version:  1
# Go Version:         go1.12.12
# OS/Arch:            linux/amd64
# # 运行一个nginx测试
# $ podman run -d docker.io/library/nginx:alpine
# $ podman ps
# $ podman inspect 744d5faa49f2 | grep OCIRuntime # 744d5faa49f2 是刚刚运行的 nginx 的 CONTAINER ID
#         "OCIRuntime": "runc",
# # podman默认运行时为runc，修改配置为crun
# # 因为编译 crun 时禁用了 systemd , 因此使用 cgroupfs
# $ vi /usr/share/containers/libpod.conf # 这是老版本的配置，新版本的配置可能在 /usr/share/containers/containers.conf
# ...
# # CGroup Manager - valid values are "systemd" and "cgroupfs"
# cgroup_manager = "cgroupfs"
# ...
# # Default OCI runtime
# runtime = "crun"
# ...
# $ podman run -d -p 8080:80 docker.io/library/nginx:alpine # 报错，怀疑是因为内核版本太低不兼容了。。
# Error: open file `/proc/thread-self/attr/exec`: No such file or directory: OCI runtime command not found error 

# 更新 systemd 版本，跟新版本也不兼容，可能需要更新的版本

# # 1. 禁用SELINUX
# $ setenforce 0 # 临时禁用
# $ vi /etc/selinux/config # 永久禁用
# ...
# SELINUX=disabled
# ...
# # 2. 下载新版本 systemd
# $ wget https://copr.fedorainfracloud.org/coprs/jsynacek/systemd-backports-for-centos-7/repo/epel-7/jsynacek-systemd-backports-for-centos-7-epel-7.repo -O /etc/yum.repos.d/jsynacek-systemd-centos-7.repo
# $ yum update systemd
# $ reboot now
# $ rpm -q systemd

# # 继续编译crun
# $ cd crun
# $ ./autogen.sh
# $ export CFLAGS="-g -O2 -std=gnu99" # 设置 gcc flag，默认安装的 gcc 参数不能正常编译

# $ ./configure --with-wasmedge
# ...
# checking for systemd/sd-bus.h... yes
# checking for library containing sd_bus_match_signal_async... no
# configure: error: *** Failed to find libsystemd
```

### crun with other runtime

ref: 
* [Want to know about different WASM runtimes ?](https://www.wasm.builders/shravi_inamdar/want-to-know-about-different-wasm-runtimes--518j)
* [WebAssembly生态及关键技术综述](https://blog.csdn.net/qiwoo_weekly/article/details/125883779)

在 crun 构建时可以使用以下参数来支持其他运行时

```BASH
  --with-mono             build with mono support
  --with-wasmer           build with wasmer support
  --with-wasmtime         build with wasmtime support
  --with-wasmedge         build with WasmEdge support
  --with-libkrun          build with libkrun support
```

参数说明：
* with-mono:
  * dotnet 容器的运行时，可以将 dotnet 技术栈的程序打包成镜像用于运行。可以参考官方示例：https://github.com/containers/crun/blob/main/docs/mono-example.md
* with-wasm* （都是 wasm 的运行时）
  * wasmer: （来自 wasmer 独立公司）
    * 可插拔性：与各种编译框架兼容，无论您需要什么（例如：Cranelift、LLVM）
    * 速度/安全性：能够在完全沙盒的环境中以接近本机的速度运行Wasm。（官方宣传比 wasmtime 快）
    * 通用性：适用于任何平台（Windows，Linux等）和芯片组
    * 支持：符合WebAssembly测试套件标准，拥有庞大的开发人员和贡献者社区支持
  * wasmtime: (目前主要支持 x86 环境，来自 bytecode alliance，其成员包括 aws、google、微软、Intel、ARM 等巨头)
    * 紧凑：要求不高的独立运行时，您可以随着需求的增长而扩展。可以使用小型芯片或与大型服务器一起使用。几乎可嵌入任何应用程序
    * 易于修改：调整Wasmtime以进行预编译，使用Lightbeam生成光速代码，或用于运行时解释。配置您需要 Wasm 完成的任何任务
    * 快速：与 Cranelift 兼容;运行高效
    * 与 WASI 兼容：支持更新 API，允许自定义符合 WASI 接口规范的实现
    * 支持：符合WebAssembly测试套件标准，拥有庞大的开发人员和贡献者社区支持
  * wasmedge:
    * 主要应用在云原生，希望抢占边缘计算场景下的容器运行时市场
* with-libkrun
  * libkrun是一个动态库，允许程序使用KVM虚拟化轻松获得在部分隔离环境中运行进程的能力。
  * 它将VMM（虚拟机监视器，虚拟机监控程序的用户空间侧）与其目的所需的最少数量的仿真设备集成在一起，抽象了虚拟机管理带来的大部分复杂性，为用户提供了一个简单的C API。

### wasm images

ref:
* [Buildah入门](https://zhuanlan.zhihu.com/p/39736486)

目前 wasm 的容器镜像不支持使用 docker 构建，因为 docker 不支持 wasm 所需的镜像注解 `annotation` 功能。因此使用另外的命令行工具 `buildah` 来构建镜像。

`buildah` 是一个与 OCI 标准兼容的镜像构建工具，其除了支持 Dockerfile 模式构建之外，还支持命令行模式进行镜像构建。

与docker不同的是: docker build 需要 dockerd (docker 的守护进程)来构建，而 buildah 不需要额外的组件；docker build会按层级构建，并且每一层都会缓存，而 buildah 只是从头到尾进行一次构建（docker模式还是支持分层构建）；buildah 还支持命令行进行构建，通过内置的命令可以实现类似 dockerfile 的指令，最终打包成镜像。

使用 buildah 构建 wasm 镜像的流程：

1. 将程序编译成 wasm 文件（生产环境建议使用AOT编译以加快运行），在文件夹中创建一个名为 `Dockerfile` 的文件，内容如下：

```Dockerfile
FROM scratch
COPY hello.wasm /
CMD ["/hello.wasm"]
```

2. 使用 buildah 打包镜像，注意一定要添加 `module.wasm.image/variant=compat` 的注解

```BASH
# 编译镜像
$ sudo buildah bud --annotation "module.wasm.image/variant=compat" -t mywasm-image .
# 推到镜像仓库，authfile 是docker仓库的用户信息
$ sudo buildah push --authfile ~/.docker/config.json mywasm-image docker://docker.io/myrepo/example-wasi:latest
# 运行镜像，需要注意 podman 需要切换到 crun 运行时，并且 crun 需要打开 wasm 支持
$ podman run mywasm-image:latest
```

## wasmedge with micro-kernel

ref:
* [边缘的容器化 — WasmEdge 与 seL4](https://blog.csdn.net/weixin_42376823/article/details/121339850)
* [WasmEdge on seL4](https://github.com/second-state/wasmedge-seL4)
* [Build WasmEdge for Open Harmony](https://github.com/WasmEdge/WasmEdge/blob/master/utils/ohos/README-zh.md)

简单来说就是将 wasmedge 编译成对应平台的可执行程序打包到对应系统中，提供相应的包调用方式即可

## wasmedge with TensorFlow

ref: 
* [A WASI-like extension for Tensorflow](https://www.secondstate.io/articles/wasi-tensorflow/)

AI推理是一项计算密集型任务，可以从Rust和WebAssembly的速度中受益匪浅。但是，标准 WebAssembly 沙箱提供对本机操作系统和硬件（如多核 CPU、GPU 和专用 AI 推理芯片）的访问非常有限。它不适合 AI 工作负载。

流行的 WASI 为沙盒 WebAssembly 程序提供了一种设计模式，以安全地访问本机主机函数。WasmEdge 扩展了该 WASI 模型，以支持从 WebAssembly 程序访问本机 Tensorflow libraries。wasmedge 提供了WebAssembly的安全性，可移植性和易用性以及Tensorflow的类原生速度。

## wasmedge advantage and disadvantage

wasmedge 的一些优势：

* 在一些非 POSIX 的操作系统中（如微内核操作系统、RTOS），无法使用类似 Docker 运行时，可以使用 WebAssembly 这种抽象系统提供统一的编程语言及 SDK
* wasmedge 除了支持标准 WebAssembly 规范，还支持云原生应用场景的 API，如 network、TensorFlow、KV storage 等
* 完全符合 OCI 标准，可以被标准容器工具存储、管理和执行
* 程序/镜像更小，启动更快

一些缺点：

* 程序需要特异性编译，目前支持的语言还有限，主要包括 C、Rust、Javascript、Go、Swift、Kotlin、Python
* 程序不支持多线程，仅支持异步应用

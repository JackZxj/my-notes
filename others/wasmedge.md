# wasmedge

ref: 
* https://wasmedge.org/book/en/index.html
* https://tinygo.org/getting-started/install/
* https://wasmedge.org/wasm_docker/

WasmEdge 是轻量级、安全、高性能、实时的软件容器与运行环境。目前是 CNCF 沙箱项目。WasmEdge 被应用在 SaaS、云原生，service mesh、边缘计算、汽车等领域。

## install

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

* wasmedge 现支持与其他语言的程序进行集成，目前支持 `C` `Go` `Rust` `Node.js` 及一些 Serverless 服务如 aws Lambda
* 目前跨语言集成的参数传递与结果返回仅支持简单参数如字符串、数字等，`Go` `Rust` 可以通过 `bindgen` 支持了一些复杂参数的传递

examples: https://www.secondstate.io/articles/extend-golang-app-with-webassembly-rust/

## Manage WasmEdge apps in CRI-O

![container view](https://www.secondstate.io/articles/manage-webassembly-apps-in-wasmedge-using-docker-tools.png)

上图显示了容器技术栈的分层情况，wasmedge 所存在的位置大约在 Low-level container runtime 中，通过 crun 调用相关的接口实现 wasm 程序的运行。

因此在 Kubernetes 或者 CRI-O 的使用中就可以将 wasm 程序打包到标准容器镜像中，通过层级调用交付给通过 wasmedge 运行。

正因为 wasm 的容器镜像只需要 wasm 的程序文件，不需要额外的程序如 bash、curl、ping 等，因此可以使用最小镜像 scratch 来作为 base image（注：虽然一些编译型语言也可以使用 scratch 作为 baseimage，但毕竟 wasm 编译出来的结果可以更小一点），因此镜像包可以做到很小很精简，运行的安全性也大大提高

目前只有 `crun` 支持 wasm 的镜像，并且该镜像还需要使用 `module.wasm.image/variant=compat-smart` 的注解来标记是普通容器镜像还是 wasm 镜像。

编镜像的流程可参考：https://github.com/second-state/wasmedge-containers-examples/blob/29fe23561f58f5fb11d4009ccf98e8eac174e93c/simple_wasi_app.md

在 CRI-O 中使用的流程可参考 （主要把默认的 runc 改成 crun）：https://github.com/second-state/wasmedge-containers-examples/blob/29fe23561f58f5fb11d4009ccf98e8eac174e93c/crio/README.md

在 kubernetes 中使用的流程（主要是在初始化的时候选择使用 CRI-O 作为容器运行时，并且在 Pod 运行时需要添加 `module.wasm.image/variant=compat-smart` 的注解）可以参考：https://github.com/second-state/wasmedge-containers-examples/blob/a14642f47b25dd9622a16038d9031ea13750e600/kubernetes_crio/README-zh.md

## wasmedge advantage and disadvantage

wasmedge 的一些优势：

* 在一些非 POSIX 的操作系统中（如微内核操作系统、RTOS），无法使用类似 Docker 运行时，可以使用 WebAssembly 这种抽象系统提供统一的编程语言及 SDK
* wasmedge 除了支持标准 WebAssembly 规范，还支持云原生应用场景的 API，如 network、TensorFlow、KV storage 等
* 完全符合 OCI 标准，可以被标准容器工具存储、管理和执行
* 程序/镜像更小，启动更快

一些缺点：

* 程序需要特异性编译，目前支持的语言还有限，主要包括 C、Rust、Javascript、Go、Swift、Kotlin、Python
* 程序不支持多线程，仅支持异步应用

# rt-thread 测试

## keil 模拟器 STM32F103 测试

1. 安装 keil MDK，参考： [Keil MDK 安装](https://www.rt-thread.org/document/site/#/rt-thread-version/rt-thread-standard/tutorial/quick-start/keil/keil)
2. 下载安装 STM32F103 pack 文件，可到官网下载： [STM32F1 Series Device Support, Drivers and Examples](https://www.keil.com/dd2/stmicroelectronics/stm32f103zf/)
3. 【可选】如果安装的 keil 版本为 5.37 之后的版本，默认安装的编译器为 compiler version 6，运行官方示例会报错: `*** Target ‘xxx‘ uses ARM-Compiler ‘Default Compiler Version 5‘ which is not available.` ，因此需要手动安装 compiler version 5，具体流程可参考：[keil5 报错](https://blog.csdn.net/weixin_45028335/article/details/126291787)。需要注意如果是到官网下载需要使用电话号码注册下载。
4. 下载官方例程，并解压到某个目录：[RT-Thread Simulator 例程](https://gitee.com/rtthread/docs-online/raw/master/rt-thread-version/rt-thread-standard/tutorial/quick-start/stm32f103-simulator/rtthread_simulator_v0.1.0.7z)
5. 按照官方指引运行跑马灯测试: [官方指引](https://www.rt-thread.org/document/site/#/rt-thread-version/rt-thread-standard/tutorial/quick-start/stm32f103-simulator/stm32f103-simulator)

可能遇到的问题:
1. `…/Drivers/STM32F0xx_HAL_Driver/Src/stm32f0xx_hal_rcc_ex.c(134): error: #268: declaration may not appear after executable statement in block` 参考：[keil添加 c99 编译支持](https://blog.csdn.net/weixin_44503803/article/details/112555868)
2. `keil只能单步调试，不能自动运行` 参考：[keil 开启自动运行](https://blog.csdn.net/qq_44819943/article/details/98348101)

**结论：**

keil 模拟器确实能模拟运行 rt-thread ，可以完成一些简单的嵌入式程序开发。示例所用的 stm32 整体性能较低，无法承接一些程序的移植工作。由于不是很熟悉 keil，故放弃自行配置高规格的模拟器。

## QEMU+env 模拟测试

1. 下载源码，[github - RT-Thread/rt-thread](https://github.com/RT-Thread/rt-thread), 国内可使用 [gitee - RT-Thread/rt-thread](https://gitee.com/rtthread/rt-thread) 加速
2. 下载 env 工具：[官网下载：RT-Thread env 工具](https://www.rt-thread.org/download.html#download-rt-thread-env-tool)
3. 按照教程编译和运行工程： [qemu](https://www.rt-thread.org/document/site/#/rt-thread-version/rt-thread-standard/application-note/setup/qemu/windows/an0006-qemu-windows?id=%e7%bc%96%e8%af%91%e5%92%8c%e8%bf%90%e8%a1%8c%e5%b7%a5%e7%a8%8b)
  + 官方教程里的开启 ping 工具在新版本的源码中已经默认打开，不需要再手动打开，如果老版本或者没打开再参考教程
  + GUI 引擎不是必须，可以不用
4. 使用 ftp 工具传输文件 [关于 rt-thread tftp](https://github.com/RT-Thread-packages/netutils/tree/master/tftp)
  + 需要按照教程安装好 tap 网卡，配置好 qemu 参数
  + 使用 tftp 传输文件：参考 [rt_thread-基于TFTP 传输文件](https://blog.csdn.net/u012210286/article/details/118380253)，一定要使用 tftp 客户端来传输文件，其他 ftp 客户端不兼容，下载地址: https://bitbucket.org/phjounin/tftpd64/downloads/, windows 可以下载这个： https://bitbucket.org/phjounin/tftpd64/downloads/Tftpd64-4.64-setup.exe
5. 在 rt-thread 上运行 wamr（wasm-micro-runtime）
  + 参考： [在 rt-thread 上运行 wamr](https://blog.csdn.net/hh1986170901/article/details/122618074)
  + rt-thread 上默认使用 latest 版本的 wamr，如果需要切换到指定版本可以自行更改 package 信息 (latest 版本不一定能用，最好还是使用 release 版本)
    * package 信息在你下载的 env 文件夹的 `packages\packages\tools\wamr\package.json` 里，额外的版本可以添加到 `site` 里：
      ```json
        ...
        "site": [
          {
            "version": "v20220118",
            "URL": "https://github.com/bytecodealliance/wasm-micro-runtime/archive/refs/tags/WAMR-01-18-2022.zip",
            "filename": "WAMR-01-18-2022.zip",
            "VER_SHA": "fill in the git version SHA value"
          },
          {
            "version": "latest",
            "URL": "https://github.com/bytecodealliance/wasm-micro-runtime.git",
            "VER_SHA": "main"
          }
        ]
        ...
      ```
    * 除了上述之外还需要同步修改 Kconfig 以支持版本选择，在上述 package.json 同目录下 `packages\packages\tools\wamr\Kconfig`：
      ``` conf
      ...
          choice
              prompt "Version"
              default PKG_USING_WAMR_V20220118_VERSION
              help
                  Select the package version
      
              config PKG_USING_WAMR_V20220118_VERSION
                  bool "v20220118"
      
              config PKG_USING_WAMR_LATEST_VERSION
                  bool "latest"
          endchoice
      ...
          config PKG_WAMR_VER
             string
             default "latest"       if PKG_USING_WAMR_LATEST_VERSION
             default "v20220118"    if PKG_USING_WAMR_V20220118_VERSION
      ...
      ```

**结论：**

想要在rt-thread上使用wasmedge需要进行跨平台编译，首先需要确认rt-thread的处理器架构（需要较强性能及编译的兼容性），然后需要了解交叉编译的人对wasmedge的源码进行一定修改，编译出适合rt-thread的版本，或者做成rt-thread的软件包，在编译rt-thread os的时候作为内置软件编译进系统。

wamr的兼容性一般，看网上的文章是能运行c编译的wasm程序，但本人目前没有尝试c编译，因此此处保留意见。而基于tinygo的wasm程序目前不能在rt-thread上运行，但是在x86_64的wamr可以运行，看报错应该是编译出来的wamr删减了部分模块（可能是因为rt-thread的一些系统包不支持，所以被删减），个人尝试过手动打开部分模块也无法被成功运行，个人修改过的完整版 packages\packages\tools\wamr\Kconfig 如下（最终还是编译失败）：

```Makefile
# Kconfig file for package wamr
menuconfig PKG_USING_WAMR
    bool "WebAssembly Micro Runtime (WAMR)"
    select RT_USING_LIBC     if RT_VER_NUM < 0x40100
    select RT_USING_DFS      if RT_VER_NUM < 0x40100
    select RT_USING_POSIX_FS if RT_VER_NUM >= 0x40100
    default n

if PKG_USING_WAMR

    config PKG_WAMR_PATH
        string
        default "/packages/tools/wamr"

    choice
        prompt "Version"
        default PKG_USING_WAMR_V20210129_VERSION
        help
            Select the package version

        config PKG_USING_WAMR_V20210129_VERSION
            bool "v20210129"

        config PKG_USING_WAMR_V20220118_VERSION
            bool "v20220118"

        config PKG_USING_WAMR_LATEST_VERSION
            bool "latest"
    endchoice

    config WAMR_ENABLE_IWASM_PARAMS
        bool
        prompt "Enable testing parameters of iwasm"
        default n

    config WAMR_BUILD_INTERP
        bool
        prompt "Enable Interpter Mode"
        default y

    if WAMR_BUILD_INTERP

        config WAMR_BUILD_FAST_INTERP
            bool
            prompt "Enable Fast Interpter"
            default y

    endif

    config WAMR_BUILD_LIBC_BUILTIN
        bool
        prompt "Use built-libc"
        default y

    config WAMR_BUILD_AOT
        bool
        prompt "Enable AOT"
        default n

    config WAMR_ENABLE_RTT_EXPORT
        bool
        prompt "Export Native Method of RT-Thread"
        default n

    if WAMR_ENABLE_RTT_EXPORT

        config WAMR_RTT_EXPORT_VPRINTF
            bool
            prompt "Export vprintf"
            default n

        config WAMR_RTT_EXPORT_DEVICE_OPS
            bool
            prompt "Export Device Operate Method"
            default n

        if WAMR_RTT_EXPORT_DEVICE_OPS
            config WAMR_RTT_EXPORT_DEVICE_OPS_CPP
                bool
                prompt "Enable WASM Cpp Support of Device Operate Method"
                default n
        endif

    endif

    config WAMR_BUILD_BULK_MEMORY
        int
        prompt "Enable WASM bulk memory feature"
        default 1

    config ENABLE_WASM_ENABLE_LIBC_WASI
        bool
        prompt "Enable WASM libc wasi"
        default y

    if ENABLE_WASM_ENABLE_LIBC_WASI

        config WAMR_BUILD_LIBC_WASI
            int
            prompt "Enable WASM build libc wasi"
            default 1

        config WASM_ENABLE_UVWASI
            int
            prompt "Enable WASM uvwasi"
            default 0

    endif

    config WASM_ENABLE_LIBC_WASI
       int
       default 0    if !ENABLE_WASM_ENABLE_LIBC_WASI
       default 1    if ENABLE_WASM_ENABLE_LIBC_WASI

    config PKG_WAMR_VER
       string
       default "latest"       if PKG_USING_WAMR_LATEST_VERSION
       default "v20210129"    if PKG_USING_WAMR_V20210129_VERSION
       default "v20220118"    if PKG_USING_WAMR_V20220118_VERSION

endif
```

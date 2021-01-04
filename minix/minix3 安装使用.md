# minix 3.3 安装使用

## 安装

1. [官网](https://wiki.minix3.org/doku.php?id=www:download:start)下载安装包

2. VMware 安装虚机
    - 新建虚拟机 - 典型 - 稍后安装系统 - 其他/其他 - 虚机名称及位置 - 硬盘设置（一般8G足够，如果要安装全部的软件则至少需要25G的空间以上） - 自定义硬件调整内存（clang编译至少需要512MB）以及挂载上一步下载的iso - 完成
    - 启动虚机，按照提示进行初始化配置

## 使用

minix3 使用和 `bash` 相近的 `ash` ，大部分语法相通，但还是有区别。minix3 使用 `pkgin` 安装软件。

``` BASH
# 初始化后需要更新仓库数据才能下载新的软件包
$ pkgin update

# 安装ssh
$ pkgin -y install openssh

# 查看 IP 以用于 xshell 远程登录
$ ifconfig

# 下载 clang 编译器以及一些链接库才能进行 c 编译
$ pkgin install clang binutils
# 国内的网络环境比较随缘，很可能下载不下来。
# 找一个可以翻墙的机器，网页打开 http://www.minix3.org/pkgsrc/packages/3.3.0/i386/All/
# 手动下载需要的安装包
# 用 xftp 将下载下来的 tgz 压缩包放到 /usr/pkg/var/db/pkgin/cache 目录下
# 然后再重新执行安装命令就能装上了

# 安装 vim 编辑器
$ pkgin -y install vim
# 解决 vim insert 模式下方向键不可用的办法
$ echo "set nocp" >> ~/.vimrc
# 通常使用 source ~/.vimrc 生效配置，但是 minix 没有 source，不知道怎么生效，使用重启可以实现。。

```

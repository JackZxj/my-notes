## dos2unix

```bash
# 文件夹内的文件批量转码 dos to unix
find . -name "*.sh" | xargs sed -i 's/\r$//g'
find . -type f | xargs sed -i 's/\r$//g'

# windows 版的 git 附带了 dos/unix 相互转化的工具，下面的命令需要在git bash中运行
# 将文件夹内所有文件 dos 转 unix
find . -type f -exec dos2unix {} \;
# 将文件夹内所有文件 unix 转 dos
find . -type f -exec unix2dos {} \;
```

## yum查找安装路径

```BASH
# 先查找想要查询的安装包关键词，得到完整名称
$ rpm -qa | grep vim

# 通过完整名称就能查到改软件包所有文件的路径了
$ rpm -ql vim-common-7.4.629-8.el7_9.x86_64
```

```bash
# 文件夹内的文件批量转码 dos to unix
find . -name "*.sh" | xargs sed -i 's/\r$//g'
find . -type f | xargs sed -i 's/\r$//g'

# windows 版的 git 附带了 dos/unix 相互转化的工具
# 将文件夹内所有文件 dos 转 unix
find . -type f -exec dos2unix {} \;
# 将文件夹内所有文件 unix 转 dos
find . -type f -exec unix2dos {} \;
```
# linux cmd

## grep

```BASH
# grep 附近 n 行
grep xx -A/B/C n # A 前 B 后 C 上下

# grep 排除
grep -v xx

# grep 或
grep "xx\|yy\|zz" # 需要引号
grep -E "xx|yy|zz" # 需要引号 == egrep "xx|yy|zz"
grep -e xx -e yy -e zz 

# grep 与
grep "xx.*yy" # 借助通配符
```

## xargs

**test.sh**

```BASH
#!/bin/bash
echo "start $1"
sleep 3
echo "end $1"
```

```BASH
# 并行运行
for i in {1..5};do echo "$i"; done | xargs -P 3 -i sh test.sh {}   # 执行 test.sh文件 ，开启3个并行 {} 指代管道前的输出，一般每次取一行
```

## awk

```BASH
# 同时取第1，n，5列
ls -la | awk '{print $1,$n,$5}' # 注意单引号

# 按照空格分割输入，取倒数第1,2列,使用tab分割
ls -la | awk -F ' ' '{print $NF,"\t",$(NF-1)}' # F 分隔符， NF 最后一列

# 打印行
ls -la | awk 'NR==2{print}' # NR表示当前行号
```

## date

```BASH
date +'+%F %T'                                  # 通常日期 2022-06-15 09:27:33    %F = %Y-%m-%d    %T = %H:%M:%S
date +'%Y-%m-%d/%H:%M:%S.%N'                    # 精确纳秒 2022-06-15/09:27:33.426702255
date +'%Y-%m-%d/%H:%M:%S.%N' | cut -b 1-23      # 精确毫秒 2022-06-15/09:27:33.426
date +%s                                        # 秒时间戳 1655256697
date '+%s%N'                                    # 纳秒时间戳 1655257691027328126
date -d '@1655256697'                           # 秒时间戳转时间
```

## jq

```BASH
# installation
sudo api-get install jq
sudo yum install jq # sudo dnf install jq
brew install jq

# usage
# input           | override or add    | override as obj         | add an array        | remove item       | simple calculate
echo '{"foo": 0}' | jq '.foo=3|.bar=4' | jq '.foo = {a:1,b:"B"}' | jq '.arr=[1,2,"3"]' | jq 'del(.arr[1])' | jq '.arr[0]=(.arr[0] + 2)*5/3-(1+2) | .arr[1]=.arr[1] + "111"'
```


## OOM

```BASH
for x in {1..9999}; do echo "Round $x"; bash -c "for b in {0..99999999}; do a=$b$a; done &"; done
```

## duplicate and repeat templates

```BASH
for i in {0..99}; do sed -e "s/jack-nginx-03/jack-nginx-$i/g" tmp/deploy-with-cm-secret-template.yaml>>tmp/deploy-with-cm-secret-100x.yaml; done
```

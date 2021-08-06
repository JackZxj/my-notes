# docker registry

https://docs.docker.com/registry/spec/api/

## docker api

``` BASH
# 查看 registry 的镜像列表
$ curl 127.0.0.1:5000/v2/_catalog
{"repositories":["destination","destination-nats","js-demo","k8simage/coredns","k8simage/etcd","k8simage/flannel","k8simage/haproxy","k8simage/kube-apiserver","k8simage/kube-controller-manager","k8simage/kube-proxy","k8simage/kube-scheduler","k8simage/osixia/keepalived","k8simage/pause","operator-demo","source","source-nats"]}

# 查看某一个镜像名的 tag 列表
# $ curl 127.0.0.1:5000/v2/{image_name}/tags/list
$ curl 127.0.0.1:5000/v2/k8simage/haproxy/tags/list
{"name":"k8simage/haproxy","tags":["2.1.0-alpine"]}
```

## 从 registry 中保存正在运行中的镜像到 tar 包

```BASH
#!/bin/bash
set -o errexit

lastline=""
# kubectl get deploy --all-namespaces -owide | awk '{if(NR>1)print $9}' | grep 5000 | while read line
kubectl get rs --all-namespaces -owide | awk '{if(NR>1)print $8}' | grep 5000 | while read line
do
    # 去重
    if [ "$lastline" == "$line" ]; then
        continue
    fi
    lastline=$line
    nline=${line#*/}                        # 移除前面的镜像地址
    newLine=${nline/\//_}                   # 替换/为_
    echo "### save" $line "to" $newLine.tar     # 输出一下

    if docker pull $line;
    then
        docker save -o $newLine.tar $line
        docker rmi $line
    else
        echo -e "\033[31mError:\033[0m can not pull" $line
    fi
    echo ""
done

echo "done"
```


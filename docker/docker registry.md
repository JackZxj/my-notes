``` BASH
# 查看 registry 的镜像列表
$ curl 127.0.0.1:5000/v2/_catalog
{"repositories":["destination","destination-nats","js-demo","k8simage/coredns","k8simage/etcd","k8simage/flannel","k8simage/haproxy","k8simage/kube-apiserver","k8simage/kube-controller-manager","k8simage/kube-proxy","k8simage/kube-scheduler","k8simage/osixia/keepalived","k8simage/pause","operator-demo","source","source-nats"]}

# 查看某一个镜像名的 tag 列表
# $ curl 127.0.0.1:5000/v2/{image_name}/tags/list
$ curl 127.0.0.1:5000/v2/k8simage/haproxy/tags/list
{"name":"k8simage/haproxy","tags":["2.1.0-alpine"]}
```

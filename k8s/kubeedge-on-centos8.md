# KubeEdge在CentOS8.0下的安装和部署流程详解

https://mp.weixin.qq.com/s/igvL9nmYV8Hmtzg0ptcXYQ

# Kubelet 额外参数

``` BASH
[root@ke-cloud ~]# cat >/etc/sysconfig/kubelet<<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=$DOCKER_CGROUPS --pod-infra-container-image=k8s.gcr.io/pause:3.1"
EOF
```

# Update InternalIP of k8s node

ref: https://yanbin.blog/kubernetes-cluster-internal-ip-issue/

## before

`10.1.0.178` is a virtual IP, and it's my master hostname. `172.31.0.7` is the real IP.

```BASH
# using a INTERNAL-IP which not my target IP
$ kubectl get no -owide
NAME            STATUS   ROLES                  AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION          CONTAINER-RUNTIME
10.1.0.178      Ready    control-plane,master   16s   v1.20.2   10.1.0.178      <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64   docker://19.3.0
```

## after

```BASH
# using the target IP
$ kubectl get no -owide
NAME            STATUS   ROLES                  AGE    VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION          CONTAINER-RUNTIME
10.1.0.178      Ready    control-plane,master   6m8s   v1.20.2   172.31.0.7    <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64   docker://19.3.0
```

## how to do

```BASH
# get kubelet info
$ systemctl status kubelet
● kubelet.service - kubelet: The Kubernetes Node Agent
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
  Drop-In: /usr/lib/systemd/system/kubelet.service.d
           └─10-kubeadm.conf
   Active: active (running) since Fri 2021-10-15 21:12:32 CST; 7s ago
     Docs: https://kubernetes.io/docs/
...

# get the drpo-in file
$ cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf | grep EnvironmentFile
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
EnvironmentFile=-/etc/sysconfig/kubelet

# edit the env file, add '--node-ip=172.31.0.7' for it
$ vi /var/lib/kubelet/kubeadm-flags.env
KUBELET_KUBEADM_ARGS="--node-ip=172.31.0.7 --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.2"

# restar kubelet
$ systemctl daemon-reload
$ systemctl restart kubelet
```


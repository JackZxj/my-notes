# get infos from ETCD

``` bash
$ kubectl describe po -n kube-system etcd-10.110.26.178
...
  etcd:
    Container ID:  docker://8547283fc3adeb17ac8ac70a23094f79d9a3b6f81d57696feaf83207bf73f597
    Image:         registry.aliyuncs.com/google_containers/etcd:3.4.13-0
    Image ID:      docker-pullable://172.31.0.7:5000/etcd@sha256:bd4d2c9a19be8a492bc79df53eee199fd04b415e9993eb69f7718052602a147a
    Port:          <none>
    Host Port:     <none>
    Command:
      etcd
      --advertise-client-urls=https://172.31.0.7:2379
      --cert-file=/etc/kubernetes/pki/etcd/server.crt
      --client-cert-auth=true
      --data-dir=/var/lib/etcd
      --initial-advertise-peer-urls=https://172.31.0.7:2380
      --initial-cluster=10.110.26.178=https://172.31.0.7:2380
      --key-file=/etc/kubernetes/pki/etcd/server.key
      --listen-client-urls=https://127.0.0.1:2379,https://172.31.0.7:2379
      --listen-metrics-urls=http://127.0.0.1:2381
      --listen-peer-urls=https://172.31.0.7:2380
      --name=10.110.26.178
      --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
      --peer-client-cert-auth=true
      --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
      --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
      --snapshot-count=10000
      --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
...

$ kubectl exec -it -n kube-system etcd-10.110.26.178 -- sh

# read etcd keys
$ etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get / --prefix --keys-only

# read members
$ etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list
# read users
$ etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key user list

# DB size (The displayed size is smaller than the actual size)
$ etcdctl --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint status --write-out table
```

pod 1340      node 46
pod                                              contain                         CPU(cores)   MEMORY(bytes)
kube-apiserver-mgt01                             kube-apiserver                  690m         2971Mi
kube-apiserver-mgt02                             kube-apiserver                  384m         2038Mi
kube-apiserver-mgt03                             kube-apiserver                  223m         1726Mi
kube-controller-manager-mgt01                    kube-controller-manager         97m          782Mi
kube-controller-manager-mgt02                    kube-controller-manager         2m           28Mi
kube-controller-manager-mgt03                    kube-controller-manager         2m           29Mi
kube-scheduler-mgt01                             kube-scheduler                  6m           136Mi
kube-scheduler-mgt02                             kube-scheduler                  24m          135Mi
kube-scheduler-mgt03                             kube-scheduler                  7m           130Mi
ETCD                                                                             300m         878.7MiB
ETCD                                                                             300m         878.7MiB
ETCD                                                                             300m         878.7MiB
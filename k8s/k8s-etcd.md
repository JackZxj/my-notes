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
## get etcd metrics

```BASH
# metrics: https://etcd.io/docs/v3.5/metrics/    https://github.com/etcd-io/etcd/blob/v3.2.17/Documentation/metrics.md
curl --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key https://172.31.0.7:2379/metrics -k
# result: https://github.com/etcd-io/website/blob/main/content/en/docs/v3.5/metrics/etcd-metrics-latest.txt
```

## etcd took too long to execute

**问题**

```BASH
$ kubectl logs -n karmada-system etcd-0 --tail 100
2022-05-20 02:27:14.619465 W | etcdserver: server is likely overloaded
2022-05-20 02:27:14.619495 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 104.392067ms, to 92ead5a9687d4550)
2022-05-20 02:27:14.619508 W | etcdserver: server is likely overloaded
2022-05-20 02:27:16.374460 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 29.951166ms, to c9aaa0ccea92df19)
2022-05-20 02:27:16.374511 W | etcdserver: server is likely overloaded
2022-05-20 02:27:16.374528 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 30.050752ms, to 92ead5a9687d4550)
2022-05-20 02:27:16.374540 W | etcdserver: server is likely overloaded
2022-05-20 02:27:16.635251 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 32.518051ms, to c9aaa0ccea92df19)
2022-05-20 02:27:16.635308 W | etcdserver: server is likely overloaded
2022-05-20 02:27:16.635324 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 32.609197ms, to 92ead5a9687d4550)
2022-05-20 02:27:16.635332 W | etcdserver: server is likely overloaded
2022-05-20 02:27:21.579848 W | etcdserver: request "header:<ID:16076022003475687499 username:\"system:admin\" auth_revision:1 > txn:<compare:<target:MOD key:\"/registry/leases/karmada-system/kube-controller-manager\" mod_revision:133582 > success:<request_put:<key:\"/registry/leases/karmada-system/kube-controller-manager\" value_size:479 >> failure:<>>" with result "size:18" took too long (405.356442ms) to execute
2022-05-20 02:27:21.835482 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 223.638651ms, to c9aaa0ccea92df19)
2022-05-20 02:27:21.835549 W | etcdserver: server is likely overloaded
2022-05-20 02:27:21.835576 W | etcdserver: failed to send out heartbeat on time (exceeded the 100ms timeout for 223.750689ms, to 92ead5a9687d4550)
```

**检查etcd metric信息**

```BASH
# 正常应该大部分在 100ms 以下，即 {le="0.128"} 
$ curl --cert karmada.crt --key karmada.key https://10.151.51.54:2379/metrics -k -s| grep wal_fsync_duration_seconds
# HELP etcd_disk_wal_fsync_duration_seconds The latency distributions of fsync called by WAL.
# TYPE etcd_disk_wal_fsync_duration_seconds histogram
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.001"} 0
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.002"} 4
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.004"} 62650
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.008"} 115719
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.016"} 142864
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.032"} 150070
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.064"} 155539
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.128"} 161687
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.256"} 164030
etcd_disk_wal_fsync_duration_seconds_bucket{le="0.512"} 164382
etcd_disk_wal_fsync_duration_seconds_bucket{le="1.024"} 164501
etcd_disk_wal_fsync_duration_seconds_bucket{le="2.048"} 164528
etcd_disk_wal_fsync_duration_seconds_bucket{le="4.096"} 164541
etcd_disk_wal_fsync_duration_seconds_bucket{le="8.192"} 164553
etcd_disk_wal_fsync_duration_seconds_bucket{le="+Inf"} 164575
etcd_disk_wal_fsync_duration_seconds_sum 2742.7531894699846
etcd_disk_wal_fsync_duration_seconds_count 164575

# 正常应该大部分在 100ms 以下，即  {le="0.128"} 
$ curl --cert karmada.crt --key karmada.key https://10.151.51.54:2379/metrics -k -s| grep backend_commit_duration_seconds
# HELP etcd_disk_backend_commit_duration_seconds The latency distributions of commit called by backend.
# TYPE etcd_disk_backend_commit_duration_seconds histogram
etcd_disk_backend_commit_duration_seconds_bucket{le="0.001"} 0
etcd_disk_backend_commit_duration_seconds_bucket{le="0.002"} 0
etcd_disk_backend_commit_duration_seconds_bucket{le="0.004"} 0
etcd_disk_backend_commit_duration_seconds_bucket{le="0.008"} 16227
etcd_disk_backend_commit_duration_seconds_bucket{le="0.016"} 90603
etcd_disk_backend_commit_duration_seconds_bucket{le="0.032"} 110484
etcd_disk_backend_commit_duration_seconds_bucket{le="0.064"} 117185
etcd_disk_backend_commit_duration_seconds_bucket{le="0.128"} 122358
etcd_disk_backend_commit_duration_seconds_bucket{le="0.256"} 125465
etcd_disk_backend_commit_duration_seconds_bucket{le="0.512"} 125948
etcd_disk_backend_commit_duration_seconds_bucket{le="1.024"} 126107
etcd_disk_backend_commit_duration_seconds_bucket{le="2.048"} 126156
etcd_disk_backend_commit_duration_seconds_bucket{le="4.096"} 126164
etcd_disk_backend_commit_duration_seconds_bucket{le="8.192"} 126169
etcd_disk_backend_commit_duration_seconds_bucket{le="+Inf"} 126183
etcd_disk_backend_commit_duration_seconds_sum 3211.4428439529324
etcd_disk_backend_commit_duration_seconds_count 126183
```

**检查磁盘延迟**

ref: https://www.ibm.com/cloud/blog/using-fio-to-tell-whether-your-storage-is-fast-enough-for-etcd

参考延迟:  etcd 文档建议 wal_fsync_duration_seconds 的第 99 个百分位应小于 10 毫秒，这样存储才能被认为足够快。

```BASH
# 需要 fio version >= 3.5
$ fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
...
fsync/fdatasync/sync_file_range:
  sync (usec): min=534, max=15766, avg=1273.08, stdev=1084.70
  sync percentiles (usec):
   | 1.00th=[ 553], 5.00th=[ 578], 10.00th=[ 594], 20.00th=[ 627],
   | 30.00th=[ 709], 40.00th=[ 750], 50.00th=[ 783], 60.00th=[ 1549],
   | 70.00th=[ 1729], 80.00th=[ 1991], 90.00th=[ 2180], 95.00th=[ 2278],
   | 99.00th=[ 2376], 99.50th=[ 9634], 99.90th=[15795], 99.95th=[15795],
   | 99.99th=[15795]
...
```

# test crun on arm64

## test on ruichi box (failed: statfs '/sys/fs/cgroup': No such file or directory)

```BASH
# install
$ wget https://github.com/containers/crun/releases/download/1.7/crun-1.7-linux-arm64-disable-systemd
$ chmod +x crun-1.7-linux-arm64-disable-systemd
$ mv crun-1.7-linux-arm64-disable-systemd /usr/local/bin/crun
$ crun -v
crun version 1.7
commit: 40d996ea8a827981895ce22886a9bac367f87264
rundir: /run/crun
spec: 1.0.0
+SELINUX +APPARMOR +CAP +SECCOMP +EBPF +YAJL

# test
# on a centos7
# install tools:
$ yum install -y skopeo
$ wget https://github.com/opencontainers/umoci/releases/download/v0.4.7/umoci.amd64
$ chmod +x umoci.amd64
$ mv umoci.amd64 /usr/local/bin/umoci
# change docker image to OCI image
$ skopeo copy docker://********/ocm-core-api-arm64:1.2.4 oci:ocm:1.2.4
# unpack oci image to path "ocm-arm"
$ umoci unpack  --image ocm:1.2.4 ocm-arm
# tar
$ tar -cvf  ocm-arm.tar ocm-arm/
$ sha256sum ocm-arm.tar
28e6f0a4c1c518e2c591a89a34b6553fcc0f2e6026dd31731dc839c4eb080eb9  ocm-arm.tar
# copy to ruichi
$ scp ocm-arm.tar root@196.222.222.200:

# on ruichi
$ sha256sum  ocm-arm.tar
28e6f0a4c1c518e2c591a89a34b6553fcc0f2e6026dd31731dc839c4eb080eb9  ocm-arm.tar
$ tar -xvf ocm-arm.tar
$ cd ocm-arm/
$ ls
config.json                                                                    sha256_5983dbb40539a27a8e4a08ab8b8c13f0739a8f2ee2c0c679acd29e62977f707f.mtree
rootfs                                                                         umoci.json
# run image
# expect: https://blog.csdn.net/adream307/article/details/115267425
$ crun run bash
2018-01-09T06:42:22.000551347Z: statfs '/sys/fs/cgroup': No such file or directory
```


## test on raspberry pi4

```BASH
# install tools for building crun with wasmedge
$ sudo apt-get install -y make git gcc build-essential pkgconf libtool \
   libsystemd-dev libprotobuf-c-dev libcap-dev libseccomp-dev libyajl-dev \
   libgcrypt20-dev go-md2man autoconf python3 automake

# install wasmedge library
# we dont need WasmEdge-image and WasmEdge-tensorflow-deps now, so it's ok
$ curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -p /usr/local # install wasmedge for all user
fatal: unable to access 'https://github.com/second-state/WasmEdge-image.git/': GnuTLS recv error (-110): The TLS connection was non-properly terminated.
fatal: unable to access 'https://github.com/second-state/WasmEdge-tensorflow-deps.git/': GnuTLS recv error (-110): The TLS connection was non-properly terminated.
Detected Linux-aarch64
WasmEdge Installation at /usr/local
Fetching WasmEdge-0.11.2
/tmp/wasmedge.384285 ~/crun
######################################################################## 100.0%
~/crun
Installing WasmEdge-0.11.2-Linux in /usr/local/include
Installing WasmEdge-0.11.2-Linux in /usr/local/lib
Installing WasmEdge-0.11.2-Linux in /usr/local/bin
var? wasmedge
0.11.2 0.11.2
Installation of wasmedge-0.11.2 successfull 
var? wasmedgec
0.11.2 0.11.2
Installation of wasmedgec-0.11.2 successfull
WasmEdge binaries accessible

# clone crun repo
$ git clone https://github.com/containers/crun.git 
$ cd crun
$ git checkout 1.7
$ git status
HEAD detached at 1.7
nothing to commit, working tree clean

# install crun with wasmegde support
$ ./autogen.sh
$ ./configure --with-wasmedge   # enable wasmedge
$ make
$ sudo make install
$ crun --version
crun version 1.7
commit: 40d996ea8a827981895ce22886a9bac367f87264
rundir: /run/user/0/crun
spec: 1.0.0
+SYSTEMD +SELINUX +APPARMOR +CAP +SECCOMP +EBPF +WASM:wasmedge +YAJL


# test crun container
$ cd ~
$ scp root@196.222.222.200:ocm-arm.tar .
$ sha256sum ocm-arm.tar
28e6f0a4c1c518e2c591a89a34b6553fcc0f2e6026dd31731dc839c4eb080eb9  ocm-arm.tar
$ cd ocm-arm/
$ ls
config.json                                                                    sha256_5983dbb40539a27a8e4a08ab8b8c13f0739a8f2ee2c0c679acd29e62977f707f.mtree
rootfs                                                                         umoci.json
$ crun run bash
2022/11/16 02:16:37 log4go init done with:
/var/log/ocm/ocm.log
{"filename":"/var/log/ocm/ocm.log","maxlines":0,"maxsize":10000000,"daily":true,"rotate":true,"maxdays":15,"separate":[ "error" ]}
logs.BeeLogger.SetLogger: open /var/log/ocm/ocm.log: permission denied
Could Not Open auditLog File : open /ocm/ocm/audit.log: no such file or directory

# test crun with docker
# add crun support for docker
$ vi /etc/docker/daemon.json
...
  "default-runtime": "runc",
  "runtimes": {
    "crun": {
      "path": "/usr/local/bin/crun"
    }
  },
...
$ systemctl restart docker
$ docker info | grep Runtime
 Runtimes: crun io.containerd.runc.v2 io.containerd.runtime.v1.linux runc
 Default Runtime: runc
$ docker run --runtime crun --name crun-nginx -d -p 10080:80 nginx:stable-alpine
8302c24796ee77102f9792f783aa2156d3ab088df572499fabcf1c3540ab3d9a
$ docker inspect crun-nginx | grep Runtime
            "Runtime": "crun",
            "CpuRealtimeRuntime": 0,
$ curl 127.0.0.1:10080
<!DOCTYPE html>
...

# install buildah and podman
# ref: https://fabianlee.org/2022/08/02/buildah-installing-buildah-and-podman-on-ubuntu-20-04/
$ sudo apt-get update
$ sudo apt-get install -y wget ca-certificates gnupg2
# add repo and signing key
$ . /etc/os-release
$ echo $VERSION_ID
20.04
$ echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list
$ curl -Ls https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_$VERSION_ID/Release.key | sudo apt-key add -
$ sudo apt-get update
$ sudo apt install buildah podman -y
# fix known issue 11745 with [machine] entry
$ sudo sed -i 's/^\[machine\]$/#\[machine\]/' /usr/share/containers/containers.conf
$ buildah version
Version:         1.22.3
Go Version:      go1.15.2
Image Spec:      1.0.1-dev
Runtime Spec:    1.0.2-dev
CNI Spec:        0.4.0
libcni Version:
image Version:   5.15.2
Git Commit:
Built:           Thu Jan  1 08:00:00 1970
OS/Arch:         linux/arm64
$ podman version
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
Version:      3.4.2
API Version:  3.4.2
Go Version:   go1.15.2
Built:        Thu Jan  1 08:00:00 1970
OS/Arch:      linux/arm64

# build a wasmedge image
$ mkdir ~/wasmedge-img && cd ~/wasmedge-img 
$ scp root@196.222.222.200:jack/wasm-files/*.wasm .
$ ls
fib.wasm  generic.wasm  hello.wasm  main.wasm
$ vi Dockerfile
FROM scratch
COPY fib.wasm /
CMD ["/fib.wasm"]
$ buildah bud --annotation "module.wasm.image/variant=compat" -t fib-wasm .
$ buildah images
REPOSITORY           TAG      IMAGE ID       CREATED              SIZE
localhost/fib-wasm   latest   bf6152e6674f   About a minute ago   61.3 KB
$ podman images
REPOSITORY           TAG      IMAGE ID       CREATED              SIZE
localhost/fib-wasm   latest   bf6152e6674f   About a minute ago   61.3 KB

# update podman crun conf
$ vi /usr/share/containers/containers.conf
...
# Paths to look for a valid OCI runtime (crun, runc, kata, runsc, krun, etc)
[engine.runtimes]
crun = [
  "/usr/local/bin/crun",
]
...
$ podman info | grep ociRuntime -A 10
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
  ociRuntime:
    name: crun
    package: Unknown
    path: /usr/local/bin/crun
    version: |-
      crun version 1.7
      commit: 40d996ea8a827981895ce22886a9bac367f87264
      rundir: /run/user/0/crun
      spec: 1.0.0
      +SYSTEMD +SELINUX +APPARMOR +CAP +SECCOMP +EBPF +WASM:wasmedge +YAJL
  os: linux
$ podman run localhost/fib-wasm
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
Hello TinyGo from WasmEdge!
# not work
$ podman run -i localhost/fib-wasm fib.wasm fibArray 10
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
Hello TinyGo from WasmEdge!
```

### args test

```Go
// main.go
package main

import (
	"fmt"
	"os"
	"strconv"
)

func main() {
	if len(os.Args) < 2 {
		panic("you should input at least  1 args, such as -1 0 1 2 3")
	}
	var ans int
	for i, arg := range os.Args {
		if i == 0 {
			continue
		}
		v, err := strconv.Atoi(arg)
		if err != nil {
			panic("args should be numbers")
		}
		ans += v
	}
	fmt.Println("count sum:",ans)
}
```

```BASH
$ tinygo build -o sum.wasm -target wasi main.go
$ wasmedgec sum.wasm sumAOT.wasm
$ wasmedge sum.wasm 1 2 4
count sum: 7
$ wasmedge sumAOT.wasm 12 3
count sum: 15
$ vi Dockerfile
FROM scratch
COPY sum.wasm /
CMD ["/sum.wasm"]
$ buildah bud --annotation "module.wasm.image/variant=compat" -t sum-wasm .
$ vi Dockerfile
FROM scratch
COPY sumAOT.wasm /
CMD ["/sumAOT.wasm"]
$ buildah bud --annotation "module.wasm.image/variant=compat" -t sum-aot-wasm .
$ podman run localhost/sum-wasm sum.wasm 1 2 3
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
count sum: 6

$ podman run localhost/sum-aot-wasm sumAOT.wasm 1 2 3 -1 -2 -5
WARN[0000] Error validating CNI config file /etc/cni/net.d/10-flannel.conflist: [failed to find plugin "flannel" in path [/usr/local/libexec/cni /usr/libexec/cni /usr/local/lib/cni /usr/lib/cni /opt/cni/bin]]
count sum: -2
```

### test crun-wasmedge with docker (failed: not supported)

```BASH
# run crun with docker
# path of docker image was not the same as crun, so we need a registry to convert it
$ docker run -d -p 5000:5000 --restart always --name registry registry:2.8.1
$ buildah push --tls-verify=false localhost/fib-wasm docker://localhost:5000/fib-wasm:latest # need --tls-verify=false to use http push
$ docker pull localhost:5000/fib-wasm:latest
$ docker images | grep fib
localhost:5000/fib-wasm                                latest          bf6152e6674f   18 hours ago   58.2kB

# fib.wasm is not an executable
$ docker run --runtime crun --label module.wasm.image/variant=compat-smart localhost:5000/fib-wasm
docker: Error response from daemon: failed to create shim task: OCI runtime create failed: open executable: Permission denied: unknown.
ERRO[0002] error waiting for container: context canceled

# sum.wasm is an executable
$ buildah push --tls-verify=false localhost/sum-wasm docker://localhost:5000/sum-wasm:latest
$ docker run --runtime crun --label module.wasm.image/variant=compat-smart localhost:5000/sum-wasm:latest
{"msg":"exec container process `/sum.wasm`: Exec format error","level":"error","time":"2022-11-17T01:42:55.000941255Z"}

$ ls -lh ~/wasmedge-img
ls -lh
total 1.3M
-rw-r--r-- 1 root root   53 11月 16 17:38 Dockerfile
-rw-r--r-- 1 root root  57K 11月 16 15:22 fib.wasm
-rw-r--r-- 1 root root  16K 11月 16 15:22 generic.wasm
-rw-r--r-- 1 root root  56K 11月 16 15:22 hello.wasm
-rw-r--r-- 1 root root  363 11月 16 17:33 main.go
-rw-r--r-- 1 root root  57K 11月 16 15:22 main.wasm
-rw-r--r-- 1 root root 704K 11月 16 17:36 sumAOT.wasm
-rwxr-xr-x 1 root root 411K 11月 16 17:34 sum.wasm

```

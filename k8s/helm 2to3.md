# Upgrade Helm2 to Helm3

> ref:
> - https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/ 
> - https://www.jianshu.com/p/08f2a82f0756

``` BASH
$ helm version
Client: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.14.2", GitCommit:"a8b13cc5ab6a7dbef0a58f5061bcc7c0c61598e7", GitTreeState:"clean"}

$ wget https://get.helm.sh/helm-v3.4.1-linux-amd64.tar.gz
$ sha256sum helm-v3.4.1-linux-amd64.tar.gz
$ tar -zxf helm-v3.4.1-linux-amd64.tar.gz
$ mv linux-amd64/helm /usr/bin/helm3 && rm -rf linux-amd64
$ helm3 version
version.BuildInfo{Version:"v3.4.1", GitCommit:"c4e74854886b2efe3321e185578e6db9be0a6e29", GitTreeState:"clean", GoVersion:"go1.14.11"}
$ helm3 plugin install https://github.com/helm/helm-2to3
$ helm3 2to3 move config
$ helm list
$ helm3 2to3 convert <release-name>
$ helm3 list -A     # check status
$ helm3 repo update
########################### recommend ###########################
$ helm3 2to3 cleanup
$ rm `which helm` # remove Helm2
$ mv /usr/bin/helm3 /usr/bin/helm
$ helm version
version.BuildInfo{Version:"v3.4.1", GitCommit:"c4e74854886b2efe3321e185578e6db9be0a6e29", GitTreeState:"clean", GoVersion:"go1.14.11"}
```

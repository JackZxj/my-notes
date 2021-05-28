# operator-lifecycle-manager

**OLM:** 通过将Operator的CRD、RBAC、controller Deployment信息统一打包为一个镜像，从而实现将Operator的存储、管理、运行进行统一的管理。

本文档为试用记录，详情请参考

> https://olm.operatorframework.io/docs/

## cli 安装

```BASH
# 安装工具
$ export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac) 
$ export OS=$(uname | awk '{print tolower($0)}') 
$ export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.7.2 
$ curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH} 
$ chmod +x operator-sdk_${OS}_${ARCH} && sudo mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk 

# 检查是否正常
$ operator-sdk version
operator-sdk version: "v1.7.2", commit: "6db9787d4e9ff63f344e23bfa387133112bda56b", kubernetes version: "1.19.4", go version: "go1.15.5", GOOS: "linux", GOARCH: "amd64"

# 安装 olm 
$ operator-sdk olm install
# 网络不行的话手动部署应该也可以
# https://github.com/operator-framework/operator-lifecycle-manager/releases
$ operator-sdk olm status
INFO[0000] Fetching CRDs for version "0.18.1"
INFO[0000] Fetching resources for resolved version "v0.18.1"
INFO[0004] Successfully got OLM status for version "0.18.1"
...
```

## sdk 构建的 CRD 直接转化

参考: 

* [operator-from-0-to-1.md](./operator-from-0-to-1.md)
* [样例仓库](https://github.com/JackZxj/operator-demo-sdk)

```BASH
# 构建
$ make bundle
# 打包
$ make bundle-build BUNDLE_IMG=172.31.0.7:5000/test.io/operator-demo-sdk-bundle:v0.0.1
# 上传到镜像仓库
# （测试发现必须上传到镜像仓库，即使在本地也得上传。。）
# 不支持非https的registry:
# https://github.com/operator-framework/operator-sdk/issues/4840
# 
# 下面的没有走通
# 
# $ make bundle-push BUNDLE_IMG=172.31.0.7:5000/test.io/operator-demo-sdk-bundle:v0.0.1
# # 部署
# $ operator-sdk run bundle 172.31.0.7:5000/test.io/operator-demo-sdk-bundle:v0.0.1
```

## 手动构建 operator manifest

~~为 Sample CRD 创建一个元数据~~由于配置过于复杂，以及镜像仓库原因，暂时没有成功过

## 评价

**优点：**
1．	用Operator SDK构建的Operator十分容易就能打包
2．	以镜像的方式存储Operator，无需额外的存储负担
3．	提供了订阅的功能，支持自动更新Operator或者手动更新Operator
4．	官方提供Operator镜像社区，有一些比较常用的operator支持本项目
5．	提供了基于Namespace的Operator隔离（需要Operator本身支持Namespace的隔离）

**缺点：**
1.	目前尚处于早期版本，可能还会有变动（目前逐步废弃packagemanifests转向bundle格式，具体两种格式有什么区别没有细研究）
2.	支持的配置多，手动构建Operator包所需的配置较为复杂
3.	Operator镜像包目前不支持存储到非tls的仓库
4.	官方的镜像Operator仓库数量较少（目前仅190+），其中还有好多是废弃的、长时间未更新的

**个人评价:** 对Operator生命周期的控制提供了一个基于k8s的管理方式，但是对于非OperatorSDK实现的Operator来说，较为复杂的配置提高了上手的门槛。个人认为对于私有集群、Operator数量较少、或者有很多自己开发的Operator的集群来说，添加OLM并没有带来实质上的好处。而对于公有集群来说，如果集群运营商提供了很多便捷的Operator功能，这些Operator是支持多租户隔离的，那么通过OLM可以较好地进行管理、分发。

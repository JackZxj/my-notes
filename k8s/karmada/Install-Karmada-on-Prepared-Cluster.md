# Install Karmada on Prepared Cluster

ref:
- https://github.com/karmada-io/karmada#32-i-have-present-cluster-for-installing
- https://kind.sigs.k8s.io/docs/user/loadbalancer/

## prepare cluster

```BASH
# create a cluster as karmada control plane
$ kind create cluster --name cluster0 --image kindest/node:v1.20.2 --kubeconfig karmada/cluster0.config
# rename context
$ kubectl config rename-context kind-cluster0 cluster0 --kubeconfig karmada/cluster0.config
# prepare metallb for external IP
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
$ kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
$ docker pull metallb/speaker:main
$ docker tag metallb/speaker:main quay.io/metallb/speaker:main
$ kind load docker-image quay.io/metallb/speaker:main --name cluster0
$ docker pull metallb/controller:main
$ docker tag metallb/controller:main quay.io/metallb/controller:main
$ kind load docker-image quay.io/metallb/controller:main --name cluster0

# Wait for all pods to be ready
$ docker network inspect -f '{{.IPAM.Config}}' kind
[{172.19.0.0/16  172.19.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
# metallb-configmap.yaml using IP 172.19.255.200-172.19.255.250
$ kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml
```

## install karmada control plane

```BASH
# prepare images
$ kind load docker-image k8s.gcr.io/kube-apiserver:v1.19.1 --name cluster0
$ kind load docker-image swr.ap-southeast-1.myhuaweicloud.com/karmada/karmada-controller-manager --name cluster0
$ kind load docker-image swr.ap-southeast-1.myhuaweicloud.com/karmada/karmada-karmada-scheduler --name cluster0
$ kind load docker-image swr.ap-southeast-1.myhuaweicloud.com/karmada/karmada-webhook --name cluster0
$ kind load docker-image k8s.gcr.io/kube-controller-manager:v1.19.1 --name cluster0

# install
$ cd $GOPATH/src/github.com/karmada-io/karmada
$ hack/remote-up-karmada.sh ~/karmada/cluster0.config cluster0

# # If failed
# $ kubectl config get-contexts
# CURRENT   NAME                CLUSTER             AUTHINFO            NAMESPACE
#           cluster0            kind-cluster0       kind-cluster0
# *         karmada-apiserver   karmada-apiserver   karmada-apiserver
# $ kubectl config use-context cluster0
# $ kubectl delete ns karmada-system
# $ kubectl config delete-context karmada-apiserver
# # And then reinstall 
# $ hack/remote-up-karmada.sh ~/karmada/cluster0.config cluster0
```

## manage clusters by pull

所需文件：

- control plane kubeconfig
- artifacts/agent/namespace.yaml
- artifacts/agent/serviceaccount.yaml
- artifacts/agent/clusterrole.yaml
- artifacts/agent/clusterrolebinding.yaml
- artifacts/agent/karmada-agent.yaml **(需要替换占位符)**
- swr.ap-southeast-1.myhuaweicloud.com/karmada/karmada-agent:latest **(镜像名依据 karmada-agent.yaml 确定)**

### join cluster

安装示例：

```BASH
# create cluster
$ kind create cluster --name cluster4 --image kindest/node:v1.20.2 --kubeconfig /root/karmada/cluster4.config
$ kubectl config rename-context kind-cluster4 cluster4 --kubeconfig /root/karmada/cluster4.config
$ kind load docker-image swr.ap-southeast-1.myhuaweicloud.com/karmada/karmada-agent --name cluster4

# env
$ REPO_ROOT=$GOPATH/src/github.com/karmada-io/karmada
$ KARMADA_APISERVER_CONTEXT_NAME=karmada-apiserver
$ MEMBER_CLUSTER_NAME=cluster4
$ KARMADA_APISERVER_KUBECONFIG="/root/karmada/cluster0.config"
$ KARMADA_SYSTEM_NAMESPACE=karmada-system
$ AGENT_IMAGE_PULL_POLICY=IfNotPresent

$ export KUBECONFIG="/root/karmada/cluster4.config"
$ kubectl config use-context karmada-apiserver --kubeconfig="${KARMADA_APISERVER_KUBECONFIG}"
$ kubectl config use-context "${MEMBER_CLUSTER_NAME}"

# create namespace for karmada agent
$ kubectl apply -f "${REPO_ROOT}/artifacts/agent/namespace.yaml"

# create service account, cluster role for karmada agent
$ kubectl apply -f "${REPO_ROOT}/artifacts/agent/serviceaccount.yaml"
$ kubectl apply -f "${REPO_ROOT}/artifacts/agent/clusterrole.yaml"
$ kubectl apply -f "${REPO_ROOT}/artifacts/agent/clusterrolebinding.yaml"

# create secret
$ kubectl create secret generic karmada-kubeconfig --from-file=karmada-kubeconfig="${KARMADA_APISERVER_KUBECONFIG}" -n "${KARMADA_SYSTEM_NAMESPACE}"

# deploy karmada agent
$ TEMP_PATH=$(mktemp -d)
$ cp "${REPO_ROOT}"/artifacts/agent/karmada-agent.yaml "${TEMP_PATH}"/karmada-agent.yaml
$ sed -i'' -e "s/{{karmada_context}}/${KARMADA_APISERVER_CONTEXT_NAME}/g" "${TEMP_PATH}"/karmada-agent.yaml
$ sed -i'' -e "s/{{member_cluster_name}}/${MEMBER_CLUSTER_NAME}/g" "${TEMP_PATH}"/karmada-agent.yaml
$ sed -i'' -e "s/{{image_pull_policy}}/${AGENT_IMAGE_PULL_POLICY}/g" "${TEMP_PATH}"/karmada-agent.yaml
$ echo -e "Apply dynamic rendered deployment in ${TEMP_PATH}/karmada-agent.yaml.\n"
$ kubectl apply -f "${TEMP_PATH}"/karmada-agent.yaml

# clean temp files
# $ rm -rf $TEMP_PATH
```

### unjoin cluster

```BASH
# on cluster
$ export KUBECONFIG="/root/karmada/cluster4.config"
$ kubectl delete ns karmada-system
$ kubectl delete clusterrolebinding karmada-agent
$ kubectl delete clusterrole karmada-agent
# $ kubectl delete ns $USER_NAMESPACE       # optional

# on control plane
$ MEMBER_CLUSTER_NAME=cluster4
$ kubectl delete cluster $MEMBER_CLUSTER_NAME
```

## manage clusters by push

所需文件：

- karmadactl
- control plane kubeconfig
- cluster kubeconfig

### join

```BASH
#  on cluster (optional, because this cluster was created by kind)

# env
$ MEMBER_CLUSTER_NAME=cluster4
$ CLUSTER_KUBECONFIG="/root/karmada/cluster4.config"

# Kind cluster uses `127.0.0.1` as kube-apiserver endpoint by default, thus kind clusters can't reach each other.
# So we need to update endpoint with container IP.
$ container_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${MEMBER_CLUSTER_NAME}-control-plane")
$ kubectl config set-cluster "kind-${MEMBER_CLUSTER_NAME}" --server="https://${container_ip}:6443" --kubeconfig="${CLUSTER_KUBECONFIG}"
# copy $CLUSTER_KUBECONFIG to control plane


# on control plane

# env
$ MEMBER_CLUSTER_NAME=cluster4
$ KARMADA_APISERVER_KUBECONFIG="/root/karmada/cluster0.config"
$ CLUSTER_KUBECONFIG="/root/karmada/cluster4.config"

# join cluster
$ export KUBECONFIG="${KARMADA_APISERVER_KUBECONFIG}"
$ kubectl config use-context karmada-apiserver
$ karmadactl join ${MEMBER_CLUSTER_NAME} --cluster-kubeconfig=$CLUSTER_KUBECONFIG
```

### unjoin

```BASH
# on control plane

# env
$ MEMBER_CLUSTER_NAME=cluster4
$ KARMADA_APISERVER_KUBECONFIG="/root/karmada/cluster0.config"
$ CLUSTER_KUBECONFIG="/root/karmada/cluster4.config"

# unjoin
$ export KUBECONFIG="${KARMADA_APISERVER_KUBECONFIG}"
$ kubectl config use-context karmada-apiserver
$ karmadactl unjoin ${MEMBER_CLUSTER_NAME} --cluster-kubeconfig=$CLUSTER_KUBECONFIG
```

MEMBER_CLUSTER_NAME=cluster5
KARMADA_APISERVER_KUBECONFIG="/root/karmada/cluster0.config"
CLUSTER_KUBECONFIG="/root/karmada/cluster5.config"

export KUBECONFIG="${KARMADA_APISERVER_KUBECONFIG}"
kubectl config use-context karmada-apiserver
karmadactl join ${MEMBER_CLUSTER_NAME} --cluster-kubeconfig=$CLUSTER_KUBECONFIG
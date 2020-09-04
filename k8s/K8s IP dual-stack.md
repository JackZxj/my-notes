kubectl edit daemonset.apps/kube-proxy -n kube-system

``` BASH
kubectl proxy --port=8001 &

NODE_NAME="192.168.154.3"; curl -sSL "http://localhost:8001/api/v1/nodes/${NODE_NAME}/proxy/configz" | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' > kubelet_configz_${NODE_NAME}
```

``` json
{"kubeletconfig":{"staticPodPath":"/etc/kubernetes/manifests","syncFrequency":"1m0s","fileCheckFrequency":"20s","httpCheckFrequency":"20s","address":"0.0.0.0","port":10250,"tlsCertFile":"/var/lib/kubelet/pki/kubelet.crt","tlsPrivateKeyFile":"/var/lib/kubelet/pki/kubelet.key","rotateCertificates":true,"authentication":{"x509":{"clientCAFile":"/etc/kubernetes/pki/ca.crt"},"webhook":{"enabled":true,"cacheTTL":"2m0s"},"anonymous":{"enabled":false}},"authorization":{"mode":"Webhook","webhook":{"cacheAuthorizedTTL":"5m0s","cacheUnauthorizedTTL":"30s"}},"registryPullQPS":5,"registryBurst":10,"eventRecordQPS":5,"eventBurst":10,"enableDebuggingHandlers":true,"healthzPort":10248,"healthzBindAddress":"127.0.0.1","oomScoreAdj":-999,"clusterDomain":"cluster.local","clusterDNS":["10.96.0.10"],"streamingConnectionIdleTimeout":"4h0m0s","nodeStatusUpdateFrequency":"10s","nodeStatusReportFrequency":"1m0s","nodeLeaseDurationSeconds":40,"imageMinimumGCAge":"2m0s","imageGCHighThresholdPercent":85,"imageGCLowThresholdPercent":80,"volumeStatsAggPeriod":"1m0s","cgroupsPerQOS":true,"cgroupDriver":"cgroupfs","cpuManagerPolicy":"none","cpuManagerReconcilePeriod":"10s","topologyManagerPolicy":"none","runtimeRequestTimeout":"2m0s","hairpinMode":"promiscuous-bridge","maxPods":110,"podPidsLimit":-1,"resolvConf":"/etc/resolv.conf","cpuCFSQuota":true,"cpuCFSQuotaPeriod":"100ms","maxOpenFiles":1000000,"contentType":"application/vnd.kubernetes.protobuf","kubeAPIQPS":5,"kubeAPIBurst":10,"serializeImagePulls":true,"evictionHard":{"imagefs.available":"15%","memory.available":"100Mi","nodefs.available":"10%","nodefs.inodesFree":"5%"},"evictionPressureTransitionPeriod":"5m0s","enableControllerAttachDetach":true,"makeIPTablesUtilChains":true,"iptablesMasqueradeBit":14,"iptablesDropBit":15,"failSwapOn":true,"containerLogMaxSize":"10Mi","containerLogMaxFiles":5,"configMapAndSecretChangeDetectionStrategy":"Watch","enforceNodeAllocatable":["pods"]}}
```

```yml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-controller-manager
    tier: control-plane
  name: kube-controller-manager
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-controller-manager
    - --feature-gates=IPv6DualStack=true
    - --allocate-node-cidrs=true
    - --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --bind-address=127.0.0.1
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --cluster-cidr=192.168.0.0/16,fd00::/48
    - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
    - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
    - --controllers=*,bootstrapsigner,tokencleaner
    - --kubeconfig=/etc/kubernetes/controller-manager.conf
    - --leader-elect=true
    - --node-cidr-mask-size-ipv4=24
    - --node-cidr-mask-size-ipv6
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --root-ca-file=/etc/kubernetes/pki/ca.crt
    - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=10.244.0.0/16,fc00::/24
    - --use-service-account-credentials=true
    image: registry.aliyuncs.com/google_containers/kube-controller-manager:v1.16.0
    imagePullPolicy: IfNotPresent
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: 127.0.0.1
        path: /healthz
        port: 10252
        scheme: HTTP
      initialDelaySeconds: 15
      timeoutSeconds: 15
    name: kube-controller-manager
    resources:
      requests:
        cpu: 200m
    volumeMounts:
    - mountPath: /etc/ssl/certs
      name: ca-certs
      readOnly: true
    - mountPath: /etc/pki
      name: etc-pki
      readOnly: true
    - mountPath: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      name: flexvolume-dir
    - mountPath: /etc/kubernetes/pki
      name: k8s-certs
      readOnly: true
    - mountPath: /etc/kubernetes/controller-manager.conf
      name: kubeconfig
      readOnly: true
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /etc/ssl/certs
      type: DirectoryOrCreate
    name: ca-certs
  - hostPath:
      path: /etc/pki
      type: DirectoryOrCreate
    name: etc-pki
  - hostPath:
      path: /usr/libexec/kubernetes/kubelet-plugins/volume/exec
      type: DirectoryOrCreate
    name: flexvolume-dir
  - hostPath:
      path: /etc/kubernetes/pki
      type: DirectoryOrCreate
    name: k8s-certs
  - hostPath:
      path: /etc/kubernetes/controller-manager.conf
      type: FileOrCreate
    name: kubeconfig
status: {}

```


## dual stack

### enable ipvs
``` BASH
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF

systemctl daemon-reload
```


### install k8s
``` yml 
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
networking:
  podSubnet: "192.168.0.0/16,fd00::/48"
kubernetesVersion: "v1.16.0"
controlPlaneEndpoint: "192.168.154.3:6443"
apiServer:
  extraArgs:
    authorization-mode: "Node,RBAC"
  timeoutForControlPlane: 4m0s
controllerManager:
  extraArgs:
    cluster-cidr: "192.168.0.0/16,fd00::/24"
    service-cluster-ip-range: "10.244.0.0/16,fc00::/24"
imageRepository: "registry.aliyuncs.com/google_containers"
featureGates: 
  IPv6DualStack: true
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
# kubelet specific options here
featureGates: 
  IPv6DualStack: true
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
# kube-proxy specific options here
clusterCIDR: "192.168.0.0/16,fd00::/48"
featureGates: 
  IPv6DualStack: true
```
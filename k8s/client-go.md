# client-go

## client-go 输出日志

```Go
package main

import (
	"context"
	"flag"
	"fmt"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/klog/v2"
)

func main() {
	klog.InitFlags(nil) // initializing the flags
	defer klog.Flush()  // flushes all pending log I/O

	flag.Parse() // parses the command-line flags

	config, err := clientcmd.BuildConfigFromFlags("", "/root/.kube/config")
	if err != nil {
		panic(err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	s, err := clientset.CoreV1().Services("default").Get(context.TODO(), "kubernetes", metav1.GetOptions{})
	if err != nil {
		panic(err)
	}
	// 获取出来的 service 缺少 TypeMeta 属性需要注意，这是 client-go 的一个 bug，官方截至 k8s v1.22 还未修复,
	// 社区挂了若干 issue，有人在解决但没有合入代码。
	// 大部分情况下不影响使用，小部分情况可能会有问题，如需要配置 OwnerReference 时
	fmt.Printf("svc with empty TypeMeta:\n%+v\n", *s)
}
```

```BASH
$ go run main.go -v 6
I0422 10:23:36.781873 2275461 loader.go:372] Config loaded from file:  /root/.kube/config
I0422 10:23:36.804920 2275461 round_trippers.go:454] GET https://127.0.0.1:26443/api/v1/namespaces/default/services/kubernetes 200 OK in 21 milliseconds
svc with empty TypeMeta:
{TypeMeta:{Kind: APIVersion:} ObjectMeta:{Name:kubernetes GenerateName: Namespace:default SelfLink: UID:ab471977-d1ef-46bb-82b2-05ef20a97592 ResourceVersion:195 Generation:0 CreationTimestamp:2022-04-20 15:26:36 +0800 CST DeletionTimestamp:<nil> DeletionGracePeriodSeconds:<nil> Labels:map[component:apiserver provider:kubernetes] Annotations:map[] OwnerReferences:[] Finalizers:[] ClusterName: ManagedFields:[{Manager:kube-apiserver Operation:Update APIVersion:v1 Time:2022-04-20 15:26:36 +0800 CST FieldsType:FieldsV1 FieldsV1:{"f:metadata":{"f:labels":{".":{},"f:component":{},"f:provider":{}}},"f:spec":{"f:clusterIP":{},"f:internalTrafficPolicy":{},"f:ipFamilyPolicy":{},"f:ports":{".":{},"k:{\"port\":443,\"protocol\":\"TCP\"}":{".":{},"f:name":{},"f:port":{},"f:protocol":{},"f:targetPort":{}}},"f:sessionAffinity":{},"f:type":{}}} Subresource:}]} Spec:{Ports:[{Name:https Protocol:TCP AppProtocol:<nil> Port:443 TargetPort:{Type:0 IntVal:6443 StrVal:} NodePort:0}] Selector:map[] ClusterIP:10.96.0.1 ClusterIPs:[10.96.0.1] Type:ClusterIP ExternalIPs:[] SessionAffinity:None LoadBalancerIP: LoadBalancerSourceRanges:[] ExternalName: ExternalTrafficPolicy: HealthCheckNodePort:0 PublishNotReadyAddresses:false SessionAffinityConfig:nil IPFamilies:[IPv4] IPFamilyPolicy:0xc000080050 AllocateLoadBalancerNodePorts:<nil> LoadBalancerClass:<nil> InternalTrafficPolicy:0xc000080060} Status:{LoadBalancer:{Ingress:[]} Conditions:[]}}
```

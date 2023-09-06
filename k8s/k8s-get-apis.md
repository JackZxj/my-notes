```Go
package main

import (
	"context"
	"fmt"
	"time"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	config, _ := clientcmd.BuildConfigFromFlags("", "/Users/bytedance/.kube/dev-mechine-test.config")
	codec := runtime.NoopEncoder{Decoder: scheme.Codecs.UniversalDecoder()}
	config.NegotiatedSerializer = serializer.NegotiatedSerializerWrapper(runtime.SerializerInfo{Serializer: codec})
	restClient, restClientErr := rest.UnversionedRESTClientFor(config)
	if restClientErr != nil {
		panic(restClientErr)
	}
	// 这个接口不是所有用户都有权限，可以考虑使用 /version， 也有一些定制的apiserver会不给version权限，那么可以考虑根据res的结果进一步判断
	res, err := restClient.Get().AbsPath("/").Timeout(time.Second).DoRaw(context.TODO())
	if err != nil {
		panic(err)
	}
	fmt.Printf("%s\n", res)
}
```

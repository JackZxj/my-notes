# installation metrics-server

1. install metrics-server

```BASH
$ kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

2. create sa token (required in k8s 1.25+)

```BASH
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-metrics-server
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "metrics-server"
type: kubernetes.io/service-account-token
data: {}
EOF
```

3. kubelet insecure TLS 

`"Failed to scrape node" err="Get \"https://172.30.1.2:10250/metrics/resource\": x509: cannot validate certificate for 172.30.1.2 because it doesn't contain any IP SANs" node="controlplane"`

```BASH
$ kubectl edit deploy -n kube-system metrics-server
...
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls # this is new
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4 # could be bitnami/metrics-server:0.6.4
        imagePullPolicy: IfNotPresent
...

$ kubectl get po -n kube-system -l k8s-app=metrics-server
$ kubectl top no
```



# k8s ingress

## prepare a cluster

```BASH
$ kind create cluster --name ingress --image kindest/node:v1.20.2 --kubeconfig /root/ingress/kubeconfig
$ export KUBECONFIG=/root/ingress/kubeconfig
$ kubectl get no
NAME                    STATUS   ROLES                  AGE   VERSION
ingress-control-plane   Ready    control-plane,master   13m   v1.20.2

# prepare metallb for external IP
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
$ kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
$ kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
$ docker pull metallb/speaker:main
$ docker tag metallb/speaker:main quay.io/metallb/speaker:main
$ kind load docker-image quay.io/metallb/speaker:main --name ingress
$ docker pull metallb/controller:main
$ docker tag metallb/controller:main quay.io/metallb/controller:main
$ kind load docker-image quay.io/metallb/controller:main --name ingress

# Wait for all pods to be ready
$ docker network inspect -f '{{.IPAM.Config}}' kind
[{172.19.0.0/16  172.19.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
# metallb-configmap.yaml using IP 172.19.255.200-172.19.255.250
$ kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml
```

## install ingress

```BASH
$ wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.2/deploy/static/provider/baremetal/deploy.yaml
$ docker pull liangjw/ingress-nginx-controller:v1.0.2
$ docker tag liangjw/ingress-nginx-controller:v1.0.2 k8s.gcr.io/ingress-nginx/controller:v1.0.2
$ docker pull liangjw/kube-webhook-certgen:v1.0
$ docker tag liangjw/kube-webhook-certgen:v1.0 k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
$ kind load docker-image k8s.gcr.io/ingress-nginx/controller:v1.0.2 --name ingress
$ kind load docker-image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0 --name ingress
$ vi deploy.yaml
# 275   type: LoadBalancer
# 323           image: k8s.gcr.io/ingress-nginx/controller:v1.0.2
# 604           image: k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0
# 654           image: k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.0

$ kubectl apply -f deploy.yaml
# remember the EXTERNAL-IP of ingress-nginx-controller
$ kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.96.203.167   172.19.255.200   80:30332/TCP,443:32146/TCP   3m47s
ingress-nginx-controller-admission   ClusterIP      10.96.37.24     <none>           443/TCP                      3m47s
```

## test ingress

### prepare the services

```BASH
# deploy the services
$ docker pull nginx:alpine
$ kind load docker-image nginx:alpine  --name ingress
$ kubectl run nginx-0 --image=nginx:alpine
$ kubectl expose pod nginx-0 --port=80 --name=nginx-0
$ kubectl wait --for=condition=Ready --timeout=30s pods nginx-0;\
  kubectl exec -i nginx-0 -- sh -c "echo nginx-0 > /usr/share/nginx/html/index.html"

$ kubectl run nginx-1 --image=nginx:alpine
$ kubectl expose pod nginx-1 --port=80 --name=nginx-1
$ kubectl wait --for=condition=Ready --timeout=30s pods nginx-1;\
  kubectl exec -i nginx-1 -- sh -c "echo nginx-1 > /usr/share/nginx/html/index.html"


# $ kubectl run nginx-2 --image=nginx:alpine
# $ kubectl expose pod nginx-2 --port=80 --name=nginx-2
# $ kubectl wait --for=condition=Ready --timeout=30s pods nginx-2;\
#   kubectl exec -i nginx-2 -- sh -c "echo nginx-2 > /usr/share/nginx/html/index.html"




$  kubectl get po,svc
NAME          READY   STATUS    RESTARTS   AGE
pod/nginx-0   1/1     Running   0          9s
pod/nginx-1   1/1     Running   0          9s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   148m
service/nginx-0      ClusterIP   10.96.114.159   <none>        80/TCP    9s
service/nginx-1      ClusterIP   10.96.16.29     <none>        80/TCP    9s

# test
$ docker exec -i `docker ps -qf name=ingress-control-plane` curl -s 10.96.114.159
nginx-0
$ docker exec -i `docker ps -qf name=ingress-control-plane` curl -s 10.96.16.29:80
nginx-1
```

### deploy the ingresses

#### with two hosts

```BASH
$ vi ingress0.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx-0
spec:
  rules:
  - host: nginx0.foo.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-0
            port: 
              number: 80
  ingressClassName: nginx
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx-1
spec:
  rules:
  - host: nginx1.foo.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-1
            port: 
              number: 80
  ingressClassName: nginx

$ kubectl apply -f ingress0.yaml
$ kubectl get ing -owide
NAME              CLASS   HOSTS            ADDRESS      PORTS   AGE
ingress-nginx-0   nginx   nginx0.foo.org   172.19.0.4   80      50s
ingress-nginx-1   nginx   nginx1.foo.org   172.19.0.4   80      50s

$ curl http://172.19.255.200 -H 'Host: nginx0.foo.org'
nginx-0
$ curl http://172.19.255.200 -H 'Host: nginx1.foo.org'
nginx-1

# remove the ingress0
$ kubectl delete -f ingress0.yaml
```

#### with one host, but two paths (fanout)

```BASH
$ vi ingress1.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx-fanout
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # 一定需要，ingress匹配路由后去掉路由，直接转发到目标service，除非service本身就是带着路由
spec:
  rules:
  - host: foo.bar.com
    http:
      paths:
      - path: /foo
        pathType: Prefix
        backend:
          service:
            name: nginx-0
            port:
              number: 80
      - path: /bar
        pathType: Prefix
        backend:
          service:
            name: nginx-1
            port:
              number: 80
  ingressClassName: nginx

$ kubectl apply -f ingress1.yaml
$ kubectl get ing
NAME                   CLASS   HOSTS         ADDRESS      PORTS   AGE
ingress-nginx-fanout   nginx   foo.bar.com   172.19.0.4   80      36s

$ kubectl describe ing ingress-nginx-fanout
Name:             ingress-nginx-fanout
Namespace:        default
Address:          172.19.0.4
Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
Rules:
  Host         Path  Backends
  ----         ----  --------
  foo.bar.com
               /foo   nginx-0:80 (10.244.0.20:80)
               /bar   nginx-1:80 (10.244.0.21:80)
Annotations:   nginx.ingress.kubernetes.io/rewrite-target: /
Events:
  Type    Reason  Age                From                      Message
  ----    ------  ----               ----                      -------
  Normal  Sync    23s (x2 over 59s)  nginx-ingress-controller  Scheduled for sync

$ curl http://172.19.255.200/foo -H 'Host: foo.bar.com'
nginx-0
$ curl http://172.19.255.200/bar -H 'Host: foo.bar.com'
nginx-1

# remove the ingress1
$ kubectl delete -f ingress1.yaml
```

## multiple-ingress

TODO: https://kubernetes.github.io/ingress-nginx/user-guide/multiple-ingress/

## external-ip ingress

ref: https://stackoverflow.com/questions/61751724/kubernetes-ingress-rules-for-external-service-with-externalname-type

```BASH
$ vi ingress-externalNameSVC-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: test-alpha
spec:
  clusterIP: None
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: v1
kind: Endpoints
metadata:
  name: my-service
  namespace: test-alpha
subsets:
  - addresses:
      - ip: 10.244.0.83  # a nginx pod's IP, which runs in default namespace
      - ip: 110.242.68.3 # IP of www.baidu.com
      - ip: 110.242.68.4 # IP of www.baidu.com
    ports:
      - port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-nginx-sss
  namespace: test-alpha
spec:
  rules:
  - host: nginx2.foo.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
  ingressClassName: nginx

$ kubectl apply -f ingress-externalNameSVC-headless.yaml

# Ingress will randomly route to three endpoints
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
200
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
200
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
200
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
200
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
200
$ curl -sIL -w "%{http_code}\n" -o /dev/null  172.19.255.101 -H 'Host: nginx2.foo.org'
403
```

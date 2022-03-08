# multi-cluster ingress

ref: 
* https://kind.sigs.k8s.io/docs/user/ingress/
* https://kubernetes.github.io/ingress-nginx/user-guide/tls/
* https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations
* https://stackoverflow.com/questions/68687814/ingress-nginx-proxy-to-external-url

## prepare

```BASH
$ mkdir ingress && cd ingress

$ cat <<EOF | kind create cluster --kubeconfig ingress.config --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ingress
nodes:
- role: control-plane
  image: kindest/node:v1.20.2
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

$ export KUBECONFIG=`pwd`/ingress.config
```

## install ingress

```BASH
$ wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

$ vi deploy.yaml
# replace image
$ cat deploy.yaml | grep 'image:'
        image: liangjw/ingress-nginx-controller:v1.1.2
        image: liangjw/kube-webhook-certgen:v1.1.1
        image: liangjw/kube-webhook-certgen:v1.1.1

$ docker pull liangjw/ingress-nginx-controller:v1.1.2
$ kind load docker-image liangjw/ingress-nginx-controller:v1.1.2 --name ingress
$ docker pull liangjw/kube-webhook-certgen:v1.1.1
$ kind load docker-image liangjw/kube-webhook-certgen:v1.1.1 --name ingress

$ kubectl apply -f deploy.yaml

$ kubectl  get all -n ingress-nginx
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-8zjs5        0/1     Completed   0          2m9s
pod/ingress-nginx-admission-patch-bp977         0/1     Completed   1          2m9s
pod/ingress-nginx-controller-78476fcc4c-sqvv8   1/1     Running     0          2m9s

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    10.96.236.100   <none>        80:32226/TCP,443:31615/TCP   2m9s
service/ingress-nginx-controller-admission   ClusterIP   10.96.15.234    <none>        443/TCP                      2m9s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           2m9s

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-78476fcc4c   1         1         1       2m9s

NAME                                       COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   1/1           2s         2m9s
job.batch/ingress-nginx-admission-patch    1/1           4s         2m9s
```

## test ingress

```BASH
$ docker pull hashicorp/http-echo:0.2.3
$ kind load docker-image hashicorp/http-echo:0.2.3 --name ingress

$ curl https://kind.sigs.k8s.io/examples/ingress/usage.yaml -o usage.yaml
$ kubectl apply -f usage.yaml

$ docker inspect ingress-control-plane | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.19.0.2",

$ kubectl  get svc -n ingress-nginx
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.96.236.100   <none>        80:32226/TCP,443:31615/TCP   11m
ingress-nginx-controller-admission   ClusterIP   10.96.15.234    <none>        443/TCP                      11m

$ curl 172.19.0.2:32226/foo
foo
$ curl 172.19.0.2:32226/bar
bar
```

## test multi-cluster

### headless svc

```BASH
# create another k8s cluster
$ kind create cluster --name pr --image kindest/node:v1.20.2 --kubeconfig pr.config

$ kind load docker-image hashicorp/http-echo:0.2.3 --name pr

$ kubectl run pr-foo --image=hashicorp/http-echo:0.2.3 -- "-text=pr-foo" --kubeconfig pr.config
$ kubectl run pr-bar --image=hashicorp/http-echo:0.2.3 -- "-text=pr-bar" --kubeconfig pr.config

$ kubectl expose pod pr-foo --port=5678 --type=NodePort --kubeconfig pr.config
$ kubectl expose pod pr-bar --port=5678 --type=NodePort --kubeconfig pr.config

$ docker inspect pr-control-plane | grep IPAddress
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.19.0.3",

$ kubectl get svc --kubeconfig pr.config
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)           AGE
pr-bar       NodePort    10.96.41.60   <none>        5678:30860/TCP    6s
pr-foo       NodePort    10.96.72.90   <none>        5678:30547/TCP    12s

$ curl 172.19.0.3:30860
pr-bar
$ curl 172.19.0.3:30547
pr-foo

$ kubectl apply -f ingress-headless-svc.yaml --kubeconfig ingress.config

$ curl 172.19.0.2:32226/foo -H 'Host: echo.test.org'
pr-foo
$ curl 172.19.0.2:32226/foo -H 'Host: echo.test.org'
pr-bar
$ curl 172.19.0.2:32226/foo -H 'Host: echo.test.org'
pr-foo
$ curl 172.19.0.2:32226/foo -H 'Host: echo.test.org'
pr-foo
$ curl 172.19.0.2:32226/foo -H 'Host: echo.test.org'
pr-bar
$ curl 172.19.0.2:32226/bar -H 'Host: echo.test.org'
pr-bar
$ curl 172.19.0.2:32226/bar
bar
$ curl 172.19.0.2:32226/foo
foo
```

```yaml
# ingress-headless-svc.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: alpha
---
apiVersion: v1
kind: Service
metadata:
  name: pr-foo
  namespace: alpha
spec:
  clusterIP: None
  ports:
    - protocol: TCP
      port: 80
      targetPort: 30547
---
apiVersion: v1
kind: Endpoints
metadata:
  name: pr-foo
  namespace: alpha
subsets:
  - addresses:
      - ip: 172.19.0.3
    ports:
      - port: 30547
  - addresses:
      - ip: 172.19.0.3
    ports:
      - port: 30860
---
apiVersion: v1
kind: Service
metadata:
  name: pr-bar
  namespace: alpha
spec:
  clusterIP: None
  ports:
    - protocol: TCP
      port: 80
      targetPort: 30860
---
apiVersion: v1
kind: Endpoints
metadata:
  name: pr-bar
  namespace: alpha
subsets:
  - addresses:
      - ip: 172.19.0.3
    ports:
      - port: 30860
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pr
  namespace: alpha
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: / # 一定需要，ingress匹配路由后去掉路由，直接转发到目标service，除非service本身就是带着路由
spec:
  rules:
  - host: echo.test.org
    http:
      paths:
      - path: /foo
        pathType: Prefix
        backend:
          service:
            name: pr-foo
            port:
              number: 80
      - path: /bar
        pathType: Prefix
        backend:
          service:
            name: pr-bar
            port:
              number: 80
  ingressClassName: nginx
```

### externalName svc

```BASH
$ kubectl apply -f ingress-externalname-svc.yaml --kubeconfig ingress.config

$ curl 172.19.0.2:32226 -H 'Host: echo.en.org'
<html><body>You are being <a href="http://echo.en.org/users/sign_in">redirected</a>.</body></html>

$ curl 'https://172.19.0.2:31615' -H 'Host: echo.entls.org' -k
<!DOCTYPE html>
<!--STATUS OK--><html> <head><meta http-equiv=content-type content=text/html;charset=utf-8><meta http-equiv=X-UA-Compatible content=IE=Edge><meta content=always name=referrer><link rel=stylesheet type=text/css href=https://ss1.bdstatic.com/5eN1bjq8AAUYm2zgoY3K/r/www/cache/bdorz/baidu.min.css><title>百度一下，你就知道</title></head> <body link=#0000cc> <div id=wrapper> <div id=head> <div class=head_wrapper> <div class=s_form> <div class=s_form_wrapper> <div id=lg> <img hidefocus=true src=//www.baidu.com/img/bd_logo1.png width=270 height=129> </div> <form id=form name=f action=//www.baidu.com/s class=fm> <input type=hidden name=bdorz_come value=1> <input type=hidden name=ie value=utf-8> <input type=hidden name=f value=8> <input type=hidden name=rsv_bp value=1> <input type=hidden name=rsv_idx value=1> <input type=hidden name=tn value=baidu><span class="bg s_ipt_wr"><input id=kw name=wd class=s_ipt value maxlength=255 autocomplete=off autofocus=autofocus></span><span class="bg s_btn_wr"><input type=submit id=su value=百度一下 class="bg s_btn" autofocus></span> </form> </div> </div> <div id=u1> <a href=http://news.baidu.com name=tj_trnews class=mnav>新闻</a> <a href=https://www.hao123.com name=tj_trhao123 class=mnav>hao123</a> <a href=http://map.baidu.com name=tj_trmap class=mnav>地图</a> <a href=http://v.baidu.com name=tj_trvideo class=mnav>视频</a> <a href=http://tieba.baidu.com name=tj_trtieba class=mnav>贴吧</a> <noscript> <a href=http://www.baidu.com/bdorz/login.gif?login&amp;tpl=mn&amp;u=http%3A%2F%2Fwww.baidu.com%2f%3fbdorz_come%3d1 name=tj_login class=lb>登录</a> </noscript> <script>document.write('<a href="http://www.baidu.com/bdorz/login.gif?login&tpl=mn&u='+ encodeURIComponent(window.location.href+ (window.location.search === "" ? "?" : "&")+ "bdorz_come=1")+ '" name="tj_login" class="lb">登录</a>');
                </script> <a href=//www.baidu.com/more/ name=tj_briicon class=bri style="display: block;">更多产品</a> </div> </div> </div> <div id=ftCon> <div id=ftConw> <p id=lh> <a href=http://home.baidu.com>关于百度</a> <a href=http://ir.baidu.com>About Baidu</a> </p> <p id=cp>&copy;2017&nbsp;Baidu&nbsp;<a href=http://www.baidu.com/duty/>使用百度前必读</a>&nbsp; <a href=http://jianyi.baidu.com/ class=cp-feedback>意见反馈</a>&nbsp;京ICP证030173号&nbsp; <img src=//www.baidu.com/img/gs.gif> </p> </div> </div> </div> </body> </html>
```

```yaml
# ingress-externalname-svc.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: beta
---
apiVersion: v1
kind: Service
metadata:
  name: en
  namespace: beta
spec:
  type: ExternalName
  externalName: git.inspur.com # gitlab (without TLS)
---
apiVersion: v1
kind: Service
metadata:
  name: entls
  namespace: beta
spec:
  type: ExternalName
  externalName: www.baidu.com # baidu (with TLS) (有的可行，有的不可行，具体好像跟加密方式有关？？)
  ports:
    - protocol: TCP
      port: 443
      targetPort: 443
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: en
  namespace: beta
  annotations:
    # nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30" # 30s
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
spec:
  ingressClassName: nginx
  rules:
  - host: echo.en.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: en
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: entls
  namespace: beta
  annotations:
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30" # 30s
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/upstream-vhost: "www.baidu.com"
spec:
  ingressClassName: nginx
  rules:
  - host: echo.entls.org
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: entls
            port:
              number: 443
```


## with tls

```BASH
$ KEY_FILE=tls.key
$ CERT_FILE=tls.crt
$ HOST=echo.tls.org

# create tls
$ openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
$ kubectl create secret tls ingress-tls --key ${KEY_FILE} --cert ${CERT_FILE} -n alpha --kubeconfig ingress.config

$ kubectl  get svc -n ingress-nginx --kubeconfig ingress.config
NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             NodePort    10.96.236.100   <none>        80:32226/TCP,443:31615/TCP   19m
ingress-nginx-controller-admission   ClusterIP   10.96.15.234    <none>        443/TCP                      19m

# create ingress
$ kubectl apply -f ingress-tls.yaml --kubeconfig ingress.config

$ curl https://172.19.0.2:31615/tls-foo -H 'Host: echo.tls.org' -k
pr-bar
$ curl https://172.19.0.2:31615/tls-foo -H 'Host: echo.tls.org' -k
pr-foo
$ curl https://172.19.0.2:31615/tls-foo -H 'Host: echo.tls.org' -k
pr-foo
$ curl https://172.19.0.2:31615/tls-foo -H 'Host: echo.tls.org' -k
pr-foo
$ curl https://172.19.0.2:31615/tls-foo -H 'Host: echo.tls.org' -k
pr-bar
```

```yaml
# ingress-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-pr
  namespace: alpha
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
      - echo.tls.org
    secretName: ingress-tls
  rules:
  - host: echo.tls.org
    http:
      paths:
      - path: /tls-foo
        pathType: Prefix
        backend:
          service:
            name: pr-foo
            port:
              number: 80
```

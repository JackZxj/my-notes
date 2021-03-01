# use curl to connect k8s api

## With K8s CA

``` Python
def create_cert(conf_path, key_path="/data/board/cert/apiserver-key.pem", cert_path="/data/board/cert/apiserver.pem", ca_key="/etc/board/cert/ca-key.pem", ca_cert="/etc/board/cert/ca.pem"):
        cert_dir = os.path.dirname(cert_path)
        csr_path = os.path.join(cert_dir, "request.csr")
        rc = subprocess.call(["openssl", "genrsa", "-out", key_path, "2048"], stdout=FNULL, stderr=subprocess.STDOUT)
        if rc != 0:
                return rc
        rc = subprocess.call(["openssl", "req", "-new", "-key", key_path, "-out", csr_path, "-config", conf_path], stdout=FNULL, stderr=subprocess.STDOUT)
        if rc != 0:
                return rc
        return subprocess.call(["openssl", "x509", "-req", "-in", csr_path, "-CA", ca_cert, "-CAkey", ca_key, "-CAcreateserial", "-out", cert_path, "-days", "10000", "-extensions", "v3_ext", "-extfile", conf_path], stdout=FNULL, stderr=subprocess.STDOUT)

create_cert("/root/Deploy/config/apiserver/openssl.conf")
# $ cat /root/Deploy/config/apiserver/openssl.conf
# [ req ]
# default_bits = 2048
# prompt = no
# default_md = sha256
# req_extensions = req_ext
# distinguished_name = dn

# [ dn ]
# CN = board-apiserver

# [ req_ext ]
# subjectAltName = @alt_names

# [ alt_names ]
# DNS.1 = kubernetes
# DNS.2 = kubernetes.default
# DNS.3 = kubernetes.default.svc
# DNS.4 = kubernetes.default.svc.cluster
# DNS.5 = kubernetes.default.svc.cluster.local
# IP.1 = 10.221.2.75
# IP.2 = 10.254.0.1
# IP.3 = 127.0.0.1

# [ v3_ext ]
# authorityKeyIdentifier=keyid,issuer:always
# basicConstraints=CA:FALSE
# keyUsage=keyEncipherment,dataEncipherment
# extendedKeyUsage=serverAuth,clientAuth
# subjectAltName=@alt_names
```

``` BASH
# 使用 k8s ca访问
# 匿名访问 /etc/board/cert/ca.pem=/etc/kubernetes/pki/ca.crt
$ curl https://10.221.2.75:6443/version --cacert /etc/kubernetes/pki/ca.crt
{
  "major": "1",
  "minor": "18",
  "gitVersion": "v1.18.3",
  "gitCommit": "2e7996e3e2712684bc73f0dec0200d64eec7fe40",
  "gitTreeState": "clean",
  "buildDate": "2020-05-20T12:43:34Z",
  "goVersion": "go1.13.9",
  "compiler": "gc",
  "platform": "linux/amd64"
}
# 带认证访问
$ curl https://10.221.2.75:6443/api/v1/namespaces/default/serviceaccounts/default --cacert /etc/board/cert/ca.pem --key /data/board/cert/apiserver-key.pem --cert /data/board/cert/apiserver.pem
{
  "kind": "ServiceAccount",
  "apiVersion": "v1",
  "metadata": {
    "name": "default",
    "namespace": "default",
    "selfLink": "/api/v1/namespaces/default/serviceaccounts/default",
    "uid": "0be161f5-f15b-4c34-bd7f-6643a62aca33",
    "resourceVersion": "481",
    "creationTimestamp": "2021-01-14T07:24:33Z"
  },
  "secrets": [
    {
      "name": "default-token-v2fbx"
    }
  ]
}
```

## With K8s ServiceAccount Token

``` BASH
ACCOUNT=test
NAMESPACE=default
CRB_NAME=test-crb

kubectl create sa $ACCOUNT -n=$NAMESPACE

kubectl create clusterrolebinding $CRB_NAME --clusterrole='cluster-admin' --serviceaccount=$NAMESPACE:$ACCOUNT

TOKEN=$(kubectl get secret $(kubectl get serviceaccount $ACCOUNT -n=$NAMESPACE -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode )

curl https://192.168.137.115:6443/api/v1/nodes --header "Authorization: Bearer $TOKEN" --insecure

curl https://192.168.137.115:6443/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/temperature-and-humidity --header "Authorization: Bearer $TOKEN" --insecure

curl https://192.168.137.115:6443/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices --header "Authorization: Bearer $TOKEN" --insecure

curl https://192.168.137.115:6443/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devicemodels/tmp-rh-model --header "Authorization: Bearer $TOKEN" --insecure

# properties in metadata are not very important
curl -v -X PUT https://192.168.137.115:6443/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/rgb-light-device --header "Authorization: Bearer $TOKEN" --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"rgb-light-device\"},\"name\":\"rgb-light-device\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"rgb-light\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero02\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"red-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"green-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"blue-pwm\"}]}}\n"},"creationTimestamp":"2020-08-27T13:51:34Z","generation":10,"labels":{"description":"rgb-light-device"},"name":"rgb-light-device","namespace":"default","resourceVersion":"3629361","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/rgb-light-device","uid":"f68d87df-15a0-4547-8e06-cb732c7d956f"},"spec":{"deviceModelRef":{"name":"rgb-light"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["edge-zero02"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"int"},"value":"20"},"propertyName":"red-pwm"},{"desired":{"metadata":{"type":"int"},"value":"0"},"propertyName":"green-pwm"},{"desired":{"metadata":{"type":"int"},"value":"10"},"propertyName":"blue-pwm"}]}}' --insecure 
```

----------------
Useless

``` json
{
"apiVersion":"devices.kubeedge.io/v1alpha1",
"kind":"Device",
"metadata":{
    "annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"temperature-and-humidity\"},\"name\":\"temperature-and-humidity\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"tmp-rh-model\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero02\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"\"},\"propertyName\":\"temperature-status\"},{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"\"},\"propertyName\":\"humidity-status\"}]}}\n"},
    "creationTimestamp":"2020-08-18T07:00:07Z",
    "generation":171071,
    "labels":{"description":"temperature-and-humidity"},
    "name":"temperature-and-humidity",
    "namespace":"default",
    "resourceVersion":"3428248",
    "selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/temperature-and-humidity",
    "uid":"b1c0bb07-d7d3-4694-9168-897ebeca9841"
    },
"spec":{
    "deviceModelRef":{"name":"tmp-rh-model"},
    "nodeSelector":{"nodeSelectorTerms":[
        {"matchExpressions":[
            {"key":"kubernetes.io/hostname",
            "operator":"In",
            "values":["edge-zero02"]}
            ]}
        ]}
    },
"status":{"twins":[
    {
    "desired":{"metadata":{"type":"string"},"value":""},
    "propertyName":"temperature-status",
    "reported":{"metadata":{"timestamp":"1598956462859","type":"string"},"value":"26C"}
    },
    {"desired":{"metadata":{"type":"string"},"value":""},"propertyName":"humidity-status","reported":{"metadata":{"timestamp":"1598956462843","type":"string"},"value":"50#"}}
    ]}
}
```

``` json
{"apiVersion":"devices.kubeedge.io/v1alpha1",
"items":[
    {"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"LEDLight\",\"model\":\"led-light\"},\"name\":\"led-light-instance-01\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"led-light\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"\",\"operator\":\"In\",\"values\":[\"edge-zero01\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"OFF\"},\"propertyName\":\"power-status\"}]}}\n"},"creationTimestamp":"2020-08-27T09:37:04Z","generation":27,"labels":{"description":"LEDLight","model":"led-light"},"name":"led-light-instance-01","namespace":"default","resourceVersion":"3196204","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/led-light-instance-01","uid":"36212bbf-fa4e-4182-ad3a-e21ccb9bdd87"},"spec":{"deviceModelRef":{"name":"led-light"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"","operator":"In","values":["edge-zero01"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"string"},"value":"ON"},"propertyName":"power-status","reported":{"metadata":{"timestamp":"1598524712730","type":"string"},"value":"OFF"}}]}},
    {"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"rgb-light-device\"},\"name\":\"rgb-light-device\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"rgb-light\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero02\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"red-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"green-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"blue-pwm\"}]}}\n"},"creationTimestamp":"2020-08-27T13:51:34Z","generation":9,"labels":{"description":"rgb-light-device"},"name":"rgb-light-device","namespace":"default","resourceVersion":"3197165","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/rgb-light-device","uid":"f68d87df-15a0-4547-8e06-cb732c7d956f"},"spec":{"deviceModelRef":{"name":"rgb-light"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["edge-zero02"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"int"},"value":"220"},"propertyName":"red-pwm"},{"desired":{"metadata":{"type":"int"},"value":"0"},"propertyName":"green-pwm"},{"desired":{"metadata":{"type":"int"},"value":"0"},"propertyName":"blue-pwm"}]}},
    {"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"temperature\",\"manufacturer\":\"test\"},\"name\":\"temperature\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"temperature-model\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero01\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"\"},\"propertyName\":\"temperature-status\"}]}}\n"},"creationTimestamp":"2020-08-19T04:06:08Z","generation":25096,"labels":{"description":"temperature","manufacturer":"test"},"name":"temperature","namespace":"default","resourceVersion":"698267","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/temperature","uid":"dfdd191a-7ae4-456d-b9a1-684853ebb48f"},"spec":{"deviceModelRef":{"name":"temperature-model"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["edge-zero01"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"string"},"value":""},"propertyName":"temperature-status","reported":{"metadata":{"timestamp":"1597835193931","type":"string"},"value":"64C"}}]}},
    {"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"temperature-and-humidity\"},\"name\":\"temperature-and-humidity\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"tmp-rh-model\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero02\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"\"},\"propertyName\":\"temperature-status\"},{\"desired\":{\"metadata\":{\"type\":\"string\"},\"value\":\"\"},\"propertyName\":\"humidity-status\"}]}}\n"},"creationTimestamp":"2020-08-18T07:00:07Z","generation":189625,"labels":{"description":"temperature-and-humidity"},"name":"temperature-and-humidity","namespace":"default","resourceVersion":"3592012","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/temperature-and-humidity","uid":"b1c0bb07-d7d3-4694-9168-897ebeca9841"},"spec":{"deviceModelRef":{"name":"tmp-rh-model"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["edge-zero02"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"string"},"value":""},"propertyName":"temperature-status","reported":{"metadata":{"timestamp":"1599017947772","type":"string"},"value":"27C"}},{"desired":{"metadata":{"type":"string"},"value":""},"propertyName":"humidity-status","reported":{"metadata":{"timestamp":"1599017947770","type":"string"},"value":"44#"}}]}}
    ],
"kind":"DeviceList",
"metadata":{"continue":"","resourceVersion":"3592015","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices"}
}
```

``` json
{"apiVersion":"devices.kubeedge.io/v1alpha1",
"kind":"DeviceModel",
"metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"DeviceModel\",\"metadata\":{\"annotations\":{},\"name\":\"tmp-rh-model\",\"namespace\":\"default\"},\"spec\":{\"properties\":[{\"description\":\"Temperature collected from the edge device\",\"name\":\"temperature-status\",\"type\":{\"string\":{\"accessMode\":\"ReadOnly\",\"defaultValue\":\"\"}}},{\"description\":\"Relative humidity collected from the edge device\",\"name\":\"humidity-status\",\"type\":{\"string\":{\"accessMode\":\"ReadOnly\",\"defaultValue\":\"\"}}}]}}\n"},"creationTimestamp":"2020-08-18T06:55:09Z","generation":1,"name":"tmp-rh-model","namespace":"default","resourceVersion":"409191","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devicemodels/tmp-rh-model","uid":"22c16d13-6ad4-44fc-a381-028fee42e558"},
"spec":{
  "properties":[
    {"description":"Temperature collected from the edge device",
    "name":"temperature-status",
    "type":{"string":
      {"accessMode":"ReadOnly","defaultValue":""}
      }
    },
    {"description":"Relative humidity collected from the edge device","name":"humidity-status","type":{"string":{"accessMode":"ReadOnly","defaultValue":""}}}
    ]}
}
```

``` json
{"apiVersion":"devices.kubeedge.io/v1alpha1","kind":"Device","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"devices.kubeedge.io/v1alpha1\",\"kind\":\"Device\",\"metadata\":{\"annotations\":{},\"labels\":{\"description\":\"rgb-light-device\"},\"name\":\"rgb-light-device\",\"namespace\":\"default\"},\"spec\":{\"deviceModelRef\":{\"name\":\"rgb-light\"},\"nodeSelector\":{\"nodeSelectorTerms\":[{\"matchExpressions\":[{\"key\":\"kubernetes.io/hostname\",\"operator\":\"In\",\"values\":[\"edge-zero02\"]}]}]}},\"status\":{\"twins\":[{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"red-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"green-pwm\"},{\"desired\":{\"metadata\":{\"type\":\"int\"},\"value\":\"50\"},\"propertyName\":\"blue-pwm\"}]}}\n"},"creationTimestamp":"2020-08-27T13:51:34Z","generation":10,"labels":{"description":"rgb-light-device"},"name":"rgb-light-device","namespace":"default","resourceVersion":"3629361","selfLink":"/apis/devices.kubeedge.io/v1alpha1/namespaces/default/devices/rgb-light-device","uid":"f68d87df-15a0-4547-8e06-cb732c7d956f"},"spec":{"deviceModelRef":{"name":"rgb-light"},"nodeSelector":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"kubernetes.io/hostname","operator":"In","values":["edge-zero02"]}]}]}},"status":{"twins":[{"desired":{"metadata":{"type":"int"},"value":"20"},"propertyName":"red-pwm"},{"desired":{"metadata":{"type":"int"},"value":"0"},"propertyName":"green-pwm"},{"desired":{"metadata":{"type":"int"},"value":"0"},"propertyName":"blue-pwm"}]}}
```

TOKEN=$(kubectl get secret -n=kube-system $(kubectl get serviceaccount default -n=kube-system -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode )

curl https://192.168.137.115:6443/api/v1/nodes --header "Authorization: Bearer $TOKEN" --insecure

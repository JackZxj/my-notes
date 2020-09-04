# use curl to connect k8s api

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

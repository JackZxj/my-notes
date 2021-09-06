# Deploy-Karmada-by-NodePort

```BASH
# 修改 APIServer 部署配置
# 添加 nodePort
# 修改 type
$ git diff artifacts/deploy/karmada-apiserver.yaml
diff --git a/artifacts/deploy/karmada-apiserver.yaml b/artifacts/deploy/karmada-apiserver.yaml
index ea964e2..9c24dd4 100644
--- a/artifacts/deploy/karmada-apiserver.yaml
+++ b/artifacts/deploy/karmada-apiserver.yaml
@@ -124,6 +124,7 @@ spec:
       port: 5443
       protocol: TCP
       targetPort: 5443
+      nodePort: 32443
   selector:
     app: karmada-apiserver
-  type: {{service_type}}
+  type: NodePort


# 修改部署脚本，把 KARMADA_APISERVER_IP 改为 master IP(或者浮动IP)
$ git diff hack/deploy-karmada.sh
diff --git a/hack/deploy-karmada.sh b/hack/deploy-karmada.sh
index 82d449c..d2c036f 100755
--- a/hack/deploy-karmada.sh
+++ b/hack/deploy-karmada.sh
@@ -172,7 +172,7 @@ util::wait_pod_ready "${APISERVER_POD_LABEL}" "${KARMADA_SYSTEM_NAMESPACE}"
 if [ "${HOST_CLUSTER_TYPE}" = "remote" ]; then
   case $KARMADA_APISERVER_SERVICE_TYPE in
     ClusterIP)
-      KARMADA_APISERVER_IP=$(kubectl get service karmada-apiserver -n "${KARMADA_SYSTEM_NAMESPACE}" -o=jsonpath='{.spec.clusterIP}')
+      KARMADA_APISERVER_IP=10.110.70.230
     ;;
     LoadBalancer)
       if util::wait_service_external_ip "karmada-apiserver" "${KARMADA_SYSTEM_NAMESPACE}"; then

$ export KARMADA_APISERVER_SECURE_PORT=32443
$ hack/remote-up-karmada.sh /root/jackzhang/config.json external true
```

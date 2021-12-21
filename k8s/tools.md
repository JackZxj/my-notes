```BASH
# 持续监控日志 follow
journalctl -u kubelet -n 100 --no-pager -f

# namespace 下所有资源
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -l <label>=<value> -n <namespace>

# 删除 Terminating namespace
NS=my-namespace
kubectl get namespace $NS -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

```BASH
#!/bin/bash
variable=(as123 tang-test tang-test2 test-10 test-11 test-12 test-4 test-5 test-8 test-9 test12170 yyy zyxin) 
# variable=(as123 tang-test) 

for i in ${variable[*]}; do
    echo -e "# kubectl get configmaps,endpoints,events,limitranges,persistentvolumeclaims,pods,podtemplates,replicationcontrollers,resourcequotas,secrets,serviceaccounts,services,controllerrevisions.apps,daemonsets.apps,deployments.apps,replicasets.apps,statefulsets.apps,horizontalpodautoscalers.autoscaling,cronjobs.batch,jobs.batch,leases.coordination.k8s.io,endpointslices.discovery.k8s.io,events.events.k8s.io,ingresses.extensions,ingresses.networking.k8s.io,networkpolicies.networking.k8s.io,poddisruptionbudgets.policy,rolebindings.rbac.authorization.k8s.io,roles.rbac.authorization.k8s.io \
    -n karmada-system-a309ee71-1c90-4a61-8ea0-023d9aa0141b-$i --ignore-not-found"
    kubectl get configmaps,endpoints,events,limitranges,persistentvolumeclaims,pods,podtemplates,replicationcontrollers,resourcequotas,secrets,serviceaccounts,services,controllerrevisions.apps,daemonsets.apps,deployments.apps,replicasets.apps,statefulsets.apps,horizontalpodautoscalers.autoscaling,cronjobs.batch,jobs.batch,leases.coordination.k8s.io,endpointslices.discovery.k8s.io,events.events.k8s.io,ingresses.extensions,ingresses.networking.k8s.io,networkpolicies.networking.k8s.io,poddisruptionbudgets.policy,rolebindings.rbac.authorization.k8s.io,roles.rbac.authorization.k8s.io \
    -n karmada-system-a309ee71-1c90-4a61-8ea0-023d9aa0141b-$i --ignore-not-found
    echo ""
done
```

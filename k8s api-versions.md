# K8S api-versions

`kubectl api-versions` to get current api versions.

## 1.15.x

- admissionregistration.k8s.io/v1beta1
- apiextensions.k8s.io/v1beta1
- apiregistration.k8s.io/v1
- apiregistration.k8s.io/v1beta1
- apps/v1
- apps/v1beta1 **`(deprecated since v1.6)`**
- apps/v1beta2 **`(deprecated since v1.6)`**
- authentication.k8s.io/v1
- authentication.k8s.io/v1beta1
- authorization.k8s.io/v1
- authorization.k8s.io/v1beta1
- autoscaling/v1
- autoscaling/v2beta1
- autoscaling/v2beta2
- batch/v1
- batch/v1beta1
- certificates.k8s.io/v1beta1
- coordination.k8s.io/v1
- coordination.k8s.io/v1beta1
- events.k8s.io/v1beta1
- extensions/v1beta1
- networking.k8s.io/v1
- networking.k8s.io/v1beta1
- node.k8s.io/v1beta1
- policy/v1beta1
- rbac.authorization.k8s.io/v1
- rbac.authorization.k8s.io/v1beta1
- scheduling.k8s.io/v1
- scheduling.k8s.io/v1beta1
- storage.k8s.io/v1
- storage.k8s.io/v1beta1
- v1

## 1.16.x

- admissionregistration.k8s.io/v1 **`(new)`**
- admissionregistration.k8s.io/v1beta1
- apiextensions.k8s.io/v1 **`(new)`**
- apiextensions.k8s.io/v1beta1
- apiregistration.k8s.io/v1
- apiregistration.k8s.io/v1beta1
- apps/v1
- authentication.k8s.io/v1
- authentication.k8s.io/v1beta1
- authorization.k8s.io/v1
- authorization.k8s.io/v1beta1
- autoscaling/v1
- autoscaling/v2beta1
- autoscaling/v2beta2
- batch/v1
- batch/v1beta1
- certificates.k8s.io/v1beta1
- coordination.k8s.io/v1
- coordination.k8s.io/v1beta1
- events.k8s.io/v1beta1
- extensions/v1beta1 **`(deprecated partly)`**
- networking.k8s.io/v1
- networking.k8s.io/v1beta1
- node.k8s.io/v1beta1
- policy/v1beta1
- rbac.authorization.k8s.io/v1
- rbac.authorization.k8s.io/v1beta1
- scheduling.k8s.io/v1
- scheduling.k8s.io/v1beta1 **`(deprecated partly)`**
- storage.k8s.io/v1
- storage.k8s.io/v1beta1
- v1

## 1.17.x

- admissionregistration.k8s.io/v1
- admissionregistration.k8s.io/v1beta1
- apiextensions.k8s.io/v1
- apiextensions.k8s.io/v1beta1
- apiregistration.k8s.io/v1
- apiregistration.k8s.io/v1beta1
- apps/v1
- authentication.k8s.io/v1
- authentication.k8s.io/v1beta1
- authorization.k8s.io/v1
- authorization.k8s.io/v1beta1
- autoscaling/v1
- autoscaling/v2beta1
- autoscaling/v2beta2
- batch/v1
- batch/v1beta1
- certificates.k8s.io/v1beta1
- coordination.k8s.io/v1
- coordination.k8s.io/v1beta1
- discovery.k8s.io/v1beta1 **`(new)`**
- events.k8s.io/v1beta1
- extensions/v1beta1 **`(deprecated partly)`**
- networking.k8s.io/v1
- networking.k8s.io/v1beta1
- node.k8s.io/v1beta1
- policy/v1beta1
- rbac.authorization.k8s.io/v1
- rbac.authorization.k8s.io/v1beta1
- scheduling.k8s.io/v1
- scheduling.k8s.io/v1beta1 **`(deprecated partly)`**
- storage.k8s.io/v1
- storage.k8s.io/v1beta1
- v1

----

## K8S API v1.16 Overview

- WORKLOADS APIS
  - Container v1 core
  - CronJob v1beta1 batch
  - DaemonSet v1 apps
  - Deployment v1 apps
  - Job v1 batch
  - Pod v1 core
  - ReplicaSet v1 apps
  - ReplicationController v1 core
  - StatefulSet v1 apps
- SERVICE APIS
  - Endpoints v1 core
  - EndpointSlice v1alpha1 discovery.k8s.io
  - Ingress v1beta1 networking.k8s.io
  - Service v1 core
- CONFIG AND STORAGE APIS
  - ConfigMap v1 core
  - CSIDriver v1beta1 storage.k8s.io
  - CSINode v1beta1 storage.k8s.io
  - Secret v1 core
  - PersistentVolumeClaim v1 core
  - StorageClass v1 storage.k8s.io
  - Volume v1 core
  - VolumeAttachment v1 storage.k8s.io
- METADATA APIS
  - ControllerRevision v1 apps
  - CustomResourceDefinition v1 apiextensions.k8s.io
  - Event v1 core
  - LimitRange v1 core
  - HorizontalPodAutoscaler v1 autoscaling
  - MutatingWebhookConfiguration v1 admissionregistration.k8s.io
  - ValidatingWebhookConfiguration v1 admissionregistration.k8s.io
  - PodTemplate v1 core
  - PodDisruptionBudget v1beta1 policy
  - PriorityClass v1 scheduling.k8s.io
  - PodPreset v1alpha1 settings.k8s.io
  - PodSecurityPolicy v1beta1 policy
- CLUSTER APIS
  - APIService v1 apiregistration.k8s.io
  - AuditSink v1alpha1 auditregistration.k8s.io
  - Binding v1 core
  - CertificateSigningRequest v1beta1 certificates.k8s.io
  - ClusterRole v1 rbac.authorization.k8s.io
  - ClusterRoleBinding v1 rbac.authorization.k8s.io
  - ComponentStatus v1 core
  - Lease v1 coordination.k8s.io
  - LocalSubjectAccessReview v1 authorization.k8s.io
  - Namespace v1 core
  - Node v1 core
  - PersistentVolume v1 core
  - ResourceQuota v1 core
  - Role v1 rbac.authorization.k8s.io
  - RoleBinding v1 rbac.authorization.k8s.io
  - RuntimeClass v1beta1 node.k8s.io
  - SelfSubjectAccessReview v1 authorization.k8s.io
  - SelfSubjectRulesReview v1 authorization.k8s.io
  - ServiceAccount v1 core
  - SubjectAccessReview v1 authorization.k8s.io
  - TokenRequest v1 authentication.k8s.io
  - TokenReview v1 authentication.k8s.io
  - NetworkPolicy v1 networking.k8s.io
- DEFINITIONS
- OLD API VERSIONS
  - APIService v1beta1 apiregistration.k8s.io
  - APIServiceCondition v1beta1 apiregistration.k8s.io
  - AggregationRule v1beta1 rbac.authorization.k8s.io
  - AggregationRule v1alpha1 rbac.authorization.k8s.io
  - AllowedCSIDriver v1beta1 extensions
  - AllowedFlexVolume v1beta1 extensions
  - AllowedHostPath v1beta1 extensions
  - ClusterRole v1beta1 rbac.authorization.k8s.io
  - ClusterRole v1alpha1 rbac.authorization.k8s.io
  - ClusterRoleBinding v1beta1 rbac.authorization.k8s.io
  - ClusterRoleBinding v1alpha1 rbac.authorization.k8s.io
  - ControllerRevision v1beta2 apps
  - ControllerRevision v1beta1 apps
  - CronJob v2alpha1 batch
  - CrossVersionObjectReference v2beta2 autoscaling
  - CrossVersionObjectReference v2beta1 autoscaling
  - CustomResourceColumnDefinition v1beta1 apiextensions.k8s.io
  - CustomResourceConversion v1beta1 apiextensions.k8s.io
  - CustomResourceDefinition v1beta1 apiextensions.k8s.io
  - CustomResourceDefinitionCondition v1beta1 apiextensions.k8s.io
  - CustomResourceDefinitionNames v1beta1 apiextensions.k8s.io
  - CustomResourceDefinitionVersion v1beta1 apiextensions.k8s.io
  - CustomResourceSubresourceScale v1beta1 apiextensions.k8s.io
  - CustomResourceSubresourceStatus v1beta1 apiextensions.k8s.io
  - CustomResourceSubresources v1beta1 apiextensions.k8s.io
  - CustomResourceValidation v1beta1 apiextensions.k8s.io
  - DaemonSet v1beta2 apps
  - DaemonSet v1beta1 extensions
  - DaemonSetCondition v1beta2 apps
  - DaemonSetCondition v1beta1 extensions
  - DaemonSetUpdateStrategy v1beta2 apps
  - DaemonSetUpdateStrategy v1beta1 extensions
  - Deployment v1beta2 apps
  - Deployment v1beta1 apps
  - Deployment v1beta1 extensions
  - DeploymentCondition v1beta2 apps
  - DeploymentCondition v1beta1 apps
  - DeploymentCondition v1beta1 extensions
  - EndpointPort v1alpha1 discovery.k8s.io
  - Event v1beta1 events.k8s.io
  - EventSeries v1beta1 events.k8s.io
  - ExternalDocumentation v1beta1 apiextensions.k8s.io
  - ExternalMetricSource v2beta1 autoscaling
  - ExternalMetricStatus v2beta1 autoscaling
  - FSGroupStrategyOptions v1beta1 extensions
  - HTTPIngressPath v1beta1 extensions
  - HTTPIngressRuleValue v1beta1 extensions
  - HorizontalPodAutoscaler v2beta2 autoscaling
  - HorizontalPodAutoscaler v2beta1 autoscaling
  - HorizontalPodAutoscalerCondition v2beta1 autoscaling
  - HostPortRange v1beta1 extensions
  - IDRange v1beta1 extensions
  - IPBlock v1beta1 extensions
  - Ingress v1beta1 extensions
  - IngressBackend v1beta1 extensions
  - IngressRule v1beta1 extensions
  - IngressTLS v1beta1 extensions
  - JSON v1beta1 apiextensions.k8s.io
  - JSONSchemaProps v1beta1 apiextensions.k8s.io
  - JSONSchemaPropsOrArray v1beta1 apiextensions.k8s.io
  - JSONSchemaPropsOrBool v1beta1 apiextensions.k8s.io
  - JobTemplateSpec v2alpha1 batch
  - Lease v1beta1 coordination.k8s.io
  - LocalSubjectAccessReview v1beta1 authorization.k8s.io
  - MetricSpec v2beta1 autoscaling
  - MetricStatus v2beta1 autoscaling
  - MutatingWebhook v1beta1 admissionregistration.k8s.io
  - MutatingWebhookConfiguration v1beta1 admissionregistration.k8s.io
  - NetworkPolicy v1beta1 extensions
  - NetworkPolicyEgressRule v1beta1 extensions
  - NetworkPolicyIngressRule v1beta1 extensions
  - NetworkPolicyPeer v1beta1 extensions
  - NetworkPolicyPort v1beta1 extensions
  - NonResourceAttributes v1beta1 authorization.k8s.io
  - NonResourceRule v1beta1 authorization.k8s.io
  - ObjectMetricSource v2beta1 autoscaling
  - ObjectMetricStatus v2beta1 autoscaling
  - Overhead v1alpha1 node.k8s.io
  - PodSecurityPolicy v1beta1 extensions
  - PodsMetricSource v2beta1 autoscaling
  - PodsMetricStatus v2beta1 autoscaling
  - PolicyRule v1beta1 rbac.authorization.k8s.io
  - PolicyRule v1alpha1 rbac.authorization.k8s.io
  - PriorityClass v1beta1 scheduling.k8s.io
  - PriorityClass v1alpha1 scheduling.k8s.io
  - ReplicaSet v1beta2 apps
  - ReplicaSet v1beta1 extensions
  - ReplicaSetCondition v1beta2 apps
  - ReplicaSetCondition v1beta1 extensions
  - ResourceAttributes v1beta1 authorization.k8s.io
  - ResourceMetricSource v2beta1 autoscaling
  - ResourceMetricStatus v2beta1 autoscaling
  - ResourceRule v1beta1 authorization.k8s.io
  - Role v1beta1 rbac.authorization.k8s.io
  - Role v1alpha1 rbac.authorization.k8s.io
  - RoleBinding v1beta1 rbac.authorization.k8s.io
  - RoleBinding v1alpha1 rbac.authorization.k8s.io
  - RoleRef v1beta1 rbac.authorization.k8s.io
  - RoleRef v1alpha1 rbac.authorization.k8s.io
  - RollbackConfig v1beta1 extensions
  - RollingUpdateStatefulSetStrategy v1beta2 apps
  - RollingUpdateStatefulSetStrategy v1beta1 apps
  - RuleWithOperations v1beta1 admissionregistration.k8s.io
  - RunAsGroupStrategyOptions v1beta1 extensions
  - RunAsUserStrategyOptions v1beta1 extensions
  - RuntimeClass v1alpha1 node.k8s.io
  - RuntimeClassStrategyOptions v1beta1 extensions
  - SELinuxStrategyOptions v1beta1 extensions
  - Scale v1 autoscaling
  - Scale v1beta1 apps
  - Scale v1beta1 extensions
  - Scheduling v1alpha1 node.k8s.io
  - SelfSubjectAccessReview v1beta1 authorization.k8s.io
  - SelfSubjectRulesReview v1beta1 authorization.k8s.io
  - ServiceReference v1 apiextensions.k8s.io
  - ServiceReference v1 apiregistration.k8s.io
  - ServiceReference v1beta1 admissionregistration.k8s.io
  - ServiceReference v1beta1 apiextensions.k8s.io
  - ServiceReference v1beta1 apiregistration.k8s.io
  - ServiceReference v1alpha1 auditregistration.k8s.io
  - StatefulSet v1beta2 apps
  - StatefulSet v1beta1 apps
  - StatefulSetCondition v1beta2 apps
  - StatefulSetCondition v1beta1 apps
  - StatefulSetUpdateStrategy v1beta2 apps
  - StatefulSetUpdateStrategy v1beta1 apps
  - StorageClass v1beta1 storage.k8s.io
  - Subject v1beta1 rbac.authorization.k8s.io
  - Subject v1alpha1 rbac.authorization.k8s.io
  - SubjectAccessReview v1beta1 authorization.k8s.io
  - SubjectRulesReviewStatus v1beta1 authorization.k8s.io
  - SupplementalGroupsStrategyOptions v1beta1 extensions
  - TokenReview v1beta1 authentication.k8s.io
  - UserInfo v1beta1 authentication.k8s.io
  - ValidatingWebhook v1beta1 admissionregistration.k8s.io
  - ValidatingWebhookConfiguration v1beta1 admissionregistration.k8s.io
  - VolumeAttachment v1beta1 storage.k8s.io
  - VolumeAttachment v1alpha1 storage.k8s.io
  - VolumeAttachmentSource v1beta1 storage.k8s.io
  - VolumeAttachmentSource v1alpha1 storage.k8s.io
  - VolumeError v1beta1 storage.k8s.io
  - VolumeError v1alpha1 storage.k8s.io
  - WebhookClientConfig v1 apiextensions.k8s.io
  - WebhookClientConfig v1beta1 admissionregistration.k8s.io
  - WebhookClientConfig v1beta1 apiextensions.k8s.io
  - WebhookClientConfig v1alpha1 auditregistration.k8s.io

------

## K8S API v1.6 Overview (Sorted)

[official api documents](https://v1-16.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.16/)
[official changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.16.md#deprecations-and-removals)

### API Deprecations

  - The following APIs are no longer served by default:

    - All resources under `apps/v1beta1` and `apps/v1beta2` - use `apps/v1` instead
    - `daemonsets`, `deployments`, `replicasets` resources under `extensions/v1beta1` - use `apps/v1` instead
    - `networkpolicies` resources under `extensions/v1beta1` - use `networking.k8s.io/v1` instead
    - `podsecuritypolicies` resources under `extensions/v1beta1` - use `policy/v1beta1` instead

    Serving these resources can be temporarily re-enabled using the `--runtime-config` apiserver flag.

    - `apps/v1beta1=true`
    - `apps/v1beta2=true`
    - `extensions/v1beta1/daemonsets=true,extensions/v1beta1/deployments=true,extensions/v1beta1/replicasets=true,extensions/v1beta1/networkpolicies=true,extensions/v1beta1/podsecuritypolicies=true`

    The ability to serve these resources will be completely removed in v1.18. ([#70672](https://github.com/kubernetes/kubernetes/pull/70672), [@liggitt](https://github.com/liggitt))

  - Ingress resources will no longer be served from `extensions/v1beta1` in v1.20. Migrate use to the `networking.k8s.io/v1beta1` API, available since v1.14. Existing persisted data can be retrieved via the `networking.k8s.io/v1beta1` API.
  - PriorityClass resources will no longer be served from `scheduling.k8s.io/v1beta1` and `scheduling.k8s.io/v1alpha1` in v1.17. Migrate to the `scheduling.k8s.io/v1` API, available since v1.14. Existing persisted data can be retrieved via the `scheduling.k8s.io/v1` API.
  - The `export` query parameter for list API calls, deprecated since v1.14, will be removed in v1.18.
  - The `series.state` field in the events.k8s.io/v1beta1 Event API is deprecated and will be removed in v1.18 ([#75987](https://github.com/kubernetes/kubernetes/pull/75987), [@yastij](https://github.com/yastij))
  - The `apiextensions.k8s.io/v1beta1` version of `CustomResourceDefinition` is deprecated and will no longer be served in v1.19. Use `apiextensions.k8s.io/v1` instead. ([#79604](https://github.com/kubernetes/kubernetes/pull/79604), [@liggitt](https://github.com/liggitt))
  - The `admissionregistration.k8s.io/v1beta1` versions of `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration` are deprecated and will no longer be served in v1.19. Use `admissionregistration.k8s.io/v1` instead. ([#79549](https://github.com/kubernetes/kubernetes/pull/79549), [@liggitt](https://github.com/liggitt))
  - The alpha `metadata.initializers` field, deprecated in 1.13, has been removed. ([#79504](https://github.com/kubernetes/kubernetes/pull/79504), [@yue9944882](https://github.com/yue9944882))
  - The deprecated node condition type `OutOfDisk` has been removed. Use the `DiskPressure` condition instead. ([#72420](https://github.com/kubernetes/kubernetes/pull/72420), [@Pingan2017](https://github.com/Pingan2017))
  - The `metadata.selfLink` field is deprecated in individual and list objects. It will no longer be returned starting in v1.20, and the field will be removed entirely in v1.21. ([#80978](https://github.com/kubernetes/kubernetes/pull/80978), [@wojtek-t](https://github.com/wojtek-t))
  - The deprecated cloud providers `ovirt`, `cloudstack` and `photon` have been removed ([#72178](https://github.com/kubernetes/kubernetes/pull/72178), [@dims](https://github.com/dims))
  - The `Cinder` and `ScaleIO` volume providers have been deprecated and will be removed in a future release. ([#80099](https://github.com/kubernetes/kubernetes/pull/80099), [@dims](https://github.com/dims))
  - The GA `PodPriority` feature gate is now on by default and cannot be disabled. The feature gate will be removed in v1.18. ([#79262](https://github.com/kubernetes/kubernetes/pull/79262), [@draveness](https://github.com/draveness))
  - Aggregated discovery requests can now timeout. Aggregated API servers must complete discovery calls within 5 seconds (other requests can take longer). Use the feature gate `EnableAggregatedDiscoveryTimeout=false` to temporarily revert behavior to the previous 30 second timeout if required (the temporary `EnableAggregatedDiscoveryTimeout` feature gate will be removed in v1.17). ([#82146](https://github.com/kubernetes/kubernetes/pull/82146), [@deads2k](https://github.com/deads2k))
  - the `scheduler.alpha.kubernetes.io/critical-pod` annotation is removed. Pod priority (`spec.priorityClassName`) should be used instead to mark pods as critical. ([#80342](https://github.com/kubernetes/kubernetes/pull/80342), [@draveness](https://github.com/draveness))
  - the NormalizeScore plugin set is removed from scheduler framework config API. Use ScorePlugin only. ([#80930](https://github.com/kubernetes/kubernetes/pull/80930), [@liu-cong](https://github.com/liu-cong))
  - the node label `alpha.service-controller.kubernetes.io/exclude-balancer` which excludes a node from cloud load balancers (using Service Type=LoadBalancer) is deprecated in favor of `node.kubernetes.io/exclude-balancer`. Support for `alpha.service-controller.kubernetes.io/exclude-balancer` will be removed in v1.18.

### API list

| API name | Version | Group | Deprecated |
| :--- | :---: | :---:| :---: |
| AggregationRule | v1alpha1 | rbac.authorization.k8s.io |  |
| AggregationRule | v1beta1 | rbac.authorization.k8s.io |  |
| AllowedCSIDriver | v1beta1 | extensions |  |
| AllowedFlexVolume | v1beta1 | extensions |  |
| AllowedHostPath | v1beta1 | extensions |  |
| APIService | v1 | apiregistration.k8s.io |  |
| APIService | v1beta1 | apiregistration.k8s.io |  |
| APIServiceCondition | v1beta1 | apiregistration.k8s.io |  |
| AuditSink | v1alpha1 | auditregistration.k8s.io |  |
| Binding | v1 | core |  |
| CertificateSigningRequest | v1beta1 | certificates.k8s.io |  |
| ClusterRole | v1 | rbac.authorization.k8s.io |  |
| ClusterRole | v1alpha1 | rbac.authorization.k8s.io |  |
| ClusterRole | v1beta1 | rbac.authorization.k8s.io |  |
| ClusterRoleBinding | v1 | rbac.authorization.k8s.io |  |
| ClusterRoleBinding | v1alpha1 | rbac.authorization.k8s.io |  |
| ClusterRoleBinding | v1beta1 | rbac.authorization.k8s.io |  |
| ComponentStatus | v1 | core |  |
| ConfigMap | v1 | core |  |
| Container | v1 | core |  |
| ControllerRevision | v1 | apps |  |
| ControllerRevision | v1beta1 | apps | not served by default |
| ControllerRevision | v1beta2 | apps | not served by default |
| CronJob | v1beta1 | batch |  |
| CronJob | v2alpha1 | batch |  |
| CrossVersionObjectReference | v2beta1 | autoscaling |  |
| CrossVersionObjectReference | v2beta2 | autoscaling |  |
| CSIDriver | v1beta1 | storage.k8s.io |  |
| CSINode | v1beta1 | storage.k8s.io |  |
| CustomResourceColumnDefinition | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceConversion | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceDefinition | v1 | apiextensions.k8s.io |  |
| CustomResourceDefinition | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceDefinitionCondition | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceDefinitionNames | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceDefinitionVersion | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceSubresources | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceSubresourceScale | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceSubresourceStatus | v1beta1 | apiextensions.k8s.io |  |
| CustomResourceValidation | v1beta1 | apiextensions.k8s.io |  |
| DaemonSet | v1 | apps |  |
| DaemonSet | v1beta1 | extensions | not served by default |
| DaemonSet | v1beta2 | apps | not served by default |
| DaemonSetCondition | v1 | apps |  |
| DaemonSetCondition | v1beta1 | extensions | not served by default |
| DaemonSetCondition | v1beta2 | apps | not served by default |
| DaemonSetUpdateStrategy | v1 | apps |  |
| DaemonSetUpdateStrategy | v1beta1 | extensions | not served by default |
| DaemonSetUpdateStrategy | v1beta2 | apps | not served by default |
| Deployment | v1 | apps |  |
| Deployment | v1beta1 | apps | not served by default |
| Deployment | v1beta1 | extensions | not served by default |
| Deployment | v1beta2 | apps | not served by default |
| DeploymentCondition | v1 | apps |  |
| DeploymentCondition | v1beta1 | apps | not served by default |
| DeploymentCondition | v1beta1 | extensions | not served by default |
| DeploymentCondition | v1beta2 | apps | not served by default |
| EndpointPort | v1alpha1 | discovery.k8s.io |  |
| Endpoints | v1 | core |  |
| EndpointSlice | v1alpha1 | discovery.k8s.io |  |
| Event | v1 | core |  |
| Event | v1beta1 | events.k8s.io |  |
| EventSeries | v1beta1 | events.k8s.io |  |
| ExternalDocumentation | v1beta1 | apiextensions.k8s.io |  |
| ExternalMetricSource | v2beta1 | autoscaling |  |
| ExternalMetricStatus | v2beta1 | autoscaling |  |
| FSGroupStrategyOptions | v1beta1 | extensions |  |
| HorizontalPodAutoscaler | v1 | autoscaling |  |
| HorizontalPodAutoscaler | v2beta1 | autoscaling |  |
| HorizontalPodAutoscaler | v2beta2 | autoscaling |  |
| HorizontalPodAutoscalerCondition | v2beta1 | autoscaling |  |
| HostPortRange | v1beta1 | extensions |  |
| HTTPIngressPath | v1beta1 | extensions |  |
| HTTPIngressRuleValue | v1beta1 | extensions |  |
| IDRange | v1beta1 | extensions |  |
| Ingress | v1beta1 | extensions |  |
| Ingress | v1beta1 | networking.k8s.io |  |
| IngressBackend | v1beta1 | extensions |  |
| IngressRule | v1beta1 | extensions |  |
| IngressTLS | v1beta1 | extensions |  |
| IPBlock | v1beta1 | extensions |  |
| Job | v1 | batch |  |
| JobTemplateSpec | v2alpha1 | batch |  |
| JSON | v1beta1 | apiextensions.k8s.io |  |
| JSONSchemaProps | v1beta1 | apiextensions.k8s.io |  |
| JSONSchemaPropsOrArray | v1beta1 | apiextensions.k8s.io |  |
| JSONSchemaPropsOrBool | v1beta1 | apiextensions.k8s.io |  |
| Lease | v1 | coordination.k8s.io |  |
| Lease | v1beta1 | coordination.k8s.io |  |
| LimitRange | v1 | core |  |
| LocalSubjectAccessReview | v1 | authorization.k8s.io |  |
| LocalSubjectAccessReview | v1beta1 | authorization.k8s.io |  |
| MetricSpec | v2beta1 | autoscaling |  |
| MetricStatus | v2beta1 | autoscaling |  |
| MutatingWebhook | v1beta1 | admissionregistration.k8s.io |  |
| MutatingWebhookConfiguration | v1 | admissionregistration.k8s.io |  |
| MutatingWebhookConfiguration | v1beta1 | admissionregistration.k8s.io |  |
| Namespace | v1 | core |  |
| NetworkPolicy | v1 | networking.k8s.io |  |
| NetworkPolicy | v1beta1 | extensions | not served by default |
| NetworkPolicyEgressRule | v1 | networking.k8s.io |  |
| NetworkPolicyEgressRule | v1beta1 | extensions | not served by default |
| NetworkPolicyIngressRule | v1 | networking.k8s.io |  |
| NetworkPolicyIngressRule | v1beta1 | extensions | not served by default |
| NetworkPolicyPeer | v1 | networking.k8s.io |  |
| NetworkPolicyPeer | v1beta1 | extensions | not served by default |
| NetworkPolicyPort | v1 | networking.k8s.io |  |
| NetworkPolicyPort | v1beta1 | extensions | not served by default |
| Node | v1 | core |  |
| NonResourceAttributes | v1beta1 | authorization.k8s.io |  |
| NonResourceRule | v1beta1 | authorization.k8s.io |  |
| ObjectMetricSource | v2beta1 | autoscaling |  |
| ObjectMetricStatus | v2beta1 | autoscaling |  |
| Overhead | v1alpha1 | node.k8s.io |  |
| PersistentVolume | v1 | core |  |
| PersistentVolumeClaim | v1 | core |  |
| Pod | v1 | core |  |
| PodDisruptionBudget | v1beta1 | policy |  |
| PodPreset | v1alpha1 | settings.k8s.io |  |
| PodSecurityPolicy | v1beta1 | extensions | not served by default |
| PodSecurityPolicy | v1beta1 | policy |  |
| PodsMetricSource | v2beta1 | autoscaling |  |
| PodsMetricStatus | v2beta1 | autoscaling |  |
| PodTemplate | v1 | core |  |
| PolicyRule | v1alpha1 | rbac.authorization.k8s.io |  |
| PolicyRule | v1beta1 | rbac.authorization.k8s.io |  |
| PriorityClass | v1 | scheduling.k8s.io |  |
| PriorityClass | v1alpha1 | scheduling.k8s.io |  |
| PriorityClass | v1beta1 | scheduling.k8s.io |  |
| ReplicaSet | v1 | apps |  |
| ReplicaSet | v1beta1 | extensions | not served by default |
| ReplicaSet | v1beta2 | apps | not served by default |
| ReplicaSetCondition | v1 | apps |  |
| ReplicaSetCondition | v1beta1 | extensions | not served by default |
| ReplicaSetCondition | v1beta2 | apps | not served by default |
| ReplicationController | v1 | core |  |
| ResourceAttributes | v1beta1 | authorization.k8s.io |  |
| ResourceMetricSource | v2beta1 | autoscaling |  |
| ResourceMetricStatus | v2beta1 | autoscaling |  |
| ResourceQuota | v1 | core |  |
| ResourceRule | v1beta1 | authorization.k8s.io |  |
| Role | v1 | rbac.authorization.k8s.io |  |
| Role | v1alpha1 | rbac.authorization.k8s.io |  |
| Role | v1beta1 | rbac.authorization.k8s.io |  |
| RoleBinding | v1 | rbac.authorization.k8s.io |  |
| RoleBinding | v1alpha1 | rbac.authorization.k8s.io |  |
| RoleBinding | v1beta1 | rbac.authorization.k8s.io |  |
| RoleRef | v1alpha1 | rbac.authorization.k8s.io |  |
| RoleRef | v1beta1 | rbac.authorization.k8s.io |  |
| RollbackConfig | v1beta1 | extensions |  |
| RollingUpdateStatefulSetStrategy | v1 | apps |  |
| RollingUpdateStatefulSetStrategy | v1beta1 | apps | not served by default |
| RollingUpdateStatefulSetStrategy | v1beta2 | apps | not served by default |
| RuleWithOperations | v1beta1 | admissionregistration.k8s.io |  |
| RunAsGroupStrategyOptions | v1beta1 | extensions |  |
| RunAsUserStrategyOptions | v1beta1 | extensions |  |
| RuntimeClass | v1alpha1 | node.k8s.io |  |
| RuntimeClass | v1beta1 | node.k8s.io |  |
| RuntimeClassStrategyOptions | v1beta1 | extensions |  |
| Scale | v1 | autoscaling |  |
| Scale | v1beta1 | apps | not served by default |
| Scale | v1beta1 | extensions |  |
| Scale | v1beta2 | apps | not served by default |
| Scheduling | v1alpha1 | node.k8s.io |  |
| Secret | v1 | core |  |
| SelfSubjectAccessReview | v1 | authorization.k8s.io |  |
| SelfSubjectAccessReview | v1beta1 | authorization.k8s.io |  |
| SelfSubjectRulesReview | v1 | authorization.k8s.io |  |
| SelfSubjectRulesReview | v1beta1 | authorization.k8s.io |  |
| SELinuxStrategyOptions | v1beta1 | extensions |  |
| Service | v1 | core |  |
| ServiceAccount | v1 | core |  |
| ServiceReference | v1 | apiextensions.k8s.io |  |
| ServiceReference | v1 | apiregistration.k8s.io |  |
| ServiceReference | v1alpha1 | auditregistration.k8s.io |  |
| ServiceReference | v1beta1 | admissionregistration.k8s.io |  |
| ServiceReference | v1beta1 | apiextensions.k8s.io |  |
| ServiceReference | v1beta1 | apiregistration.k8s.io |  |
| StatefulSet | v1 | apps |  |
| StatefulSet | v1beta1 | apps | not served by default |
| StatefulSet | v1beta2 | apps | not served by default |
| StatefulSetCondition | v1 | apps |  |
| StatefulSetCondition | v1beta1 | apps | not served by default |
| StatefulSetCondition | v1beta2 | apps | not served by default |
| StatefulSetUpdateStrategy | v1 | apps |  |
| StatefulSetUpdateStrategy | v1beta1 | apps | not served by default |
| StatefulSetUpdateStrategy | v1beta2 | apps | not served by default |
| StorageClass | v1 | storage.k8s.io |  |
| StorageClass | v1beta1 | storage.k8s.io |  |
| Subject | v1alpha1 | rbac.authorization.k8s.io |  |
| Subject | v1beta1 | rbac.authorization.k8s.io |  |
| SubjectAccessReview | v1 | authorization.k8s.io |  |
| SubjectAccessReview | v1beta1 | authorization.k8s.io |  |
| SubjectRulesReviewStatus | v1beta1 | authorization.k8s.io |  |
| SupplementalGroupsStrategyOptions | v1beta1 | extensions |  |
| TokenRequest | v1 | authentication.k8s.io |  |
| TokenReview | v1 | authentication.k8s.io |  |
| TokenReview | v1beta1 | authentication.k8s.io |  |
| UserInfo | v1beta1 | authentication.k8s.io |  |
| ValidatingWebhook | v1beta1 | admissionregistration.k8s.io |  |
| ValidatingWebhookConfiguration | v1 | admissionregistration.k8s.io |  |
| ValidatingWebhookConfiguration | v1beta1 | admissionregistration.k8s.io |  |
| Volume | v1 | core |  |
| VolumeAttachment | v1 | storage.k8s.io |  |
| VolumeAttachment | v1alpha1 | storage.k8s.io |  |
| VolumeAttachment | v1beta1 | storage.k8s.io |  |
| VolumeAttachmentSource | v1alpha1 | storage.k8s.io |  |
| VolumeAttachmentSource | v1beta1 | storage.k8s.io |  |
| VolumeError | v1alpha1 | storage.k8s.io |  |
| VolumeError | v1beta1 | storage.k8s.io |  |
| WebhookClientConfig | v1 | apiextensions.k8s.io |  |
| WebhookClientConfig | v1alpha1 | auditregistration.k8s.io |  |
| WebhookClientConfig | v1beta1 | admissionregistration.k8s.io |  |
| WebhookClientConfig | v1beta1 | apiextensions.k8s.io |  |
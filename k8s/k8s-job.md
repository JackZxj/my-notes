# k8s job

## restart a job

ref: https://jvnior.com/post/2020-08-04-restart-job-in-kubernetes/

```BASH
$ kubectl get job my-job -n my-namespace -o json |
  jq 'del(.spec.selector)' |
  jq 'del(.spec.template.metadata.labels)' |
  kubectl replace --force -f -
```

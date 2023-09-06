# helm usage

## upgrade or install

```BASH
$ helm upgrade --install RELEASE_NAME CHART -n NAMESPACE --create-namespace --set xx=xx 
```

## create resource if not exist

* https://helm.sh/zh/docs/chart_template_guide/functions_and_pipelines/#%E4%BD%BF%E7%94%A8lookup%E5%87%BD%E6%95%B0

note: 

* `lookup` should not used in template yamls, it might cause an unexpected deletion when upgrading

expample: 

```yaml
# templates/_helper.tpl
{{- define "testchart.iscm" -}}
{{- if (lookup "v1" "ConfigMap" "default" "aa") }}
"aa"
{{- end }}
{{- end }}


# templates/configmap.yaml
{{ if ne "testchart.iscm" "aa" }}
apiVersion: v1
data:
  aa: aaa
kind: ConfigMap
metadata:
  name: aa
  namespace: default
{{- end }}
```
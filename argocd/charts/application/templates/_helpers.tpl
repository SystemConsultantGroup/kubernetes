{{- define "application.commonLabels" -}}
app.kubernetes.io/name: {{ .workload | quote }}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/part-of: {{ .root.Values._context.application | quote }}
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
platform.scg.sh/instance-type: {{ .root.Values._context.instance.type | quote }}
{{- end }}

{{- define "application.resourceName" -}}
{{- $limit := .limit | default 63 | int -}}
{{- $name := .name | trimSuffix "-" -}}
{{- if le (len $name) $limit -}}
{{- $name -}}
{{- else -}}
{{- $hash := sha256sum $name | trunc 8 -}}
{{- $prefixLimit := sub $limit 9 | int -}}
{{- printf "%s-%s" ($name | trunc $prefixLimit | trimSuffix "-") $hash -}}
{{- end -}}
{{- end }}

{{- define "application.workloadName" -}}
{{- include "application.resourceName" (dict "name" (printf "%s-%s" .root.Values._context.application .workload)) -}}
{{- end }}

{{- define "application.secretName" -}}
{{- include "application.resourceName" (dict "name" (printf "%s-%s-environment" .root.Values._context.application .workload)) -}}
{{- end }}

{{- define "application.testingNamespace" -}}
{{- printf "%s-testing" .Values._context.application -}}
{{- end }}

{{- define "application.previewHostname" -}}
{{- $label := include "application.resourceName" (dict "name" (printf "%s-%s-%v" .Values._context.application .Values._context.instance.workload .Values._context.instance.pullRequest)) -}}
{{- printf "%s.preview.scg.sh" $label -}}
{{- end }}

{{- define "application.testingHostname" -}}
{{- printf "%s.testing.scg.sh" .Values._context.application -}}
{{- end }}

{{- define "application.redirectOnly" -}}
{{- $redirect := false -}}
{{- range (.filters | default (list)) -}}
  {{- if eq .type "RequestRedirect" -}}
    {{- $redirect = true -}}
  {{- end -}}
{{- end -}}
{{- $redirect -}}
{{- end }}

{{- define "application.rules" -}}
{{- $root := .root -}}
{{- $workloads := .workloads -}}
{{- $instanceType := $root.Values._context.instance.type -}}
{{- $previewWorkload := $root.Values._context.instance.workload | default "" -}}
{{- $testingNamespace := include "application.testingNamespace" $root -}}
{{- range $group := .groups -}}
  {{- $owner := $group.owner -}}
  {{- $rules := $group.http.rules | default (list (dict)) -}}
  {{- range $index, $original := $rules -}}
    {{- $rule := deepCopy $original -}}
    {{- if not (hasKey $rule "name") -}}
      {{- $_ := set $rule "name" (printf "%s-%s-%d" $root.Values._context.application $owner (add1 $index)) -}}
    {{- end -}}
    {{- if not (hasKey $rule "backendRefs") -}}
      {{- if ne (include "application.redirectOnly" $rule) "true" -}}
        {{- $_ := set $rule "backendRefs" (list (dict "name" $owner "port" 80)) -}}
      {{- end -}}
    {{- end -}}
    {{- if hasKey $rule "backendRefs" -}}
      {{- $backends := list -}}
      {{- range $originalBackend := $rule.backendRefs -}}
        {{- $backend := deepCopy $originalBackend -}}
        {{- $groupName := get $backend "group" | default "" -}}
        {{- $kind := get $backend "kind" | default "Service" -}}
        {{- $name := get $backend "name" | default "" -}}
        {{- if and (eq $groupName "") (eq $kind "Service") (hasKey $workloads $name) (not (hasKey $backend "namespace")) -}}
          {{- $_ := set $backend "name" (include "application.workloadName" (dict "root" $root "workload" $name)) -}}
          {{- if not (hasKey $backend "port") -}}
            {{- $_ := set $backend "port" 80 -}}
          {{- end -}}
          {{- if and (eq $instanceType "preview") (ne $name $previewWorkload) -}}
            {{- $_ := set $backend "namespace" $testingNamespace -}}
          {{- end -}}
        {{- end -}}
        {{- $backends = append $backends $backend -}}
      {{- end -}}
      {{- $_ := set $rule "backendRefs" $backends -}}
    {{- end -}}
- {{ toYaml $rule | nindent 2 | trim }}
{{ end }}
{{ end }}
{{- end }}

{{- define "application.injectionForRule" -}}
{{- $root := .root -}}
{{- $workloads := .workloads -}}
{{- $owner := .owner -}}
{{- $rule := .rule -}}
{{- $inject := "" -}}
{{- if hasKey $rule "backendRefs" -}}
  {{- range $backend := $rule.backendRefs -}}
    {{- $groupName := get $backend "group" | default "" -}}
    {{- $kind := get $backend "kind" | default "Service" -}}
    {{- $name := get $backend "name" | default "" -}}
    {{- if and (eq $groupName "") (eq $kind "Service") (hasKey $workloads $name) (not (hasKey $backend "namespace")) -}}
      {{- $target := get $workloads $name -}}
      {{- if and $target.http (hasKey $target.http "inject") -}}
        {{- $candidate := $target.http.inject | toString -}}
        {{- if and (ne $inject "") (ne $inject $candidate) -}}
          {{- fail (printf "HTTPRoute rule has multiple different injection configurations: %s" $owner) -}}
        {{- end -}}
        {{- $inject = $candidate -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- else if hasKey $workloads $owner -}}
  {{- $target := get $workloads $owner -}}
  {{- if and $target.http (hasKey $target.http "inject") -}}
    {{- $inject = $target.http.inject | toString -}}
  {{- end -}}
{{- end -}}
{{- $inject -}}
{{- end }}

{{- define "application.envoyExtensionPolicy" -}}
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyExtensionPolicy
metadata:
  name: {{ .name }}
  labels:
    {{- include "application.commonLabels" (dict "root" .root "workload" .owner) | nindent 4 }}
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: {{ .routeName }}
      sectionName: {{ .ruleName }}
  wasm:
    - name: envoy-html-injector
      rootID: envoy-html-injector
      failOpen: false
      code:
        type: HTTP
        http:
          url: {{ .root.Values._context.htmlInjector.wasm.url | quote }}
          sha256: {{ .root.Values._context.htmlInjector.wasm.sha256 | quote }}
      config: {{ .inject | toJson }}
{{- end }}

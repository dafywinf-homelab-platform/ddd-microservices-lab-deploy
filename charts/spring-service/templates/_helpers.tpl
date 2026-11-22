{{/* The release name is the service name, e.g. order-service */}}
{{- define "spring-service.name" -}}
{{- .Release.Name -}}
{{- end -}}

{{/* The version without its digest, for the version label: 1.1.0@sha256:... -> 1.1.0 */}}
{{- define "spring-service.version" -}}
{{- splitList "@" .Values.image.tag | first -}}
{{- end -}}

{{- define "spring-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spring-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "spring-service.labels" -}}
{{ include "spring-service.selectorLabels" . }}
app.kubernetes.io/version: {{ include "spring-service.version" . | quote }}
app.kubernetes.io/part-of: ddd-microservices-lab
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

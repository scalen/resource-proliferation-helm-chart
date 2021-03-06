{{/*
Expand the name of the chart.
*/}}
{{- define "various-webservers.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "various-webservers.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified base app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "various-webservers.basefullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := .Values.baseNameOverride | default .Values.nameOverride | default .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Expand the verbose name of the chart and specific server.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "various-webservers.verbosename" -}}
{{- $baseName := .Values.baseNameOverride | default .Values.nameOverride | default .Chart.Name }}
{{- $nameExtension := "" -}}
{{- range .Values.proliferationStack | default (list) -}}
{{- if .nameOverride -}}
{{- $nameExtension = "" -}}
{{- $baseName = .nameOverride -}}
{{- else -}}
{{- $nameExtension = printf "%s-%s-%s" $nameExtension .group .instance -}}
{{- end -}}
{{- end -}}
{{- printf "%s%s" $baseName $nameExtension -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "various-webservers.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "various-webservers.labels" -}}
helm.sh/chart: {{ include "various-webservers.chart" . }}
{{ include "various-webservers.selectorLabels" . }}
app.kubernetes.io/verbosename: {{ include "various-webservers.verbosename" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "various-webservers.selectorLabels" -}}
app.kubernetes.io/name: {{ include "various-webservers.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "various-webservers.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "various-webservers.basefullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* vim: set filetype=yaml: */}}
{{- /*
Helpers for creating multiple similarly-configured instances from a single set of templates.
*/ -}}


{{- define "proliferation.renderTemplatesFromDirectory" -}}
  {{- /*
  Generate the set of resources in the chart for a kind of instance, with the given instance
  context.

  Takes: list <directory> <instance context>
  */ -}}

  {{- $templatesDir := index . 0 -}}
  {{- $context := index . 1 -}}

  {{- range $path, $_ := printf "%s/[!_]*" $templatesDir | $context.Files.Glob -}}
    {{- with tpl ($context.Files.Get $path) $context -}}
---
# Source: {{ $path }}{{ with $context.Values.nameOverride }}, Kind: {{ . }}{{ end }}
{{ printf "%s\n" . }}
    {{- end -}}
  {{- end -}}
{{ end -}}


{{- define "proliferation.renderValuesForAllKinds" -}}
  {{- /*
  Generate the set of values for each kind of instance, each combining the base values and those
  from one of the entries in the specified map. Furthermore, modify the chart name override in
  each set of values toincorporate the name of the entry.

  If the specified map is not present or is empty, return the base values available.

  Takes: <top context> | list <top context> [<key>]
  Defaults:
    key: "kinds"
  */ -}}

  {{- $context := . -}}
  {{- $kindsKey := "kinds" -}}
  {{- if typeIs "[]interface {}" . -}}
    {{- $context = index . 0 -}}
    {{- if len . | eq 2 -}}
      {{- $kindsKey = index . 1 -}}
    {{- end -}}
  {{- end -}}

  {{- $allInstanceValues := list -}}
  {{- $kinds := get $context.Values $kindsKey | default (dict) | mustDeepCopy -}}
  {{- if not $kinds -}}
    {{- $allInstanceValues = mustAppend $allInstanceValues $context.Values -}}
  {{- else -}}
    {{- $commonValues := omit $context.Values $kindsKey | mustDeepCopy -}}
    {{- range $kind, $specificValues := $kinds -}}
      {{- if not (kindIs "invalid" $specificValues) -}}
        {{- /*
        Empty .Values dict, and rebuild from the combination of kind-specific values and common
        values.
        */ -}}
        {{- $instanceValues := mustMergeOverwrite (mustDeepCopy $commonValues) $specificValues -}}

        {{- /* Enumerate stack of proliferations performed to get this instance context. */ -}}
        {{- $proliferationEntry := dict "group" $kindsKey "instance" $kind -}}
        {{- $proliferationStack := $commonValues.proliferationStack | default (list) -}}
        {{- $_ := mustAppend $proliferationStack $proliferationEntry | set $instanceValues "proliferationStack" -}}

        {{- /* Set a name override for the chart in the course of processing the instance. */ -}}
        {{- $parentName := $commonValues.nameOverride | default $context.Chart.Name -}}
        {{- $_ := $instanceValues.baseNameOverride | default $parentName | set $instanceValues "baseNameOverride" -}}
        {{- if $specificValues.nameOverride -}}
          {{- $_ := set $proliferationEntry "nameOverride" $specificValues.nameOverride -}}
        {{- else -}}
          {{- $_ := printf "%s-%s" $parentName $kind | set $instanceValues "nameOverride" -}}
        {{- end -}}

        {{- $allInstanceValues = mustAppend $allInstanceValues $instanceValues -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- dict "instanceValues" $allInstanceValues | toYaml -}}
{{- end -}}


{{- define "proliferation.renderTemplatesFromDirectoryForAllKinds" -}}
  {{- /*
  Generate the set of resources from the templates in the given location for each kind of instance,
  with each context taking its values from a combination of the base values and those from one of
  the entries in the specified map. Furthermore, modify the chart name override in each context to
  incorporate the name of the entry.

  If the specified map is not present or is empty, create one set of the resources from the base
  values available.

  Takes: <top context> | list <top context> [<directory> <key>]
  Defaults:
    directory: "instance-templates"
    key: "kinds"
  */ -}}

  {{- $context := . -}}
  {{- $kindsKey := "kinds" -}}
  {{- $templatesDir := "instance-templates" -}}
  {{- if typeIs "[]interface {}" . -}}
    {{- $context = index . 0 -}}
    {{- if len . | eq 3 -}}
      {{- $kindsKey = index . 2 -}}
      {{- $templatesDir = index . 1 -}}
    {{- end -}}
  {{- end -}}

  {{- $originalValues := mustDeepCopy $context.Values -}}
  {{- range (list $context $kindsKey | include "proliferation.renderValuesForAllKinds" | fromYaml).instanceValues -}}
    {{- /*
    Empty .Values dict, and rebuild from the combination of kind-specific values and common
    values.
    */ -}}
    {{- range keys $context.Values -}}
      {{- $_ := unset $context.Values . -}}
    {{- end -}}
    {{- $_ := mustMergeOverwrite $context.Values . -}}

    {{- list $templatesDir $context | include "proliferation.renderTemplatesFromDirectory" -}}
  {{- end -}}

  {{- /* Return .Values to its original state. */ -}}
  {{- range keys $context.Values -}}
    {{- $_ := unset $context.Values . -}}
  {{- end -}}
  {{- $_ := mustMerge $context.Values $originalValues -}}
{{- end -}}

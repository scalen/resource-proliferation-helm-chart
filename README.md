# Resource Proliferation Helm Library Chart

This is a Helm library chart containing partial templates designed to enable sets of
template files within a chart to be repeated with varying effective contexts.  This can be
useful when needing to support multiple similar replicates of a set of resources alongside
common resources; it can also simply be used where the multiple resource replicates share
much of their configuration, replacing the use of multiple aliased instances of a chart in
an umbrella chart.

As an example, this chart could be used to specify once the templated Deployment, ConfigMaps
HorizontalPodAutoscalers and Secrets for a web service, then replicate those resources for a
whole set of similarly configured web services. These multiple similar web service
Deployments could be joined, in the same chart, by a single shared Ingress for exposing all
services.  This is the example available [here](/examples/various-webservers).

Of course, the replicated resources can be renderred alongside any number and kind of other
resources, such as a Deployment of, for example, a Controller, or a logging DaemonSet, etc.
Furthermore, these web service Deployments could be joined in the same chart by any number
of other sets of replicated resources.

## Installation

This chart is not currently available in a Helm chart museum or repository.  However, it
can be installed as a Git submodule directly into a parent chart's `charts` directory.
Alternatively, it could be simply cloned onto the same machine as a parent chart, then
referenced as a local dependency.

## Partial Templates

There are three partial templates made available by this library chart.  Their details are
shown in the table below.

| Name | Description | Signature |
| :--: | :---------: | :-------: |
| <a id="renderTemplatesFromDirectory" href="#renderTemplatesFromDirectory">`proliferation.renderTemplatesFromDirectory`</a> | Given a directory relative to the (parent) chart root, this partial template will first establish all partials from any files from that directory, then render all the resources from the template files in that directory whose names do not start with an underscore. The context used to render these templates is intended to be a top-level Helm-style context, though that isn't strictly necessary when using this partial template directly. On the other hand, [this template is not expected to be used directly](#renderTemplatesFromDirectory-equivalence) in most cases. | `list <directory> <context>` |
| <a id="renderValuesForAllKinds" href="#renderValuesForAllKinds">`proliferation.renderValuesForAllKinds`</a> | This partial may be given a values key located at the root of the values tree that holds the mapping of replicate instance names to the corresponding instance-specific values. Alternatively, this argument may be omitted to use the default of `kinds`.  The one required argument is a top-level Helm-style context.<br /><br />This partial will take the given context, remove the given key (e.g. `kinds`), then construct a new context for each entry in the map under that given key. In this new context, `.Values` are those of the given context merged with those of the given entry, with the entry's taking precedence. Furthermore, the `nameOverride` value in the new context is either based on the combination of the entry's unique key and the `.Chart.Name`, or an extension of the given context's `nameOverride`.  The output is the list of contexts renderred to YAML, under the single key `instanceValues` of a map, ready for conversion back to data using `fromYaml`.<br /><br />If the key specified in the arguments (or `kinds`, if not otherwise specified) is not present in the given context then a the original context is returned as the sole item in the list of contexts. | `<context> \| list <context> [<replicate values key>]` |
| <a id="renderTemplatesFromDirectoryForAllKinds" href="#renderTemplatesFromDirectoryForAllKinds">`proliferation.renderTemplatesFromDirectoryForAllKinds`</a> | This partial may be given a directory (relative to the parent chart root) from which to source template files, and a values key located at the root of the values tree that holds the mapping of replicate instance names to the corresponding instance-specific values. Alternatively, both of these arguments may be omitted to use the defaults of `instance-templates` and `kinds`.  The one required argument is a top-level Helm-style context.<br /><br />This partial will [render the values for all kinds specified in the context](#renderValuesForAllKinds), then use each set of values in turn to [render the templates from the given directory](#renderTemplatesFromDirectory).<br /><br /><a id="renderTemplatesFromDirectory-equivalence">When no kinds are specified in the given context then a single set of the resources is rendered, using the given context unchanged.  This makes it equivalent to the partial [`renderTemplatesFromDirectory`](#renderTemplatesFromDirectory).</a> | `<context> \| list <context> [<template directory> <replicate values key>]` |

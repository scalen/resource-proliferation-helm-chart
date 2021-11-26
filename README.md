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

## Behaviour and Intent

The intent of this library chart is to support the specification of repeating resources in
a manner that feels like native Helm templating:

* The top context available to a replicated template is a normal Helm context;
* The expected values are the same both for the replicated and "base"/"singleton" templates;
* Given the above, conventional partial templates defined in the base `templates` should
  work as expected (mostly, see below).

### Chart naming within replicated templates

Where templates are replicated multiple times, the notion of the chart's "name" (following
the convention of `<chart>.name` and `<chart>.fullname` partial templates, as well as
`nameOverride` and `fullnameOverride`, established by the canonical example chart) becomes
more complicated: It is often used as the base part of the name for the majority of a
chart's resources, so that the specific resource for that chart is identifiable from the
same kind of resource defined in another chart in the same release.  However, with multiple
replicates of the same resources would need separate "names"; these would most naturally be
specific to their specific context.

To this end, whenever a new context is created, the "name" according to the root context is
recorded as a new value called `baseNameOverride`; this is either the `nameOverride` in the
root context, or the name of the chart itself.  Furthemore, the `nameOverride` value is set
in each created context based on the first applicable rule in the following list:

1. If the `nameOverride` is set in the more specific context, use that exactly.
2. If the `nameOverride` is set in the more general context, use that value suffixed with
   the name of the specific context, separated by a hyphen.
3. Otherwise, use the `baseNameOverride` of the specific context, suffixed with its
   specific name, separated by a hyphen.

This will ensure that the resources in each replica of a set replicated templates will
have unique names when using the canonical `<chart>.name` and `<chart>.fullname` partial
templates.  It is advised that a `<chart>.basefullname` partial template is also created,
for referring to resources from the base `templates` directory from within a replicated
template.

Another new value called `proliferationStack` is also made available, to support more
complex naming conventions than expressed by the above rules.  This makes the full stack
of nested proliferation contexts that have contributed to the current context available,
in the form of a list of objects with attributes for the `group` and `instance` within
that group.  For example, one "specific context" produced from the given "input values"
would look like this:

_input values_:
```yaml
wheels: 2
wings: 0
vehicles:
  plane:
    nameOverride: mechanicalBird
    wings: 2
    models:
      biplane:
        wings: 4
        wheels: 3
      fighter:
        wheels: 3
      carrier:
        wheels: 12
  cars:
    wheels: 4
    models:
      morrissMinor:
        wheels: 3
      vwGolf: {}
```
_specific context_:
```yaml
wheels: 3
wings: 2
proliferationStack:
- group: vehicles
  instance: plane
  nameOverride: mechanicalBird
- group: models
  instance: fighter
```

## Installation

This chart is not currently available in a Helm chart museum or repository.  However, it
can be installed as a Git submodule directly into a parent chart's `charts` directory.
Alternatively, it could be simply cloned onto the same machine as a parent chart, then
referenced as a local dependency.  Finally, this repository can be referenced as a Helm
repository using [Helm-Git](https://github.com/aslafy-z/helm-git).

## Partial Templates

There are three partial templates made available by this library chart.  Their details are
shown in the table below.

| Name | Description | Signature |
| :--: | :---------: | :-------: |
| <a id="renderTemplatesFromDirectory" href="#renderTemplatesFromDirectory">`proliferation.renderTemplatesFromDirectory`</a> | Given a directory relative to the (parent) chart root, this partial template will first establish all partials from any files from that directory, then render all the resources from the template files in that directory whose names do not start with an underscore. The context used to render these templates is intended to be a top-level Helm-style context, though that isn't strictly necessary when using this partial template directly. On the other hand, [this template is not expected to be used directly](#renderTemplatesFromDirectory-equivalence) in most cases. | `list <directory> <context>` |
| <a id="renderValuesForAllKinds" href="#renderValuesForAllKinds">`proliferation.renderValuesForAllKinds`</a> | This partial may be given a values key located at the root of the values tree that holds the mapping of replicate instance names to the corresponding instance-specific values. Alternatively, this argument may be omitted to use the default of `kinds`.  The one required argument is a top-level Helm-style context.<br /><br />This partial will take the given context, remove the given key (e.g. `kinds`), then construct a new context for each entry in the map under that given key. In this new context, `.Values` are those of the given context merged with those of the given entry, with the entry's taking precedence. Furthermore, the `nameOverride` value in the new context is either based on the combination of the entry's unique key and the `.Chart.Name`, or an extension of the given context's `nameOverride`.  The output is the list of contexts renderred to YAML, under the single key `instanceValues` of a map, ready for conversion back to data using `fromYaml`.<br /><br />If the key specified in the arguments (or `kinds`, if not otherwise specified) is not present in the given context then a the original context is returned as the sole item in the list of contexts. | `<context> \| list <context> [<replicate values key>]` |
| <a id="renderTemplatesFromDirectoryForAllKinds" href="#renderTemplatesFromDirectoryForAllKinds">`proliferation.renderTemplatesFromDirectoryForAllKinds`</a> | This partial may be given a directory (relative to the parent chart root) from which to source template files, and a values key located at the root of the values tree that holds the mapping of replicate instance names to the corresponding instance-specific values. Alternatively, both of these arguments may be omitted to use the defaults of `instance-templates` and `kinds`.  The one required argument is a top-level Helm-style context.<br /><br />This partial will [render the values for all kinds specified in the context](#renderValuesForAllKinds), then use each set of values in turn to [render the templates from the given directory](#renderTemplatesFromDirectory).<br /><br /><a id="renderTemplatesFromDirectory-equivalence">When no kinds are specified in the given context then a single set of the resources is rendered, using the given context unchanged.  This makes it equivalent to the partial [`renderTemplatesFromDirectory`](#renderTemplatesFromDirectory).</a> | `<context> \| list <context> [<template directory> <replicate values key>]` |

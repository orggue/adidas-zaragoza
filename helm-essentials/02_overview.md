### What is Helm?

Helm has been created by Deis to:
* Manage multiple Kubernetes yaml files as one object (in a single workflow)
* Provide a templating mechanism
* Make Kubernetes easier for beginners

----

### Pros and Cons

* Pros:
 * Reach library of templates (https://kubeapps.com/)
 * Much reacher templating capabilities than Kubernetes or Openshift templates
 * Can manage state of deployments like Ansible or Puppet
 * Maintained by the CNCF
* Cons:
 * Non-native to Kubernetes

----

### Architecture

Helm has 3 major components:
* Command-line client for end users:
* Server (deployed as a pod) called `Tiller` that:
  * Interacts with the Kubernetes API server
  * Evaluates Helm packages (called `charts`)
  * Preserves the state of deployments
* Chart repository

```
helm init --upgrade # starts Tiller
helm serve          # starts repository
```

----

### Packaging

Helm has its own packaging called `Charts`:

`Kubernetes yaml files + metadata = Chart`

----


### Chart structure

```
chart/
  Chart.yaml      # chart metadata (version, creator etc)
  values.yaml     # default values for a chart
  charts/         # directly-copied dependencies (called `subcharts`)
  templates/      # templated Kubernetes manifests
  ...             # other files (e.g. .toml configuration files)
```

----

### Chart Example

Chart.yaml
```
name: nginx
description: A basic NGINX HTTP server
version: 0.1.0
keywords:
  - http
  - nginx
  - www
  - web
home: "https://github.com/kubernetes/helm"
sources:
  - "https://hub.docker.com/_/nginx/"
maintainers:
  - name: technosophos
    email: mbutcher@deis.com
```

----

### Templates

Helm template language supports:
* Scoped values and variables
* Control structures (loops, if)
* Macros (called `partials`)
* Modules (called `subcharts`)

which makes them a simple programming language

----

### Values and Variables

* Values - default values for a chart (may be overridden)
* Variable - a named reference to another object (rarely used)

----

### Functions

Helm has over 60 available functions:
* Some of them are defined by the Go template language itself
* Most of the others are part of the Sprig template library
* A few are added by Helm itself

Functions can be put into pipelines:

```
{{ .Values.favorite.food | upper | quote }}
```

----

### Example - Defining Values

* values.yaml

```
favorite:
  drink: coffee
  food: pizza
```

* (alternatively) in .toml files e.g. config1.toml:

```
message = Hello from config 1
```

----

### Example - Variables

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- $relname := .Release.Name -}}
  release: {{ $relname }}
```

results in (`helm install --dry-run --debug .`)

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: viable-badger-configmap
data:
  release: viable-badger
```

----

### Example - Functions and Pipelines

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  {{- end }}
```
results in:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: sappy-cricket-configmap
data:
  drink: "coffee"
  food: "PIZZA"
```

----

### Example - Accessing files

```
apiVersion: v1
kind: Secret
metadata:
  name: {{ .Release.Name }}-secret
type: Opaque
data:
  token: |-
    {{ .Files.Get "config1.toml" | b64enc }}
```

results in:

```
apiVersion: v1
kind: Secret
metadata:
  name: unrealized-anteater-secret
type: Opaque
data:
  token: |-
    bWVzc2FnZSA9IEhlbGxvIGZyb20gY29uZmlnIDEK
```

----

### Example - IF and RANGE

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
  {{- if eq .Values.favorite.drink "coffee"}}
  mug: true
  {{- end}}
```
results in:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: gangly-porcupine-configmap
data:
  drink: "coffee"
  food: "pizza"
  mug: true
```

----

### Partials

Partials are reusable fragments of templates (similar to macros in other languages).

----

### Example - Partial

Partials start with underscore e.g. `_helpers.tpl`:
```
{{- define "mychart_app" -}}
app_name: {{ .Chart.Name }}
app_version: "{{ .Chart.Version }}+{{ .Release.Time.Seconds }}"
{{- end -}}
```

----

### Example - Using partials

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{ include "mychart_app" . | indent 4 }}
data:
{{ include "mychart_app" . | indent 2 }}
```
results in (note the indentation):
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: jolly-dragon-configmap
  labels:
    app_name: mychart
    app_version: "0.1.0+1497228175"
data:
  app_name: mychart
  app_version: "0.1.0+1497228175"
```

----

### Subcharts

Charts can be nested. Parent chart can override values of subcharts.

Nesting requires subcharts to be physically copied to `charts/` subdirectory within the parent chart.

----

### Workflows

* Development
```
  init        initialize Helm on both client and server
  create      create a new chart with the given name
  install     install a chart archive (`--dry-run` and `--debug`)
  lint        examines a chart for possible issues
  package     package a chart directory into a chart archive
```
* Production
```
  install     install a chart archive
  list        list releases
  upgrade     upgrade a release
  history     fetch release history
  delete      given a release name, delete the release
```

### Summary


----

In this course you learned:
* Helm features, benefits, and basic use cases
* To write, deploy and centrally manage Helm charts

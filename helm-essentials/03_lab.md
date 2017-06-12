### Preparation

Before starting the excercise we need to:
1. Start MiniKube
```
minikube start
```
1. Install Helm cli - follow https://docs.helm.sh/using-helm/#install-helm
1. Start Helm Tiller
```
helm init --upgrade
```

----

### Searching

In this lab we will use community charts.

```
helm search
```

shows the list of available packages.

----

### Inspecting

Lets try to install WordPress. However before doing that lets see what are the default values of the installation.

```
helm inspect stable/wordpress

(truncated)
resources:
  requests:
    memory: 512Mi
    cpu: 300m
```

----

### Changing defaults

Let's override the amount of memory and check the resulting configuration:
```
helm install stable/wordpress \ 
--set resources.requests.memory=1024Mi --dry-run --debug

(truncated)
resources:
  requests:
    cpu: 300m
    memory: 1024Mi
```

----

### Installing
```
helm install stable/wordpress \
--set resources.requests.memory=1024Mi
```

----

### Listing

```
helm list           # should list WordPress release
kubectl get pods    # should list MariaDB and WordPress pods
```

----

### Delete

```
helm delete WORDPRESS_RELEASE    # provide here the name of release
kubectl get pods                 # pods should be terminated
```

----

You successfully tested Helm production workflow.

---
title: Kubernetes Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

### Step 1 kubectl basics

* The format of a kubectl command is:

```
kubectl [action] [resource]
```

* This performs the specified action  (like `create`, `describe`) on the specified resource (like `node`, `container`).
* Use `--help` after the command to get additional info about possible parameters
```
kubectl get nodes --help
```

---

Before we start set up `kubectl` so it uses the supplied training config

```
export KUBECONFIG=~/training-config
kubectl config get-contexts
CURRENT   NAME                                    CLUSTER                                 AUTHINFO                                NAMESPACE
*         gke_adam-k8s_europe-west1-b_cluster-1   gke_adam-k8s_europe-west1-b_cluster-1   gke_adam-k8s_europe-west1-b_cluster-1

```

---

To view the nodes in the cluster, run the `kubectl get nodes` command:
```bash
NAME                                       STATUS    AGE       VERSION
gke-cluster-1-default-pool-0989cb44-3mc2   Ready     20h       v1.6.4
gke-cluster-1-default-pool-0989cb44-533n   Ready     20h       v1.6.4
gke-cluster-1-default-pool-0989cb44-mdf5   Ready     20h       v1.6.4
```

Here we see the available nodes, just one in our case. Kubernetes will choose where to deploy our application based on the available Node resources.

---

### Step 2 deploy a simple application

Let’s run our first app on Kubernetes with the kubectl run command. The `run` command creates a new deployment for the specified container. This is the simpliest way of deploying a container.

```bash
kubectl run hello \  
 --image=gcr.io/google_containers/echoserver:1.4 \
 --port=8080

deployment "hello" created
```

---

This performed a few things:
* Searched for a suitable node.
* Scheduled the application to run on that node.
* Configured the cluster to reschedule the instance on a new node when needed.

---

### List your **Deployment**s

```bash
kubectl get deployments
NAME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hello            1         1         1            1           51s

```

We see that there is 1 **Deployment** running a single instance of your app.

---

### Step 3 View our app

By default applications are only visible inside the cluster. We can create a proxy to connect to our application.  
Find out the **Pod** name:
```
kubectl get pod
```
Create the proxy:
```bash
kubectl port-forward hello-3015430129-g95j6 8080:8080
```
We now have a connection between our host and the Kubernetes cluster.

---

### Inspect your application

With
```
kubectl get <obejct>
```
and
```
kubectl describe <object>
```
you can gather information about the status of your objects like **Pod**s, **Deployment**s, **Service**s, etc.

---

### Accessing the application

To see the output of our application, run a curl request in a new terminal window:
```bash
curl http://localhost:8080
CLIENT VALUES:
client_address=127.0.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://0.0.0.0:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=0.0.0.0:8080
user-agent=curl/7.51.0
BODY:
-no body in request-
```

---

### Expose service while creating the **Deployment**

`kubectl proxy` is meant for testing services that are not exposed. To expose the application, use a service.

Delete old **Deployment**

```
kubectl delete deployment hello
```

---

Create a new **Deployment** and a **Service**

```
kubectl run hello \
 --image=gcr.io/google_containers/echoserver:1.4 \
  --port=8080 --expose --service-overrides='{ "spec": { \
     "type": "LoadBalancer" } }'
service "hello" created
deployment "hello" created
```

This creates a new **Deployment** and a service of **type:LoadBalancer**. A random high port will be allocated to which we can connect.

---

View the **Service**:

```
kubectl get service
kubectl get svc
NAME          CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
hello         10.63.251.230   35.187.76.71   8080:31285/TCP   24s
kubernetes    10.0.0.1        <none>         443/TCP          28m
```
Access the external IP with curl:

```
curl 35.187.76.71:8080
CLIENT VALUES:
client_address=10.132.0.3
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://35.187.76.71:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=35.187.76.71:8080
user-agent=curl/7.52.1
BODY:
-no body in request-
```

---

### Cleanup

```
kubectl delete deployment,service hello
deployment "hello" deleted
service "hello" deleted
```

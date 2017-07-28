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

<<<<<<< variant A
Before we start set up `kubectl` so it uses the supplied training config

>>>>>>> variant B
Check that kubectl is configured to talk to your cluster, by running the kubectl version command:
```bash
kubectl version
####### Ancestor
Before we start we need to ensure that minikube is running:
```
minikube status
```
If it`s not running issue:
```
minikube start
```

Check that kubectl is configured to talk to your cluster, by running the kubectl version command:
```bash
kubectl version
======= end
```
export KUBECONFIG=~/training-config
kubectl config get-contexts
CURRENT   NAME                                    CLUSTER                                 AUTHINFO                                NAMESPACE
*         gke_adam-k8s_europe-west1-b_cluster-1   gke_adam-k8s_europe-west1-b_cluster-1   gke_adam-k8s_europe-west1-b_cluster-1

```

---

To view the nodes in the cluster, run the `kubectl get nodes` command:
<<<<<<< variant A
```bash
NAME                                       STATUS    AGE       VERSION
gke-cluster-1-default-pool-0989cb44-3mc2   Ready     20h       v1.6.4
gke-cluster-1-default-pool-0989cb44-533n   Ready     20h       v1.6.4
gke-cluster-1-default-pool-0989cb44-mdf5   Ready     20h       v1.6.4
>>>>>>> variant B
```bash	
kubectl get nodes
NAME       STATUS    AGE       VERSION
minikube   Ready     7m        v1.6.0
####### Ancestor
```bash
kubectl get nodes
NAME        STATUS    AGE
127.0.0.1   Ready     48m
======= end
```

Here we see the available nodes, just one in our case. Kubernetes will choose where to deploy our application based on the available Node resources.

---

### Step 2 deploy a simple application 

Let’s run our first app on Kubernetes with the kubectl run command. The `run` command creates a new deployment for the specified container. This is the simpliest way of deploying a container.

```bash
<<<<<<< variant A
kubectl run hello \
 --image=gcr.io/google_containers/echoserver:1.4 \
 --port=8080
>>>>>>> variant B
kubectl run hello-kubernetes \
--image=gcr.io/google_containers/echoserver:1.4 --port=8080
####### Ancestor
kubectl run hello-minikube \  
 --image=gcr.io/google_containers/echoserver:1.4 \
 --port=8080
======= end

<<<<<<< variant A
deployment "hello" created
>>>>>>> variant B
deployment "hello-kubernetes" created
####### Ancestor
deployment "hello-minikube" created
======= end
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
<<<<<<< variant A
NAME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hello            1         1         1            1           51s

>>>>>>> variant B
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hello-kubernetes   1         1         1            1           31s
####### Ancestor
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hellonode   1         1         1            1           31s
======= end
```

<<<<<<< variant A
We see that there is 1 **Deployment** running a single instance of your app.
>>>>>>> variant B
We see that there is 1 deployment running a single instance of your app. 
####### Ancestor
We see that there is 1 deployment running a single instance of your app.
======= end

---

### Inspect your application

<<<<<<< variant A
By default applications are only visible inside the cluster. We can create a proxy to connect to our application.  
Find out the **Pod** name:
>>>>>>> variant B
With 
####### Ancestor
By default applications are only visible inside the cluster. We can create a proxy to connect to our application.  
Find out the pod name:
======= end
```
kubectl get <obejct>
```
<<<<<<< variant A
Create the proxy:
```bash
kubectl port-forward hello-3015430129-g95j6 8080:8080
>>>>>>> variant B
and 
####### Ancestor
Create the proxy:
```bash
kubectl port-forward hello-minikube-3015430129-g95j6 8080:8080
======= end
```
kubectl describe <object>
```
you can gather information about the status of your objects like pods, deployments, services, etc.

---

### Step 3 View our app

By default applications are only visible inside the cluster. We can create a proxy to connect to our application.  
Find out the pod name:
```
kubectl get pod
```
Create the proxy:
```bash
kubectl port-forward hello-kubernetes-3015430129-g95j6 8080 
```
<<<<<<< variant A
you can gather information about the status of your objects like **Pod**s, **Deployment**s, **Service**s, etc.
>>>>>>> variant B
We now have a connection between our host and the Kubernetes cluster.
####### Ancestor
you can gather information about the status of your objects like pods, deployments, services, etc.
======= end

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

`kubectl port-forward` is meant for testing services that are not exposed. To expose the application, use a service.

Delete old **Deployment**

```
<<<<<<< variant A
kubectl delete deployment hello
>>>>>>> variant B
kubectl delete deployment hello-kubernetes
####### Ancestor
kubectl delete deployment hello-minikube
======= end
```

---

Create a new **Deployment** and a **Service**

```
<<<<<<< variant A
kubectl run hello --image=gcr.io/google_containers/echoserver:1.4 --port=8080 --expose --service-overrides='{ "spec": { "type": "LoadBalancer" } }'
service "hello" created
deployment "hello" created
>>>>>>> variant B
kubectl run hello-kubernetes \
--image=gcr.io/google_containers/echoserver:1.4 \
--port=8080 --expose \
--service-overrides='{ "spec": { "type": "NodePort" } }'

service "hello-kubernetes" created
deployment "hello-kubernetes" created
####### Ancestor
kubectl run hello-minikube \
 --image=gcr.io/google_containers/echoserver:1.4 \
  --port=8080 --expose --service-overrides='{ "spec": { \
     "type": "NodePort" } }'
service "hello-minikube" created
deployment "hello-minikube" created
======= end
```

This creates a new **Deployment** and a service of **type:LoadBalancer**. A random high port will be allocated to which we can connect.

---

View the **Service**:

```
kubectl get service
kubectl get svc
<<<<<<< variant A
NAME          CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
hello         10.63.251.230   35.187.76.71   8080:31285/TCP   24s
kubernetes    10.0.0.1        <none>         443/TCP          28m
>>>>>>> variant B
NAME             CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
hello-kubernetes   10.0.0.233   <nodes>       8080:31075/TCP   24s
kubernetes       10.0.0.1     <none>        443/TCP          28m
####### Ancestor
NAME             CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
hello-minikube   10.0.0.233   <nodes>       8080:31075/TCP   24s
kubernetes       10.0.0.1     <none>        443/TCP          28m
======= end
```
<<<<<<< variant A
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
>>>>>>> variant B

Access the application with curl

(use the IP of one of your nodes)

```
curl 0.0.0.0:31075
####### Ancestor
Access the application with curl:
```
curl $(minikube ip):31075
```
Or when using minikube:
```
curl $(minikube service hello-minikube --url)
======= end
```

---

### Cleanup

```
<<<<<<< variant A
kubectl delete deployment,service hello
deployment "hello" deleted
service "hello" deleted
>>>>>>> variant B
kubectl delete deployment,service hello-kubernetes
deployment "hello-kubernetes" deleted
service "hello-kubernetes" deleted
####### Ancestor
kubectl delete deployment,service hello-minikube
deployment "hello-minikube" deleted
service "hello-minikube" deleted
======= end
```

----

[Next up Pods...](../03_pods.md)


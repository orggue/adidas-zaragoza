### Step 1 kubectl basics

The format of a kubectl command is: kubectl [action] [resource]  
This performs the specified action  (like create, describe) on the specified resource (like node, container). You can use --help after the command to get additional info about possible parameters (kubectl get nodes --help).

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
```

You can see both the client and the server versions

----

To view the nodes in the cluster, run the `kubectl get nodes` command:
```bash	
kubectl get nodes
NAME        STATUS    AGE
127.0.0.1   Ready     48m
```

Here we see the available nodes, just one in our case. Kubernetes will choose where to deploy our application based on the available Node resources.

----

### Step 2 deploy a simple application 

Let’s run our first app on Kubernetes with the kubectl run command. The run command creates automatically a new deployment for the specified container. This is the simpliest way of deploying a container.

```bash
kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080

deployment "hello-minikube" created
```

This performed a few things for you:
* searched for a suitable node
* scheduled the application to run on that Node
* configured the cluster to reschedule the instance on a new Node when needed 

----

### list your deployments

```bash
kubectl get deployments
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hellonode   1         1         1            1           31s
````

We see that there is 1 deployment running a single instance of your app. 

----

### Step 3 View our app

By default deployed applications are visible only inside the Kubernetes cluster. To view that the application output without exposing it externally, we’ll create a route between our terminal and the Kubernetes cluster using a proxy:
Find out the pod name
```
kubectl get pod
```
Create the proxy
```bash
kubectl port-forward hello-minikube-3015430129-g95j6 8080 8080 
```
We now have a connection between our host and the Kubernetes cluster.

----

### Inspect your application

With `kubectl get <obejct>` and `kubectl describe <object>` you can gather information about the status of your objects like pods, deployments, services, ...

----

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

----

### Expose service while creating the deployment

`kubectl proxy` is meant for testing services which are not getting exposed. To expose the application we can create a service definition (we come to that) or we let kubernetes do that for us

Delete old deployment
```
kubectl delete deployment hello-minikube
```
----

Create a new deployment and a service
```
kubectl run hello-minikube --image=gcr.io/google_containers/echoserver:1.4 --port=8080 --expose --service-overrides='{ "spec": { "type": "NodePort" } }'
service "hello-minikube" created
deployment "hello-minikube" created
```
This creates a new deployment and a service of type:NodePort. It will get an random high port allocated where we can access the application:

----

View the service:
```
kubectl get service
kubectl get svc
NAME             CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
hello-minikube   10.0.0.233   <nodes>       8080:31075/TCP   24s
kubernetes       10.0.0.1     <none>        443/TCP          28m
```
Access the application with curl
```
curl $(minikube ip):31075
```
Or when using minikube
```
curl $(minikube service hello-minikube --url)
```

----

### Cleanup

```
kubectl delete deployment,service hello-minikube
deployment "hello-minikube" deleted
service "hello-minikube" deleted
```
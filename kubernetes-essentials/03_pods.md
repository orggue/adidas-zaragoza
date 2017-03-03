## Creating and managing pods

At the core of Kubernetes is the Pod. Pods represent a logical application and hold a collection of one or more containers and volumes. In this lab you will:

* Create a simple Hello World node.js application
* Create a docker container image
* Write a Pod configuration file
* Create and inspect Pods
* Interact with Pods remotely using kubectl

We'll create a Pod named `hello-world` and interact with it using the kubectl.

----

### Local development with minikube

When developing with Docker containers, we often do not wish to publish them before testing them in minikube. We'll now setup minikube and Docker to work smoothly together.

```
minikube delte
minikube start --insecure-registry localhost:5000
```
This will create a VM and configure a single-node Kubernetes cluster inside it.
The --insecure-registry localhost:5000 is needed because it allows for the Docker daemon running on the minikube node to connect to an insecure Docker registry, without using SSL. This simplifies the setup process without any real disadvantage, since we’ll be using this same Docker daemon to build and push our images, so nothing will be sent over external networks.

----

### Using minikube’s Docker daemon from our localhost

Since we’re already running a Docker daemon inside the minikube’s VM, we should take advantage of this instead of relying on another VM. 

In order to do that, you just need to run the following and you’re ready to go:

```
eval $(minikube docker-env)
```

----

### Create your node.js app

A simple “hello world”: server.js (note the port number argument to www.listen):
```
var http = require('http');
var handleRequest = function(request, response) {
  response.writeHead(200);
  response.end("Hello World!");
}
var www = http.createServer(handleRequest);
www.listen(8080);
```
Save that to a file called `server.js`
----

### Create a docker container image

Create the file `Dockerfile` for hello-node (note port 8080 in the EXPOSE command):
```
FROM node:6.9
EXPOSE 8080
COPY server.js /
ENTRYPOINT ["node", "/server.js"]
```

----

### Build the container

We will build the container on minikube

```
docker build -t hello-node:v1 .
```

----

### Create your app on K8s

kubectl run hello-node --image=hello-node:v1 --port=8080
deployment "hello-node" created

----

### Check Deployment and Pod

```
kubectl get deployment
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
hello-node   1         1         1            1           49s
kubectl get pod
NAME                          READY     STATUS    RESTARTS   AGE
hello-node-2399519400-02z6l   1/1       Running   0          54s
```

----

### Check metadata about the cluster, events and kubectl configuration

```
kubectl cluster-info
kubectl get events
kubectl config view
```

----

### Creating a Pod manifest

Explore the `hello-world` pod configuration file:

```
cat pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: hello-node
  labels:
    app: hello-node
spec:
  containers:
    - name: hello-node
      image: hello-node:v1
      ports:
        - containerPort: 8080
```
Create the pod using kubectl:

```
kubectl delete deployment hello-node
kubectl create -f configs/pod.yaml
```

----

### View Pod details

Use the `kubectl get` and `kubect describe` commands to view details for the `hello-node` Pod:

```
kubectl get pods
```

```
kubectl describe pods <pod-name>
```

----

### Interact with a Pod remotely

Pods are allocated a private IP address by default and cannot be reached outside of the cluster. Use the `kubectl port-forward`, as allreday done in the previous section, to map a local port to a port inside the `hello-node` pod.

Use two terminals. One to run the `kubectl port-forward` command, and the other to issue `curl` commands.

----
Terminal 1
```
kubectl port-forward hello-node 8080 8080
```
Terminal 2
```
curl 0.0.0.0:8080
Hello World!
````

----

### Do it yourself
* Create a `nginx.conf` which returns a 200 "From zero to hero"
* Create a Docker container based on nginx and copy the `nginx.conf` file in that container
* Build the container on minikube
* Create a Pod manifest using the new container
* Get output of the application using `curl`or your browser
* Access the pod on port 80 using port-forward
* View the logs of the nginx container

----

### Debugging

### View the logs of a Pod

Use the `kubectl logs` command to view the logs for the `<PODNAME>` Pod:

```
kubectl logs <PODNAME>
```

> Use the -f flag and observe what happens.

----

### Run an interactive shell inside a Pod

Like with Docker you can establish an interactive shell to a pod with almost the same sytax. Use the `kubectl exec` command to run an interactive shell inside the `<PODNAME>` Pod:

```
kubectl exec -ti <PODNAME> /bin/sh
```

----


## Creating and Managing Deployments

Deployments sit on top of ReplicaSets and add the ability to define how updates to Pods should be rolled out.

In this section we will combine everything we learned about Pods and Services and create a Deplyoment manifest for our hello-node application. 
* Create a deployment manifest
* Scale our Deployment / ReplicaSet
* Update our application (Rolling Update | Recreate)

----

### Creating Deployments

An example of a deployment is the frontend service of the sock Shops

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: hello-node
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: hello-node
    spec:
      containers:
      - name: hello-node
        image: hello-node:v1
        ports:
        - containerPort: 8080
```

----


```
kubectl create -f configs/service.yaml
```

----

### Scaling Deployments

Behind the scenes Deployments manage ReplicaSets. Each deployment is mapped to one active ReplicaSet. Use the `kubectl get replicasets` command to view the current set of replicas.
```
kubectl get rs
NAME                   DESIRED   CURRENT   READY     AGE
hello-node-364036756   1         1         1         16s
```
----

### Scaling Deployments

ReplicaSets are scaled through the Deployment or independently. Use the `kubectl scale` command to scale:

```
kubectl scale --replicas=3 rs/hello-node-364036756
replicaset "hello-node-364036756" scaled
```

----

### Check the status of scaling the ReplicaSet
```
kubectl get rs hello-node-364036756
kubectl describe rs hello-node-364036756
```

----

### Scale down the Deployment

```
kubectl scale deployments hello-node --replicas=2
deployment "hello-node" scaled
```

----

### Check the status of the Deployment

```
kubectl describe deployment hello-node
```
```
kubectl get pods
```

----

### Updating Deployments ( RollingUpdate )

We need to make some changes to our node.js application and create a new image with a new Version. Default update strategy is RollingUpdate and we will test that out first.

Update the text `Hello World!` to something different like `Verion 2`

Build a new Dockerimage and tag it with v2

Update the Deployment
```
kubectl set image deployment/hello-node hello-node=hello-node:v2
```

----

### Validate that it works
We can use ab (Apache Benchmark) to make continous requests to our application and we'll see if some requests will fail. Using `--watch-only` we'll see updates of the pods.

```
ab -n 50000 -c 1  $(minikube service hello-node --url)/
kubectl get po --watch-only
```

----

### Cleanup

```
kubectl delete -f configs/deployment-v1.yaml
```
If there were a large number of pods, this may take a while to complete. If you want to leave the pods running instead, specify `--cascade=false`
If you try to delete the pods before deleting the Deployments, it will just replace them, as it is supposed to do.

----

### Updating Deployments ( Recreate )

We'll see how to do an update to our application using the recreate strategy. First we need to create a deploment with the Recreate strategy.
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: hello-node
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: hello-node
    spec:
      containers:
      - name: hello-node
        image: hello-node:v1
        ports:
        - containerPort: 8080
```

Update the Deployment
```
kubectl set image deployment/hello-node hello-node=hello-node:v2
```

----

### Validate that it works
We can use ab (Apache Benchmark) to make continous requests to our application and we'll see if some requests will fail. Using `--watch-only` we'll see updates of the pods.

```
ab -n 50000 -c 1  $(minikube service hello-node --url)/
This is ApacheBench, Version 2.3 <$Revision: 1748469 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 192.168.99.100 (be patient)
apr_pollset_poll: The timeout specified has expired (70007)
Total of 4002 requests completed


kubectl get po --watch-only
NAME                         READY     STATUS        RESTARTS   AGE
hello-node-364036756-c9r4l   1/1       Terminating   0          6m
hello-node-364036756-fs7vf   1/1       Terminating   0         6m
hello-node-364036756-pblkw   1/1       Terminating   0         6m
hello-node-364036756-f84dq   1/1       Terminating   0         6m
hello-node-445432469-8nslh   0/1       Pending   0         0s
hello-node-445432469-3c6fc   0/1       Pending   0         0s
hello-node-445432469-rfw0s   0/1       Pending   0         0s
hello-node-445432469-czsxw   0/1       Pending   0         0s
hello-node-445432469-8nslh   0/1       Pending   0         0s
hello-node-445432469-3c6fc   0/1       Pending   0         0s
hello-node-445432469-rfw0s   0/1       Pending   0         0s
hello-node-445432469-czsxw   0/1       Pending   0         0s
hello-node-445432469-8nslh   0/1       ContainerCreating   0         0s
hello-node-445432469-3c6fc   0/1       ContainerCreating   0         0s
hello-node-445432469-rfw0s   0/1       ContainerCreating   0         2s
hello-node-445432469-czsxw   0/1       ContainerCreating   0         2s
hello-node-445432469-8nslh   1/1       Running   0         4s
hello-node-445432469-rfw0s   1/1       Running   0         5s
hello-node-445432469-3c6fc   1/1       Running   0         5s
hello-node-445432469-czsxw   1/1       Running   0         6s
```

You'll notice that reqeusts to the application can't be fullfiled because first the old pods are getting terminated and then the new pods are getting started.

----

### Cleanup

```
kubectl delete -f configs/deployment-v2.yaml
```

----

### Do it yourself

* Create a deployment manifest for a nginx:1.10 containers with a defined number of replicas=1
* Create a serivce manifest to expose the nginx
* Scale the deployment up to 3
* Validate the scaling was successful
* Update the deployment to use nginx:1.11
* Cleanup
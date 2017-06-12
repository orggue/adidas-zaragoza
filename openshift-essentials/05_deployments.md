## Creating and Managing Deployments

Deployments sit on top of ReplicaSets and add the ability to define how updates to Pods should be rolled out.

In this section we will combine everything we learned about Pods and Services and create a Deplyoment manifest for our hello-node application.
* Create a deployment manifest.
* Scale our Deployment / ReplicaSet.
* Update our application (Rolling Update | Recreate).

----

### Creating Deployments

An example of a deployment:

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
oc create -f configs/deployment-v1.yaml
```

----

### Scaling Deployments

Behind the scenes Deployments manage ReplicaSets. Each deployment is mapped to one active ReplicaSet. Use the `oc get replicasets` command to view the current set of replicas.
```
oc get rs
NAME                   DESIRED   CURRENT   READY     AGE
hello-node-364036756   1         1         1         16s
```

----

### Scaling Deployments

```
oc scale deployments hello-node --replicas=3
deployment "hello-node" scaled
```

----

### Scale down the Deployment

```
oc scale deployments hello-node --replicas=2
deployment "hello-node" scaled
```

----

### Check the status of the Deployment

```
oc describe deployment hello-node
```
```
oc get pods
```

----

### Updating Deployments ( RollingUpdate )

* RollingUpdate is the default strategy.
* Updates Pods one (or a few) at a time.
* Update the text of the application, creating a new version of the image.
* Build a new image and tag it with v2.
* Update the Deployment:

```
oc set image deployments hello-node hello-node=hello-node:v2
```

----

### Validate that it works
We will use curl in a loop to validate that the update will not affect the application.

In one terminal
```
for ((i=1;i<=10000;i++)); do curl -s -o /dev/null -I -w "%{http_code}" "0.0.0.0:30080"; done
```
Watch what happens to the pods in another terminal:
```
oc get pod --watch-only
```
In a third terminal update to the "old" version v1:
```
oc set image deployments hello-node hello-node=hello-node:v1
```
During the update the service will continue to serve requests. You'll also witness the rolling update.

----

### Cleanup

```
oc delete -f configs/deployment-v1.yaml
```
* If the number of Pods is large, this may take a while to complete.
* To leave the Pods running instead,  
use `--cascade=false`.
* If you try to delete the Pods before deleting the Deployment, the ReplicaSet will just replace them.

----

### Updating Deployments ( Recreate )

* Recreate is the alternative update strategy.
* All existing Pods are killed before new ones are created.
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

----

Create the new Deployment:
```
oc create -f configs/deplyoment-v2.yaml
```

Update the Deployment:
```
oc set image deployments hello-node hello-node=hello-node:v2
```

----

### Validate that it works
We will use curl in a loop to validate that the update will not affect the application.

In one terminal:
```
for ((i=1;i<=10000;i++)); do curl -s -o /dev/null -I -w "%{http_code}" "0.0.0.0:30080"; done
```
Watch what happens to the pods in another terminal:
```
oc get pod --watch-only
```
In a third terminal update to the "old" version v1:
```
oc set image deployments hello-node hello-node=hello-node:v1
```

----

You'll see that curl will stop or even a timeout will occur. You also saw that first all pods are getting terminated before the new ones are getting started, in the window where you've watched the pod.

----

### Cleanup

```
oc delete -f configs/deployment-v2.yaml
```

----

### Do it yourself

* Create a deployment manifest for one nginx:1.12 container.
* Create a service manifest to expose Nginx.
* Scale the deployment up to 3.
* Validate the scaling was successful.
* Update the deployment to use nginx:1.13.
* Cleanup.

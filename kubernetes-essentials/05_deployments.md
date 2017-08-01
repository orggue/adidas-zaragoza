---
title: Kubernetes Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

### Creating and Managing **Deployment**s

In this section we will

* Combine what we learned about **Pod**s and **Service**s
* Create a deployment manifest
* Scale our **Deployment** / **ReplicaSet**
* Update our application (Rolling Update | Recreate)

---

### ReplicaSet

A **ReplicaSet** ensures that a specified number of **Pod**s are running at any given time.

---

### Deployment

A **Deployment** manages **ReplicaSets** and defines how updates to **Pod**s should be rolled out.

---

### Creating a Deployment

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
        image: nginx:1.12
        ports:
        - containerPort: 8080
```

---

### Deploy to K8s

```
kubectl create -f configs/deployment-v1.yaml
```

---

### Scaling **Deployment**s

* **Deployment**s manage **ReplicaSet**s.
* Each **Deployment** is mapped to one active **ReplicaSet**.
* Use `kubectl get replicasets` to view the current set of replicas.

```
kubectl get rs
NAME                   DESIRED   CURRENT   READY     AGE
hello-node-364036756   1         1         1         16s
```

---

### Scaling Deployments

* **ReplicaSet**s can be scaled through the **Deployment** or independently.  
* Use the `kubectl scale` command to scale:

```
kubectl scale --replicas=3 deployments/hello-node
deployment "hello-node" scaled
```

---

### Check the status of scaling the ReplicaSet
```
kubectl get rs hello-node-364036756
kubectl describe rs hello-node-364036756
```

---

### Scale down the **Deployment**

```
kubectl scale deployments hello-node --replicas=2
deployment "hello-node" scaled
```

---

### Check the status of the **Deployment**

```
kubectl describe deployment hello-node
```
```
kubectl get pods
```

---

### Updating Deployments 

(`RollingUpdate`)

* RollingUpdate is the default strategy.
* Updates Pods one (or a few) at a time.

----

### Common workflow

* Update the text of the application, creating a new version of the image.
* Build a new image and tag it with v2.
* Update the **Deployment**:

```
kubectl set image deployment/hello-node hello-node=muellermich/hello-node:v2
```

* Check status via 

```
kubectl rollout status deployment hello-node
```

---

### Cleanup

```
kubectl delete -f configs/deployment-v1.yaml
```
* If the number of Pods is large, this may take a while to complete.
* To leave the Pods running instead,  
use `--cascade=false`.
* If you try to delete the Pods before deleting the Deployment, the ReplicaSet will just replace them.

---

### Updating Deployments (Recreate)

* Recreate is the alternative update strategy.
* All existing **Pod**s are killed before new ones are created.

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
        image: nginx:1.13
        ports:
        - containerPort: 8080
```

---

### Deploy to K8s

```
kubectl create -f configs/deployment-v2.yaml
```

---

### Updating Deployments (Recreate)

Update the Deployment
```
kubectl set image deployment/hello-node hello-node=muellermich/hello-node:v2

kubectl get pods -w
```

---

### Cleanup

```
kubectl delete -f configs/deployment-v2.yaml
```

---

### Do it yourself

* Create a deployment for one nginx:1.12 container.
* Create a service manifest to expose Nginx.
* Scale the deployment up to 3.
* Validate the scaling was successful.
* Update the **Deployment** to use nginx:1.13-alpine.
* Cleanup

----

[FIN](../01_outline.md)

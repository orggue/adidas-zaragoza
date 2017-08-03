---
title: Kubernetes Deployments Exercise
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Kubernetes Deployments

---

### The files

This exercise involves two deployments and one service manifest
that can be found in the config folder

---


### The Service

Review the configs/service.yaml

```
apiVersion: v1
kind: Service
metadata:
  name: hello-node
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: hello-node

```

Note the selector

Lets apply that manifest

```
kubectl apply -f configs/service.yaml
```


### The Deployments

The deployments are identical aside from the version label and the name

The name needs to be different to have them both running on the same 
cluster in the same namespace

The version will be utilized by the service selector

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
        image: muellermich/hello-node:v1

```

###  Canary Deployment and AB
This is the easiest

Deploy the first deployment

```
kubectl apply -f configs/deployment-v1.yaml
```

Check the IP of your svc

```
kubectl get svc
```
Then curl the service
```
curl IP:8080
Hello World!
```
Now for this to be a canary deployment we need to have more versions
of one rather than the canary version
So lets scale the deployment

```
kubectl scale --replicas=3 deployment/hello-node
```
Now run out a canary deployment with version 2

```
kubectl apply -f configs/deployment-v2.yaml
```

Because traffic is spread across the deployments we won't run one curl but try multiple

Run the following
```
for i in {1..20}; do curl IP:8080; echo; done
```

Is traffic distributed equal to the ratio of v1 and v2 deployment?

Scale your deployments as you see fit

Make v1 6 and v2 4

Now you have a 60 40 split of pods.

Is the traffic distributed 60:40

---

### Blue Green Deployment

Leave both deployments running from the previous exercise

Edit the configs/service.yaml file and add
```
    version: one
```
under the selector (The cli is supposed to be able to do this, but has bug)

then apply your changes
```
kubectl apply -f configs/service.yaml
```

curl your application again

Now change the selector in the service to
```
    version: two
```

curl your application again

### Other options

Run through the exercise on Katacode for using Istio in a Kubernetes
cluster for examples of more robust deployment options.  

https://www.katacoda.com/courses/istio/deploy-istio-on-kubernetes

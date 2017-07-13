---
title: Kubernetes Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Kubernetes Essentials

---

### What will you learn?

* Slides

  * What is k8s? Use cases & core concepts
  
* Exercises

  * Managing cloud native apps with `kubectl`

---


### What is k8s?

* Open Source container orchestrator created by Google

* Top level project from the Cloud Native Computing Foundation CNCF

* Popular: 24K stars on Github

---

### Use cases

* Managing containerized applications

* Scaling

* Load balancing

* Rolling Updates

*And more!*

---

### How to use k8s?

* Install k8s on a set of machines: a k8s cluster

* Package your applications as Docker containers

* Deploy your applications using the `kubectl` cli or k8s APIs

---

## Core concepts

---

### Outline

* Container
* Pod
* Deployment
* ReplicaSet
* Service
* Label
* Selector

---

### **Container**

* **Container**s are the processes scheduled by k8s

* Scheduled as part of a **Pod**

---

### **Pod**

* Fundamental application unit

* **Pod** contains one or more **Container**s

* **Container**s in the **Pod** share network stack and volumes

---

### **Deployment**

* Manages updates to **Pod**s

* Example:
	
  * Updating a **Container** image
  
  * Scaling up or down
  

---


### **ReplicaSet**

* Internal component used by **Deployment**

* Example:

  * On rolling upgrade **Deployment** creates new **ReplicaSet** and destroys old one

---

### **Service**

* Exposes your **Pod** to traffic from outside the cluster


---

### **Label**


* Used to manage **Pod**s

* `"environment" : "dev"`

* Useful for monitoring and analytics

---

### **Selector**

* Match **Pod**s based on their *Label*s

---

## Kubernetes Architecture

---

### Architecture Diagram


<img src="kubernetes-architecture.png">

---

### Master

* api-server
 
 * Provides outbound Kubernetes REST API
 
 * Uses etcd to store state
 
 * Implements the basic logic for scheduling

---


### Master

* controller-manager

  * Implements core control loops shipped with Kubernetes
  
  * Regulates the state of the system
  
  * Watches cluster state through the apiserver
  
  * Changes current state towards the desired state

---


### Master

* scheduler

  * Workload-specific function that significantly impacts availability, performance, and capacity
  
  * Responsible to identify the state the cluster has to be in

---

### Master

* etcd

Distributed, consistent key-value store for shared configuration and service discovery

---


### Node

* kubelet

  * Primary agent that runs on each node
  
  * Takes a set of `PodSpecs` and ensures that the containers are running and healthy

---


### Node

* kube-proxy

  * Load balancer for the services on that node
  
---

### Manifests

* k8s uses Yaml based manifests

* Every resource can be defined through a manifest	


---


## Manifests

```
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


---



### **Service** types

* ClusterIP
  
* LoadBalancer
 
* NodePort

* Headless

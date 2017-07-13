---
title: Kubernetes Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

## Creating and Managing **Service**s

In this section you will create a `hello-node` **Service** and "expose" the `hello-node` **Pod**. You will learn how to:

* Create a **Service**.
* Use label and selectors to expose a limited set of **Pod**s externally.

---

### Introduction to **Service**s

* Stable endpoints for **Pod**s.
* Based on labels and selectors.

---

### **Service** types

* `ClusterIP` Exposes the **Service** on a cluster-internal IP.

* `NodePort` Expose the **Service** on a specific port on each node.

* `LoadBalancer` Use a loadbalancer from a Cloud Provider. Creates `NodePort` and `ClusterIP`.

* `ExternalName` Connect an external service (CNAME) to the cluster.

---

### Create a Service

Explore the hello-node **Service** configuration file:

```
cat service.yaml
apiVersion: v1
kind: Service
metadata:
  name: hello-node
spec:
  type: NodePort
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 8080
    nodePort: 30080
  selector:
    app: hello-node
```

Setting `nodePort` is optional. If not set, a random high port is assigned.

---

Create the hello-node **Service** using `kubectl`:

```
kubectl create -f service.yaml
```

---

### Query the **Service**

```
curl -i 0.0.0.0:30080
```

---

### Explore the hello-node **Service**

```bash
kubectl get services hello-node
```

```bash
kubectl describe services hello-node
```

---

### Using labels

Use `kubectl get pods` with a label query, e.g. for troubleshooting.

```
kubectl get pods -l "app=hello-node"
```

Use `kubectl label` to add labels.

```
kubectl label pods hello-node 'secure=disabled'
```

---

View the endpoints of the `hello-node` **Service**:

```
kubectl describe services hello-node
```

---

### Do it yourself

* Create a **Service** for the nginx **Pod**s.
* Expose port 80 to a static `nodePort` 31000.
* Access the **Service** using `curl` or a browser.

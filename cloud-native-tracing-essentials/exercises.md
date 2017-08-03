---
title: Cloud Native Tracing Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Cloud Native Tracing

---

## Outline

* This module only has a single exercise

* We will install the Weave Sock Shop

* We will install the Zipkin and update some services to make them aware of zipkin


---

## Installing Weave Sock Shop

* Check out the Sock Shop code for cs training

```
git clone https://github.com/microservices-demo/microservices-demo
cd microservices-demo/deploy/kubernetes
git checkout cs-training
```

Now we will deploy the Sock Shop

```
kubectl create -f manifests/sock-shop-ns.yaml -f manifests
```
Do you know why we ran create in this order?  Did you get an error?
Please ask us to explain

Insure the sock-shop is running
```
kubectl get pods -n sock-shop
```


---

## Installing Zipkin

To launch zipkin 

```
kubectl apply -f manifests-zipkin/zipkin-ns.yaml -f manifests-zipkin
```

Wait for the zipkin endpoints to be available

```
kubectl get svc -n zipkin
```

Visit the endpoint for zipkin

Some services were restarted with new configurations,make sure they are up again

```
kubectl get pods -n sock-shop
```

The load-test should already be running, this will generate traces for you.

# Using Zipkin

Now take a look around. Try:

* Read the documentation at: http://zipkin.io/

* Choose orders in the drop down and click Find Traces

* Click on a trace to delve deeper



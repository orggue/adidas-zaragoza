---
title: Cloud Native Monitoring Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Cloud Native Monitoring

---

## Outline

* This module only has a single exercise

* We will install the Weave Sock Shop

* Inside the Sock Shop there are a range of monitoring manifests. We will use these to investigate
  two cloud-native projects: prometheus and grafana.

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

Not all services may come up the only required one is user

---

## Installing Prometheus

To install prometheus 

First visit https://requestb.in

Click create requestbin

Copy the url and replace REQUESTBIN_URL in

```
manifests-monitoring/alertmanager-configmap.yaml
```
Keep the requestb.in page open

Now launch prometheus, grafana and the alertmanager 

```
kubectl create -f manifests-monitoring/monitoring-ns.yaml -f manifests-monitoring
```

Wait for the prometheus endpoints to be available

```
kubectl get svc -n monitoring
```

Visit the endpoint for grafana and prometheus

While in prometheus go to alerts you have one alert rule

```
rate(microservices_demo_user_request_count[1m]) > 20
```

Basically fire an alert if the request rate for the user service goes over 20 in a minute

We will force this to happen

install siege
```
sudo apt-get install -y siege 
```

Now we will port forward to the user service

First get your user pod id
```
kubectl get pods -n sock-shop
```
And proxy to the service
```
kubectl port-forward USER_POD_ID 8000:80 -n sock-shop
```
Then hit it with a bunch of requests
```
siege --concurrent=20 --reps=100 http://localhost:8000/healt
```

You can visit prometheus and enter your own PromQL
to see the effects of siege

```
rate(microservices_demo_user_request_count[1m])
```

After a few minutes if you visit the Alerts tab in Prometheus
you will see an alert is active

Visit the request bin url and you will see that the endpoint
has been hit with an alert

# Using Prometheus

Now take a look around. Try:

* Read the documentation at: https://prometheus.io/docs/querying/basics/

* Plot the rate of requests (the rate of `request_duration_seconds_count`) - your results may vary,
  this depends on the requests to the sock shop.

* Deploy the `load-test` manifest. This starts a container that loads the sock-shop. `kubectl apply
  -f /deploy/kubernetes/manifests/loadtest-dep.yaml`

* Watch the rate of requests again.

---

# Tasks

Grafana documentation can be found here: http://docs.grafana.org/guides/basic_concepts/

* Create your own dashboard.

* Create a 95th percentile latency plot

* Create a "metric" showing the number of sock orders.

---

# Extra

If you've finished all this, and you have some extra time, browse to the alertmanager directory:

`cd /deploy/kubernetes/manifests-alerting/`

The prometheus alertmanager provides an alert mechanism for prometheus.

* Investigate. :-)



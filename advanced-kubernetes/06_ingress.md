### What is ingress?

Typically, services and pods have IPs only routable by the cluster network. All traffic that ends up at an edge router is either dropped or forwarded elsewhere. Conceptually, this might look like:
```
    internet
        |
  ------------
  [ Services ]
```
An Ingress is a collection of rules that allow inbound connections to reach the cluster services.
```
    internet
        |
   [ Ingress ]
   --|-----|--
   [ Services ]
```

----

It can be configured:
* to give services externally-reachable urls
* load balance traffic
* terminate SSL
* offer name based virtual hosting 

An Ingress controller is responsible for fulfilling the Ingress, usually with a loadbalancer, though it may also configure your edge router or additional frontends to help handle the traffic in an HA manner.

----

### Ingress controller

In order for the Ingress resource to work, the cluster must have an Ingress controller running

An Ingress Controller is a daemon, deployed as a Kubernetes Pod, that watches the ApiServer's /ingresses endpoint for updates to the Ingress resource. Its job is to satisfy requests for ingress.

Workflow:
* Poll until apiserver reports a new Ingress
* Write the LB config file based on a go text/template
* Reload LB config

----

### Example
Ingress resource
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata: 
  name: frontend-ingress
spec: 
  rules: 
    - 
      host: frontend.example.com
      http: 
        paths: 
          - 
            backend: 
              serviceName: front-end
              servicePort: 80
            path: /
```
*POSTing this to the API server will have no effect if you have not configured an Ingress controller.*

----

This section will focus on the nginx-ingress-controller. There are others like HAProxy or Traefik available. They can easily be exchanged. To check which one is best suited for you, please check the documentation of the loadbalancers if they meet your requirements.
There are also implementations for hardware loadbalancers like F5 available, but I haven't seen them used out in the wild.

Specialities of the NGINX ingress controller
The NGINX ingress controller does not uses Services to route traffic to the pods. Instead it uses the Endpoints API in order to bypass kube-proxy to allow NGINX features like session affinity and custom load balancing algorithms. It also removes some overhead, such as conntrack entries for iptables DNAT.

----

### Setup

For the controller, the first thing we need to do is setup a default backend service for nginx.

The default backend is the default fall-back service if the controller cannot route a request to a service. The default backend needs to satisfy the following two requirements :
* serves a 404 page at /
* serves 200 on a /healthz

Infos about the default backend can be found [here:](https://github.com/kubernetes/contrib/tree/master/404-server)

----

### Create the default backend

Let’s use the example default backend of the official kubernetes nginx ingress project:

```
kubectl create -f https://raw.githubusercontent.com/kubernetes/ingress/master/examples/deployment/nginx/default-backend.yaml

```

----

### Deploy the loadbalancer

```
kubectl create -f configs/ingress-daemonset.yaml
```

This will create a nginx-ingress-controller on each available node

----

### Deploy some application

First we need to deploy some application to publish. To keep this simple we will use the echoheaders app that just returns information about the http request as output
```
kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.4 \
  --replicas=1 --port=8080
```
Now we expose the same application in two different services (so we can create different Ingress rules)
```
kubectl expose deployment echoheaders --port=80 --target-port=8080 \
  --name=echoheaders-x
kubectl expose deployment echoheaders --port=80 --target-port=8080 \
  --name=echoheaders-y
```

----

### Create ingress rules

Explore and create some Ingress rules

```
kubectl create -f configs/ingress.yaml
```

```
  rules: 
    - host: foo.bar.com
      http: 
        paths: 
          - path: /foo
            backend: 
              serviceName: echoheaders-x
              servicePort: 80           
    - host: bar.baz.com
      http: 
        paths: 
          - path: /bar
            backend: 
              serviceName: echoheaders-y
              servicePort: 80
          - path: /foo
            backend: 
              serviceName: echoheaders-x
              servicePort: 80
```

----

### Accessing the application

We can use curl or a browser. If you want to access the applications you need either to edit you `/etc/hosts` file with the domains `foo.bar.com` and `bar.baz.com` and as the IP use the IP of minikube. Or having a browser plugin installed to manipulate the host header.

Here we'll use `curl``

```
curl -H "Host: foo.bar.com" http://$(minikube ip)/bar
curl -H "Host: bar.baz.com" http://$(minikube ip)/bar
curl -H "Host: bar.baz.com" http://$(minikube ip)/foo
```

----

### Enabling SSL

We want to have SSL for our services enabled. So let's create first the needed certificates for `foo.bar.com`:

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /work/tls.key \
-out /work/tls.crt -subj "/CN=foo.bar.com"
```
No openssl installed? No Prob
```
docker run -v $PWD:/work -it nginx openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 -keyout /work/tls.key -out /work/tls.crt \
  -subj "/CN=foo.bar.com"
```

----

### Create secrets for the SSL certificates

In order to pass the cert and key to the controller we'll create secrets as follow, where tsl.key is the key name and tsl.crt is your certificate and server.pem is the pem file.
```
kubectl create secret tls foo-secret --key tls.key --cert tls.crt
kubectl create secret generic tls-dhparam --from-file=dhparam.pem 
```

----

### Create an ingress using SSL

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: foo-ssl
  namespace: default
spec:
  tls:
  - hosts:
    - foo.bar.com
    secretName: foo-secret
  rules:
  - host: foo.bar.com
    http:
      paths:
      - backend:
          serviceName: echoheaders-x
          servicePort: 80
        path: /ssl
```

```
kubectl create -f configs/ingress-ssl.yaml
curl -H "Host: foo.bar.com" https://$(minikube ip)/ssl --insecure
```

----

### Do it yourself

* Deploy an nginx and expose it using a service
* Write a ingress manifest to expose the nginx service on port 80 listening on training.example.com/nginx
* Create a SSL certificate for training.example.com and create a ingress manifest for ssl and path /ssl
* Access the nginx via `curl` or a browser on port 80 and 443

----

### Whitelist

If you are using Ingress on your Kubernetes cluster it is possible to restrict access to your application based on dedicated IP addresses. 
IP whitelisting to restrict access can be used .This can be done with specifying the allowed client IP source ranges through the `ingress.kubernetes.io/whitelist-source-range` annotation. The value is a comma separated list of CIDR block, e.g. 10.0.0.0/24,1.1.1.1/32.

If you want to set a default global set of IPs this needs to be set in the config of the ingress-controller. 

----

### The configuration:

apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: whitelist
  annotations:
    ingress.kubernetes.io/whitelist-source-range: "1.1.1.1/24"
spec:
  rules:
  - host: whitelist.test.net
  http:
    paths:
    - path: /
    backend:
      serviceName: webserver
      servicePort: 80

----

### Testing with the annotation set:

curl -v -H "Host: whitelist.test.net" <HOST-IP>/graph
* Trying <HOST-IP>...
* TCP_NODELAY set
* Connected to <HOST-IP> (<HOST-IP>) port 80 (#0)
> GET /graph HTTP/1.1
> Host: whitelist.test.net
> User-Agent: curl/7.51.0
> Accept: */*
> 
< HTTP/1.1 403 Forbidden
< Server: nginx/1.11.3
< Date: Tue, 07 Feb 2017 09:46:51 GMT
< Content-Type: text/html
< Content-Length: 169
< Connection: keep-alive
< 
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>nginx/1.11.3</center>
</body>
</html>
* Curl_http_done: called premature == 0
* Connection #0 to host <HOST-IP> left intact

----

### Testing without the annotation set:

```bash
curl -v -H "Host: whitelist.test.net" <HOST-IP>/graph
* Trying <HOST-IP>...
* TCP_NODELAY set
* Connected to <HOST-IP> (<HOST-IP>) port 80 (#0)
> GET /graph HTTP/1.1
> Host: whitelist.test.net
> User-Agent: curl/7.51.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: nginx/1.11.3
< Date: Tue, 07 Feb 2017 09:49:01 GMT
< Content-Type: text/html; charset=utf-8
< Transfer-Encoding: chunked
< Connection: keep-alive

* Curl_http_done: called premature == 0
* Connection #0 to host <HOST-IP> left intact
```

Using this simple annotation, you’re able to restrict who can access the applications in your kubernetes cluster by its IPs.

----

### Path rewrites

Sometimes, there is a need to rewrite the path of a request to match up with the backend service. One such scenario might be, a API got developed and deployed, got changed over time, but there is still a need to be backwards compatibility on the API endpoints.

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: apitest
  namespace: applications
  annotations:
    ingress.kubernetes.io/rewrite-target: /new/get
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: "foo.bar.com"
    http:
      paths:
      - path: /get/new
        backend:
          serviceName: echoheaders-y
          servicePort: 80
````

----

### TCP

Ingress does not support TCP services (yet). For this reason this Ingress controller uses the flag --tcp-services-configmap to point to an existing config map where the key is the external port to use and the value is <namespace/service name>:<service port> It is possible to use a number or the name of the port.


```
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  9000: "default/example-go:8080"
```

----

### Test your TCP service

----

### UDP

Ingress does not support UDP services (yet). For this reason this Ingress controller uses a ConfigMap where the key is the external port to use and the value is <namespace/service name>:<service port> It is possible to use a number or the name of the port.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: udp-configmap-example
  namespace: kube-system
data:
  53: "kube-system/kube-dns:53"
```

To enable this capability you also need to tell the ingress controller where the service is deployed and the name of it. In our example it will be `--udp-services-configmap=$(POD_NAMESPACE)/udp-configmap-example`.

----

### Deploy UDP ingress ressource

```
kubectl replace -f configs/ingress-daemonset-udp.yaml
kubectl create -f configs/udp-configmap-example.yaml
```

----

### Test our UDP service




### External Auth
### Sticky Session
https://github.com/kubernetes/ingress/tree/master/examples/affinity/cookie/nginx

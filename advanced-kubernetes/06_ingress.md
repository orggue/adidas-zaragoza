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
kubectl create -f configs/ingress-config-template-configmap.yaml
kubectl create -f configs/ingress-daemonset.yaml
```

This will create a nginx-ingress-controller on each available node

----

### Deploy some application

First we need to deploy some application to publish. To keep this simple we will use the echoheaders app that just returns information about the http request as output
```
kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.4 --replicas=1 --port=8080
```
Now we expose the same application in two different services (so we can create different Ingress rules)
```
kubectl expose deployment echoheaders --port=80 --target-port=8080 --name=echoheaders-x
kubectl expose deployment echoheaders --port=80 --target-port=8080 --name=echoheaders-y
```

----

### Create ingress rules

Next we create a couple of Ingress rules

kubectl create -f configs/ingress.yaml

```
apiVersion: extensions/v1beta1
kind: Ingress
metadata: 
  name: echomap
spec: 
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
````

----

### Enabling SSL

We want to have SSL for our services enabled. So let's create first the needed certificates for `foo.bar.com`:

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=foo.bar.com"
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
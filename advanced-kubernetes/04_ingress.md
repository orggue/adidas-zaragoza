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

It can be configured to:
* Give services externally-reachable urls
* Loadbalance traffic
* Terminate SSL
* Offer name based virtual hosting

An Ingress controller is responsible for fulfilling the Ingress, usually with a loadbalancer, though it may also configure your edge router or additional frontends to help handle the traffic in an HA manner.

----

### Ingress controller

In order for the Ingress resource to work, the cluster must have an `Ingress Controller` running.

An `Ingress Controller` is a daemon, deployed as a Kubernetes Pod, that watches the ApiServer's /ingresses endpoint for updates to the Ingress resource. Its job is to satisfy requests for ingress.

----

### Ingress Workflow

* Poll until apiserver reports a new Ingress.
* Write the LB config file based on a go text/template.
* Reload LB config.

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

### Ingress Controllers

This section will focus on the nginx-ingress-controller. There are others available, suchs as HAProxy or Traefik. 

They can easily be exchanged. To check which one is best suited for you, please check the documentation of the loadbalancers if they meet your requirements.

There are also implementations for hardware loadbalancers like F5 available, but I haven't seen them used out in the wild.

----

### Specialities of the NGINX ingress controller
The NGINX ingress controller does not use Services to route traffic to the pods. 

Instead it uses the Endpoints API in order to bypass kube-proxy to allow NGINX features like session affinity and custom load balancing algorithms. 

It also removes some overhead, such as conntrack entries for iptables DNAT.

----

### Setup

For the controller, the first thing we need to do is setup a default backend service for nginx.

This is the default fall-back service if the controller cannot route a request to a service. The default backend needs to satisfy the following two requirements :
* Serve a 404 page at /
* Serve 200 on a /healthz

Infos about the default backend can be found [here](https://github.com/kubernetes/contrib/tree/master/404-server).

----

### Create the default backend

Let’s use the example default backend of the official kubernetes nginx ingress project:

```
kubectl create -f \
https://raw.githubusercontent.com/kubernetes/ingress/master/examples/deployment/nginx/default-backend.yaml

```

----

### Deploy the loadbalancer

```
kubectl create -f configs/ingress/ingress-daemonset.yaml
```

This will create a nginx-ingress-controller on each available node.

----

### Deploy some application

First we need to deploy some application to publish. To keep this simple we will use the echoheaders app that just returns information about the http request as output.
```
kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.4 \
  --replicas=1 --port=8080
```
Now we expose the same application in two different services (so we can create different Ingress rules).
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
kubectl create -f configs/ingress/ingress.yaml
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

To access the applications via a browser you need either to edit your `/etc/hosts` file with the domains `foo.bar.com` and `bar.baz.com` pointing to the IP of your k8s cluster. Or use a browser plugin to manipulate the host header.

Here we'll use `curl`.

```
curl -H "Host: foo.bar.com" http://<HOST_IP>/bar
curl -H "Host: bar.baz.com" http://<HOST_IP>/bar
curl -H "Host: bar.baz.com" http://<HOST_IP>/foo
```

----

### Enabling SSL

We want to have SSL for our services enabled. So let's create first the needed certificates for `foo.bar.com`:

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /work/tls.key \
-out /work/tls.crt -subj "/CN=foo.bar.com"
openssl dhparam -out dhparam.pem 4096
```
No openssl installed? No Problem.
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
kubectl create -f configs/ingress/ingress-ssl.yaml
curl -H "Host: foo.bar.com" https://<HOST_IP>/ssl --insecure
```

----

### Do it yourself

* Deploy an nginx and expose it using a service.
* Write an ingress manifest to expose the nginx service on port 80 listening on training.example.com/nginx
* Create an SSL certificate for training.example.com and create an ingress manifest for ssl and path /ssl.
* Access the nginx via `curl` or a browser on port 80 and 443.

----

### Whitelist

If you are using Ingress on your Kubernetes cluster it is possible to restrict access to your application based on dedicated IP addresses.

IP whitelisting to restrict access can be used by specifying the allowed client IP source ranges through the `ingress.kubernetes.io/whitelist-source-range` annotation.

----

### Whitelist (continued)

The value is a comma separated list of CIDR block, e.g. 10.0.0.0/24,1.1.1.1/32.

If you want to set a default global set of IPs this needs to be set in the config of the ingress-controller.

----

### The configuration:

```
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
```

----

### Testing with the annotation set

```
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
```

----

###  ...Without the annotation set

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

Using this annotation, you’re able to restrict who can access the applications in your Kubernetes cluster by IP.

----

### Path rewrites

Sometimes, you want to rewrite the path of a request to match up with the backend service.

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
```

----

### TCP

Ingress does not support TCP services (yet). 

For this you can use the flag `--tcp-services-configmap` to point to a ConfigMap where the key is the external port to use and the value is `<namespace/service name>:<service port>`. 

You can either use a number or the name of the port.

----

### Cleanup

```
kubectl delete -f configs/ingress/ingress-daemonset.yaml
```

----

### Create the controller and configmap

```
kubectl create -f configs/ingress/ingress-daemonset-tcp.yaml
kubectl create -f configs/ingress/ingress-tcp.yaml 
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-tcp-ingress-configmap
  namespace: kube-system
data:
  9000: "default/http-svc:80"
```

----

### Test your TCP service

```
kubectl -n kube-system get po -o wide
NAME                                                  READY     STATUS    RESTARTS   AGE       IP           NODE
default-http-backend-2198840601-hvcw9                 1/1       Running   0          24m       10.60.2.3    gke-cluster-1-default-pool-fddbe43a-wcpc
heapster-v1.3.0-1768742904-lwzg9                      2/2       Running   0          24m       10.60.0.6    gke-cluster-1-default-pool-fddbe43a-dpw0
kube-dns-3263495268-1mgxc                             3/3       Running   0          25m       10.60.1.2    gke-cluster-1-default-pool-fddbe43a-f622
kube-dns-3263495268-wlsxs                             3/3       Running   0          25m       10.60.0.3    gke-cluster-1-default-pool-fddbe43a-dpw0
kube-dns-autoscaler-2362253537-s5nwh                  1/1       Running   0          25m       10.60.0.2    gke-cluster-1-default-pool-fddbe43a-dpw0
kube-proxy-gke-cluster-1-default-pool-fddbe43a-dpw0   1/1       Running   0          25m       10.132.0.4   gke-cluster-1-default-pool-fddbe43a-dpw0
kube-proxy-gke-cluster-1-default-pool-fddbe43a-f622   1/1       Running   0          25m       10.132.0.3   gke-cluster-1-default-pool-fddbe43a-f622
kube-proxy-gke-cluster-1-default-pool-fddbe43a-wcpc   1/1       Running   0          25m       10.132.0.2   gke-cluster-1-default-pool-fddbe43a-wcpc
kubernetes-dashboard-490794276-hf8c0                  1/1       Running   0          25m       10.60.1.3    gke-cluster-1-default-pool-fddbe43a-f622
l7-default-backend-3574702981-x4wpk                   1/1       Running   0          25m       10.60.0.5    gke-cluster-1-default-pool-fddbe43a-dpw0
nginx-ingress-lb-c8xwd                                1/1       Running   0          14m       10.60.0.8    gke-cluster-1-default-pool-fddbe43a-dpw0
nginx-ingress-lb-f53wn                                1/1       Running   0          14m       10.60.1.5    gke-cluster-1-default-pool-fddbe43a-f622
nginx-ingress-lb-m7g3q                                1/1       Running   0          14m       10.60.2.6    gke-cluster-1-default-pool-fddbe43a-wcpc
```

----

```
(sleep 1; echo "GET / HTTP/1.1"; echo "Host: <nginx-ingress-lb-XXXX_IP>:9000"; echo;echo;sleep 2) | telnet <nginx-ingress-lb-XXXX_IP> 9000

Trying 10.60.0.8...
Connected to 10.60.0.8.
Escape character is '^]'.
HTTP/1.1 200 OK
Server: nginx/1.9.11
Date: Thu, 20 Apr 2017 07:53:30 GMT
Content-Type: text/plain
Transfer-Encoding: chunked
Connection: keep-alive

f
CLIENT VALUES:

1b
client_address=10.60.0.8

c
command=GET

c
real path=/

a
query=nil

14
request_version=1.1

25
request_uri=http://10.60.0.8:8080/

1


f
SERVER VALUES:

2a
server_version=nginx: 1.9.11 - lua: 10001

1


12
HEADERS RECEIVED:

16
host=10.60.0.8:9000

6
BODY:

14
-no body in request-
0

Connection closed by foreign host.
```

----

### UDP

Ingress does not support UDP services (yet). Again you can use a ConfigMap.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: udp-configmap-example
  namespace: kube-system
data:
  53: "kube-system/kube-dns:53"
```

You also need to tell the ingress controller where the service is deployed via an annotation. It's working in the same way as our TCP example.

----

### External Auth
### Example 1:

Use an external service (Basic Auth) located in `https://httpbin.org` 

```
kubectl create -f configs/ingress/ingress-auth.yaml
ingress "external-auth" created

kubectl get ing external-auth
NAME            HOSTS                         ADDRESS       PORTS     AGE
external-auth   external-auth-01.sample.com   172.17.4.99   80        13s
```

----

Test 1: no username/password (expect code 401)
```
curl -H "Host: external-auth-01.sample.com" http://104.155.113.47/
<html>
<head><title>401 Authorization Required</title></head>
<body bgcolor="white">
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx/1.13.0</center>
</body>
</html>
```

Test 2: valid username/password (expect code 200)
```
curl -H "Host: external-auth-01.sample.com" http://104.155.113.47/ -u 'user:passwd'
CLIENT VALUES:
client_address=10.60.2.8
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://external-auth-01.sample.com:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
authorization=Basic dXNlcjpwYXNzd2Q=
connection=close
host=external-auth-01.sample.com
user-agent=curl/7.51.0
x-forwarded-for=85.195.227.234
x-forwarded-host=external-auth-01.sample.com
x-forwarded-port=80
x-forwarded-proto=http
x-original-uri=/
x-real-ip=85.195.227.23485.195.227.234
x-scheme=http
BODY:
-no body in request-
```

Test 3: invalid username/password (expect code 401)
```
curl -H "Host: external-auth-01.sample.com" http://104.155.113.47/ -u 'user:password'
<html>
<head><title>401 Authorization Required</title></head>
<body bgcolor="white">
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx/1.13.0</center>
</body>
</html>
```

----

[Next up Volumes...](../05_volumes.md)

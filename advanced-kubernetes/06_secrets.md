In this section you will learn:
* How to create secrets
* use secrets

----

### Secrets in action

We want to share the value *some-base64-encoded-payload* under the key *my-super-secret-key* as a Kubernetes Secret for a pod.
First you need to base64-encode it like so:
```
echo -n some-base64-encoded-payload | base64
c29tZS1iYXNlNjQtZW5jb2RlZC1wYXlsb2Fk
```

Note the -n parameter with echo; this is necessary to suppress the trailing newline character.

----

### Creating the secret

We put the result of the base64 encoding into the secret manifest:
```
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  my-super-secret-key: c29tZS1iYXNlNjQtZW5jb2RlZC1wYXlsb2Fk
```
Currently there is no other type available, also no other "encryption" method despite base64 encoding.

----

### Using Secret

Create a pod with that secret
```
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: secret
  name: secret
spec:
  volumes:
    - name: "secret"
      secret:
        secretName: mysecret
  containers:
    - image: nginx
      name: webserver
      volumeMounts:
        - mountPath: "/tmp/mysec"
          name: "secret"
```
```
kubectl create -f secret.yaml -f pod_secret.yaml
```

----

### Validate Secret

```
kubectl exec -ti secret /bin/bash
cat /tmp/mysec/my-super-secret-key
```

----

One word of warning here, in case it’s not obvious: `secret.yaml` should never ever be committed to a source control system such as Git. If you do that, you’re exposing the secret and the whole exercise would have been for nothing.

----

### Working with secrets

A secret volume is used to pass sensitive information, such as passwords, to pods. You can store secrets in the Kubernetes API and mount them as files for use by pods without coupling to Kubernetes directly. 

Secret volumes are backed by tmpfs (a RAM-backed filesystem) so they are never written to non-volatile storage.
Important: You must create a secret in the Kubernetes API before you can use it

We'll make the `redis.conf` available to the container via a Volume using secrets

----

### Creating a Secret Using kubectl create secret

```
kubectl create secret generic db-user-pass --from-file=redis.conf
```

Validate that it's been created:
```
kubectl get secrets

kubectl describe secret db-user-pass
```
Note that neither get nor describe shows the contents of the file by default

----

### Using secret in a container

```
        volumeMounts:
        - mountPath: /usr/local/etc/redis
          name: config
          readOnly: true
      volumes:
        - name: config
          secret:
            secretName: db-user-pass
```

----

### Create a redis master

```
kubectl create -f redis-controller.yaml
```

----

### Validate that the redis is working
```
kubectl port-forward <PODNAME> 6379
```
```bash
telnet localhost 6379
CONFIG GET loglevel
```

----

###  Configure redis password
Uncomment `#requirepass foobared` in `redis.conf`
```
sed -i -e 's/#requirepass foobared/requirepass foobared/g' redis.conf
```
or just with your editor

----

### Update your secret

```
kubectl delete secret db-user-pass
kubectl create secret generic db-user-pass --from-file=redis.conf
```

Mounted Secrets are updated automatically but it's using its local ttl-based cache for getting the current value of the secret. The total time is kubelet sync period + ttl of secrets cache in kubelet (~1min). But as we can't do at the moment `kubectl apply --from-file` this isn' working. 

----

### Validate that the redis.conf is updated

Access to pod and validate the `redis.conf`

```
kubectl exec -ti <PODNAME> bash
cat /usr/local/etc/redis/redis.conf | grep foobar
```

----

### Validate that the redis is using our config
```
kubectl port-forward <redis-pod-name> 6379
```
```bash
telnet localhost 6379
```

----

### Do it yourself

* Create a mysql pod
* Set via an environment variable a password
* Create a service for that mysql
* Connect from another pod to the mysql database using the password (mysql container comes with mysql-client)
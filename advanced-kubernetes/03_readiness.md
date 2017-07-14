### What is Liveness and Readiness

Kubernetes health checks are divided into liveness and readiness probes.
Kubernetes is focusing on running containers in production. Production means that we need a way to ensure pods are actually running and healthy.

----

### ReadinessProbe

Readiness probes allow you to specify checks to verify if a Pod is ready for use. There are three methods that can be used to determine readiness. HTTP, Exec or TCPSocket.

```
readinessProbe:
  httpGet:
    path: /readiness
    port: 8080
  initialDelaySeconds: 20
  timeoutSeconds: 5
```
`initialDelaySeconds: 5` means that there is a delay of 5 seconds until the readiness probe will be called

`timeoutSeconds: 1` means that the readiness probe must respond within one second and needs to be HTTP 200 or greater and less than 400

----

### Liveness probes

Once the application pod is up and running we need a way to confirm that it’s healthy and ready for serving traffic.

Liveness probes are for situations when an app has crashed or isn't responding anymore. Just like the readiness probe, a liveness probe can be used to preform a set of health checks.

```
livenessProbe:
  httpGet:
    path: /healthcheck
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 1
```

`periodSeconds: 10` means that the check will be every 10 seconds performed

----

### Liveness Probes

As a simple example here is a health for a Go applications.

```
http.HandleFunc("/healthcheck", func(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("ok"))
}
http.ListenAndServe(":8080", nil)
```

----

And this needs to be added into the Pod manifest
```
livenessProbe:
  httpGet:
    path: /healthcheck
    port: 8080
  initialDelaySeconds: 15
  timeoutSeconds: 1
```

----

### Readiness Probes

A simple check if connections to the database are possible

```
http.HandleFunc("/readiness", func(w http.ResponseWriter, r *http.Request) {
  ok := true
  errMsg = ""

  // Check database
  if db != nil {
    _, err := db.Query("SELECT 1;")
  }
  if err != nil {
    ok = false
    errMsg += "Database not ok.\n"
  }

  if ok {
    w.Write([]byte("OK"))
  } else {
    // Send 503
    http.Error(w, errMsg, http.StatusServiceUnavailable)
  }
})
http.ListenAndServe(":8080", nil)
```

----

And this needs to be added into the Pod manifest

```
readinessProbe:
  httpGet:
    path: /readiness
    port: 8080
  initialDelaySeconds: 20
  timeoutSeconds: 5
```

Combining the readiness and liveness probes help ensure only healthy containers are running within the cluster. With the liveness probe you can monitor also downstream dependencies.

----

### Advanced liveness probe example

```
livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
          - name: X-Custom-Header
            value: Awesome
      initialDelaySeconds: 15
      timeoutSeconds: 1
```

`httpHeaders` describes a custom header to be used in HTTP probes

----

### Creating Pods with Liveness and Readiness Probes

Explore the healthy-monolith pod configuration:

Relevant part
```
      livenessProbe:
        httpGet:
          path: /healthz
          port: 81
          scheme: HTTP
        initialDelaySeconds: 5
        periodSeconds: 15
        timeoutSeconds: 5
      readinessProbe:
        httpGet:
          path: /readiness
          port: 81
          scheme: HTTP
        initialDelaySeconds: 5
        timeoutSeconds: 1
```

----

Create the healthy-monolith pod using
```
$ kubectl create -f configs/readiness/healthy-monolith.yaml
```

Thanks to Kelsey Hightower for this application

----

### View Pod details

Pods will not be marked ready until the readiness probe returns an HTTP 200 response. Use the `kubectl describe` to view details for the healthy-monolith Pod.

```
$ kubectl describe pod healthy-monolith | grep -i ready
    Ready:		True
  Ready 	True
Tolerations:	node.alpha.kubernetes.io/notReady:NoExecute for 300s
```

The healthy-monolith Pod logs each health check. Use the `kubectl logs` command to view them.

```
$ kubectl logs healthy-monolith
2017/07/14 13:29:53 Starting server...
2017/07/14 13:29:53 Health service listening on 0.0.0.0:81
2017/07/14 13:29:53 HTTP service listening on 0.0.0.0:80
10.36.0.1:57834 - - [Fri, 14 Jul 2017 13:30:02 UTC] "GET /healthz HTTP/1.1" Go-http-client/1.1
10.36.0.1:57840 - - [Fri, 14 Jul 2017 13:30:07 UTC] "GET /readiness HTTP/1.1" Go-http-client/1.1
10.36.0.1:57856 - - [Fri, 14 Jul 2017 13:30:17 UTC] "GET /healthz HTTP/1.1" Go-http-client/1.1
10.36.0.1:57858 - - [Fri, 14 Jul 2017 13:30:17 UTC] "GET /readiness HTTP/1.1" Go-http-client/1.1
10.36.0.1:57880 - - [Fri, 14 Jul 2017 13:30:27 UTC] "GET /readiness HTTP/1.1" Go-http-client/1.1
10.36.0.1:57894 - - [Fri, 14 Jul 2017 13:30:32 UTC] "GET /healthz HTTP/1.1" Go-http-client/1.1
```

----

### Experiment with Readiness Probes

In this tutorial you'll see how Kubernetes handels failed readiness probes. The monolith container supports the ability to force failures of it's readiness and liveness probes, again thanks to Kelsey!!!

Use the `kubectl port-forward` command to forward a local port to the health port of the healthy-monolith Pod.

```
$ kubectl port-forward healthy-monolith 10081:81
Forwarding from 127.0.0.1:10081 -> 81
Forwarding from [::1]:10081 -> 81
```
The command will stay open to host the port forwarding. Hit ctrl-Z, and then immediately run `bg` to move the port-forwarding command into the background, and you will have access to the /healthz and /readiness HTTP endpoints:

```
$ bg
[1]+ kubectl port-forward healthy-monolith 10081:81 &
```
----

Force the monolith container readiness probe to fail. Use the curl command to toggle the readiness probe status:

```
$ curl http://127.0.0.1:10081/readiness/status
Handling connection for 10081
```
Wait about 45 seconds and get the status of the healthy-monolith Pod using the kubectl get pods command. Note that 0 pods are currently ready:

```
$ kubectl get pods healthy-monolith
NAME               READY     STATUS    RESTARTS   AGE
healthy-monolith   0/1       Running   0          12m
```
Use the `kubectl describe` command to get more details about the failing readiness probe:

```
$ kubectl describe pods healthy-monolith
```

Notice the Ready flag has changed for the healthy-monolith pod:

```
$ kubectl describe pods healthy-monolith | grep -i ready
    Ready:		False
  Ready 	False
Tolerations:	node.alpha.kubernetes.io/notReady:NoExecute for 300s
```

----

Force the monolith container readiness probe to pass. Use the curl command to toggle the readiness probe status:

```
$ curl http://127.0.0.1:10081/readiness/status
Handling connection for 10081
```
Wait about 15 seconds and get the status of the healthy-monolith Pod using the kubectl get pods command, note that 1/1 are now ready:

```
$ kubectl get pods healthy-monolith
NAME               READY     STATUS    RESTARTS   AGE
healthy-monolith   1/1       Running   0          24m
```

----

### Experiment with Liveness Probes

Building on what you learned in the previous tutorial use the kubectl port-forward and curl commands to force the monolith container liveness probe to fail. Observe how Kubernetes responds to failing liveness probes.

```
$ curl http://127.0.0.1:10081/healthz/status
```

----

### Quiz

What happened when the liveness probe failed?
What events where created when the liveness probe failed?

----


### Cleanup

Run the `fg` command followed by hitting ctrl-c, to stop the port-forwarding activity which we backgrounded earlier.
```
$ fg
kubectl port-forward healthy-monolith 10081:81
^C
```

Delete the health-monolith deployment:
```
$ kubectl delete -f configs/readiness/healthy-monolith.yaml
```

----

In this section you learned:
* How Kubernetes supports application monitoring using liveness and readiness probes.
* How to add readiness and liveness probes to Pods
* What happens when probes fail.

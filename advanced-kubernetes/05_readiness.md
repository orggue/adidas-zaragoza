### What is Liveness and Readiness

Kubernetes health checks are divided into liveness and readiness probes. 
Kubernetes is focusing on running containers in production. Production means that we need a way to ensure pods are actually running and healthy. To achieve this, Kubernetes provides a way to declare if a pod is ready using a readiness probe.

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

`timeoutSeconds: 1` means that the rediness probe must respond within one second and needs to be HTTP 200 or greater and less than 400

----

### Liveness probes

Once the application pod is up and running we need a way to confirm that it’s healthy and ready for serving traffic. If your application is crashing Kubernetes will see that the app has terminated and will restart it. Liveness probes are for situations when an app has crashed or isn't responding anymore. Just like the readiness probe, a liveness probe can be used to preform a set of health checks via HTTP or exec.

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

We are reusing the /ping endpoint to verify the health of the influxdb pod. It’s also possible to use another endpoint or leverage a command line utility in the container via the exec probe.

Combining the readiness and liveness probes help ensure only healthy containers are running within the cluster. With the liveness probe you can monitor also downstream dependencies.

----

### Example implementations

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

A simple check if I can connect to the database

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
    errMsg += "Database not ok.¥n"
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

### Tutorial: Creating Pods with Liveness and Readiness Probes

Explore the influxdb pod configuration:

```
apiVersion: v1
kind: Pod
metadata:
  name: "healthy-monolith"
  labels:
    app: monolith
spec:
  containers:
    - name: monolith
      image: kelseyhightower/monolith:1.0.0
      ports:
        - name: http
          containerPort: 80
        - name: health
          containerPort: 81
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

Create the healthy-monolith pod using 
```
kubectl create -f configs/healthy-monolith.yaml
```

Thanks to Kelsey for this application

----

### View Pod details

Pods will not be marked ready until the readiness probe returns an HTTP 200 response. Use the kubectl describe to view details for the healthy-monolith Pod.

The healthy-monolith Pod logs each health check. Use the `kubectl logs` command to view them.

----

### Experiment with Readiness Probes

In this tutorial you'll see how Kubernetes handels failed readiness probes. The monolith container supports the ability to force failures of it's readiness and liveness probes, again thanks to Kelsey!!!

Use the `kubectl port-forward` command to forward a local port to the health port of the healthy-monolith Pod.

````
kubectl port-forward healthy-monolith 10081:81
```
You now have access to the /healthz and /readiness HTTP endpoints exposed by the monolith container.
Experiment with Readiness Probes

----

Force the monolith container readiness probe to fail. Use the curl command to toggle the readiness probe status:

```
curl http://127.0.0.1:10081/readiness/status
````
Wait about 45 seconds and get the status of the healthy-monolith Pod using the kubectl get pods command:

```
kubectl get pods healthy-monolith
```
Use the kubectl describe command to get more details about the failing readiness probe:

```
kubectl describe pods healthy-monolith
```
Notice the events for the healthy-monolith Pod report details about failing readiness probe.

----

Force the monolith container readiness probe to pass. Use the curl command to toggle the readiness probe status:

```
curl http://127.0.0.1:10081/readiness/status
```
Wait about 15 seconds and get the status of the healthy-monolith Pod using the kubectl get pods command:

```
kubectl get pods healthy-monolith
```

----

In this lab you learned that Kubernetes supports application monitoring using liveness and readiness probes. You also learned how to add readiness and liveness probes to Pods and what happens when probes fail.
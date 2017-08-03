### Liveness and Readiness

A way to ensure pods are actually running and healthy.

---

* health checks are divided into liveness and readiness probes.
* Kubernetes is focusing on running containers in production.
  * Production means that we need a way to ensure pods are actually running and
    healthy before serving traffic.

---

Readiness probes allow you to specify checks to verify if a Pod is ready for use. There are three methods that can be used to determine readiness. HTTP, Exec or TCPSocket.

```
readinessProbe:
  httpGet:
    path: /readiness
    port: 8080
  initialDelaySeconds: 20
  timeoutSeconds: 5
```

---

`initialDelaySeconds: 5` means that there is a delay of 5 seconds until the readiness probe will be called

`timeoutSeconds: 1` means that the readiness probe must respond within one second and needs to be HTTP 200 or greater and less than 400

---

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

---

`periodSeconds: 10` means that the check will be every 10 seconds performed

---

### Liveness Probes

As a simple example here is a health for a Go applications.

```
http.HandleFunc("/healthcheck", func(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("ok"))
}
http.ListenAndServe(":8080", nil)
```

---

And this needs to be added into the Pod manifest
```
livenessProbe:
  httpGet:
    path: /healthcheck
    port: 8080
  initialDelaySeconds: 15
  timeoutSeconds: 1
```

---

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

---

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

---

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

---

### Worksheet: 03_readiness.md

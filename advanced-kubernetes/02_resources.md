### Resource Management

In this section we'll discuss:
* Quality of Service (QoS)
* Resource Quotas

---

### The resource model

What exactly is a resource in Kubernetes?

**CPU & Memory**
* Accounted
* Scheduled
* Isolated

**Local Storage (Disk or SSD)**
* Accounted (restriction to single partition /)

**Nvidia GPU**
* Alpha support (1 GPU per-node)

---

### Requests and Limits

Request:

How much of a resource a container is asking to use with a strong guarantee of availability.
* CPU (millicores, 1/1000 of one core)
* RAM (bytes)

Scheduler will not over-commit requests.  

---

### Requests and Limits

Limit: (hard limit)
* Maximum amount of a resource a container can access.
* Scheduler ignores limits.

---

### Requests and Limits

Repercussions:
* Usage > Request: resources might be available.
* Usage > Limit: killed or throttled.

---

### Setting resource limits


* If a pod is scheduled successfully, the container is guaranteed the amount of resources requested.
* Scheduling is based on requests, not limits.
* Set resource requests so Kubernetes can schedule containers on different nodes.
* Set resource limits to prevent an application from taking up all resources.

This is why you should ALWAYS set both resource requests and resource limits.

---

### Compressible Resource Guarantees

Kubernetes only supports CPU at the moment.

* Pods are guaranteed to get the amount of CPU they request.
* This isn't fully guaranteed today because CPU isolation is at the container level. Pod level cgroups will be introduced soon to achieve this goal.
* Excess CPU resources will be distributed based on the amount of CPU requested.

---

### Compressible Resource Guarantees

Example (1 vCPU available):
* Container A requests 600 milli CPUs.
* Container B requests for 300 milli CPUs.
* Both containers try to use as much CPU as they can. Then the extra 100 milli CPUs will be distributed to A and B in a 2:1 ratio.

Pods will be throttled if they exceed their limit. If limit is unspecified, pods can use excess CPU when available.

---

### Incompressible Resource Guarantees

Kubernetes only supports memory at the moment.

* Pods will get the amount of memory they request. If they exceed their memory request, they could be killed (if some other pod needs memory).
* If pods consume less memory than requested, they will not be killed (except in cases where system tasks or daemons need more memory).

When Pods use more memory than their limit, will be killed by the kernel.

---

### Quality of Service Classes
Guaranteed: highest protection.

* request > 0 && limit == request

* If `limits` and optionally `requests` (not equal to `0`) are set for all resources across all containers and they are *equal*, then the pod is classified as **Guaranteed**.

---

### Guaranteed

```yaml
containers:
    name: foo
        resources:
            limits:
                cpu: 10m
                memory: 1Gi
    name: bar
        resources:
            limits:
                cpu: 100m
                memory: 100Mi
```

---

### Guaranteed

```yaml
containers:
    name: foo
        resources:
            limits:
                cpu: 10m
                memory: 1Gi
            requests:
                cpu: 10m
                memory: 1Gi

    name: bar
        resources:
            limits:
                cpu: 100m
                memory: 100Mi
            requests:
                cpu: 100m
                memory: 100Mi
```

---

### Best Effort: lowest protection

* request == 0 (limit == node size)

- If `requests` and `limits` are not set for all of the resources, across all containers, then the pod is classified as **Best-Effort**.

```yaml
containers:
    name: foo
        resources:
    name: bar
        resources:
```

---

### Burstable: medium protection

* request > 0 && limit > request

- If `requests` and optionally `limits` are set (not equal to `0`) for one or more resources across one or more containers, and they are *not equal*, then the pod is classified as **Burstable**.

---

Container `bar` has no resources specified.

```yaml
containers:
    name: foo
        resources:
            limits:
                cpu: 10m
                memory: 1Gi
            requests:
                cpu: 10m
                memory: 1Gi

    name: bar
```

---

Containers `foo` and `bar` have limits set for different resources.

```yaml
containers:
    name: foo
        resources:
            limits:
                memory: 1Gi

    name: bar
        resources:
            limits:
                cpu: 100m
```

---

Container `foo` has no limits set, and `bar` has neither requests nor limits specified.

```yaml
containers:
    name: foo
        resources:
            requests:
                cpu: 10m
                memory: 1Gi

    name: bar
```

---

How is “protection” implemented?
* CPU: some Best Effort/Burstable container using more than its request is throttled.
* Memory: some Best Effort/Burstable container using more than its request is killed.

---

### Worksheet: 02_resources.md

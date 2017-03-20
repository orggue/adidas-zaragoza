### Resource Management

In this section we'll discuss about:
* QoS
* Resource Quotas
* Namespaces
* Resource Limits

----

### The resource model

What exactly is a resource in Kubernetes?

CPU & Memory
* Accounted
* Scheduled
* Isolated
Local Storage (Disk or SSD)
* Accounted (restriction to single partition /)
Nvidia GPU
* Alpha support (1 GPU per-node)

----

### Requests and Limits

Request: (soft limit)
How much of a resource a container is asking to use with a strong guarantee of availability
* CPU (millicores, 1/1000 of one core)
* RAM (bytes)
Scheduler will not over-commit requests
Limit: (hard limit)
* max amount of a resource a container can access
* scheduler ignores limits
Repercussions:
* Usage > Request: resources might be available
* Usage > Limit: killed or throttled

If a pod is successfully scheduled, the container is guaranteed the amount of resources requested. Scheduling is based on requests and not limits

----

### Setting resource limits

* Set resource request that Kubernetes can do a good job of scheduling containers on different instances to use as much potential capacity as possible. 
* Set resource limit that in the case you have a application trying eating up all ressources (java :-)), it can be prevented.

This is why you should ALWAYS set both resource requests and resource limits.

----

### Compressible Resource Guarantees

Kubernetes only supports CPU at the moment

* Pods are guaranteed to get the amount of CPU they request
* This isn't fully guaranteed today because cpu isolation is at the container level. Pod level cgroups will be introduced soon to achieve this goal.
* Excess CPU resources will be distributed based on the amount of CPU requested. 

Example (1 vCPU available): 
* Container A requests 600 milli CPUs
* Container B requests for 300 milli CPUs
* Both containers trying to use as much CPU as they can. Then the extra 100 milli CPUs will be distributed to A and B in a 2:1 ratio

Pods will be throttled if they exceed their limit. If limit is unspecified, then the pods can use excess CPU when available.

----

### Incompressible Resource Guarantees

Kubernetes only supports memory at the moment

* Pods will get the amount of memory they request, if they exceed their memory request, they could be killed (if some other pod needs memory)* If pods consume less memory than requested, they will not be killed (except in cases where system tasks or daemons need more memory)

When Pods use more memory than their limit, a process that is using the most amount of memory, inside one of the pod's containers, will be killed by the kernel.


----

### Quality of Service Classes
Guaranteed: highest protection
• request > 0 && limit == request

- If `limits` and optionally `requests` (not equal to `0`) are set for all resources across all containers and they are *equal*, then the pod is classified as **Guaranteed**.

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

----

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

----

Best Effort: lowest protection
• request == 0 (limit == node size)

- If `requests` and `limits` are not set for all of the resources, across all containers, then the pod is classified as **Best-Effort**.

```yaml
containers:
	name: foo
		resources:
	name: bar
		resources:
```

----

Burstable: medium protection
• request > 0 && limit > request

- If `requests` and optionally `limits` are set (not equal to `0`) for one or more resources across one or more containers, and they are *not equal*, then the pod is classified as **Burstable**.

Container `bar` has not resources specified.

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

----

Container `foo` and `bar` have limits set for different resources.

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

----

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

----

How is “protection” implemented?
* CPU: some Best Effort/Burstable container using more than its request is throttled
    * CPU shares + CPU quota
* Memory: some Best Effort/Burstable container using more than its request is killed
    * OOM score + user-space evictions

----

Demo goes here


----

### Resource Quota

Per-namespace
* maximum request and limit across all pods
* applies to each type of resource (CPU, mem)
* user must specify request or limit
* maximum number of a particular kind of object
Ensure no user/app/department abuses the cluster

Applied at admission time

Just another API object

----

Demo goes here

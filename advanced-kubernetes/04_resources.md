### Resource Management

In this section we'll discuss about:
* Namespaces
* Resource Quotas
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

### Isolation

Advantages:
* No noisy neighbours
* You don't need to worry about interference
* Repeated runs of same app gives ~equal performance
* Makes it easier to create performance SLAs
Disadvantages:
* How do I know how much I need?
    * system can help with this, monitoring, testing, ...
* Utilization - strong isolation: unused resources get lost
    * system has to reserve for requester
    * can be mitigated wth overcommitment --> risk!!

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


----

### Setting resource limits

* Set resource request that Kubernetes can do a good job of scheduling containers on different instances to use as much potential capacity as possible. 
* Set resource limit that in the case you have a application trying eating up all ressources (java :-)), it can be prevented.

This is why you should ALWAYS set both resource requests and resource limits.

----



----

### Quality of Service Classes
Guaranteed: highest protection
* request > 0 && limit == request
Best Effort: lowest protection
* request == 0 (limit == node size)
Burstable: medium protection
* request > 0 && limit > request

How is “protection” implemented?
* CPU: some Best Effort/Burstable container using more than its request is throttled
    * CPU shares + CPU quota
* Memory: some Best Effort/Burstable container using more than its request is killed
    * OOM score + user-space evictions

----

### Namespaces

By default, all resources in Kubernetes are created in the default namespace. 

A pod will run without CPU and memory requests/limits. A namespace allows to partition a cluster into logically named group. Each namespace provides :

* a unique scope for resources to avoid name collisions
* access policies
* ability to specify constraints for resource consumption

This allows a Kubernetes cluster to share resources by multiple groups and provide different levels of access and resource quota to users. Resources created in one namespace are hidden from other namespaces. Multiple namespaces can be created, each potentially with different constraints.

----




Like Docker, Kubernetes provides support for cgroups and placing limits on CPU and memory usage for each container in a pod. 

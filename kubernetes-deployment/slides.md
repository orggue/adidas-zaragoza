---
title: Kubernetes Deployments
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Kubernetes Deployments

---

### What will you learn?

* Slides

  * How to do some simple deployment startegies with Kubernetes
  * Some of the drawbacks of these methods
  
* Exercises

  *  Practice some deployments in your cluster `kubectl`

---

### Native Kubernetes Updates

  * RollingUpdate
  * Recreate

### Deployments

Three main types of deployments we will address

  * Canary
  * A/B
  * Blue Green

---

### Canary

Why is it called canary?


---

### Canary

To test if the new version causes havoc in your system

---

### A/B

Have two versions running next to each other distributed traffic
To tests features
"Does this button get used more if it is red?"

---


### Blue Green

Have two versions running next to each other and switch back and forth between them

---

### With Selectors

It can be accomplished with selectors of a service on deployments

### The Problem

It means you need to be aware of how your pods are scaling
to measure the quantity of your deployments

There are no guarantees of distribution equal to the ratio of pods

Seperate deployments for each version of a service

Lots of manual intervention

### Other tools

Other tools can perform deployment strategies better

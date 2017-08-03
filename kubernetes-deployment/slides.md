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

Have two versions running next with distributed traffic

---


### Blue Green

Have two versions running next to each other and switch back and forth between them

---

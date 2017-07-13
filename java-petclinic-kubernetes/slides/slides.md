## Spring PetClinic on Kubernetes
### How to run Java apps on Kubernetes
&nbsp;
### 
<img width="400" src="slides/img/cs-logo-transparent-background.png">
---

## Overview

You should leave here knowing:

 - How to build Java containers
 - How to deploy Java apps to Kubernetes
 - Unique challenges in running Java in a container environment

---

## Prerequisites

 - Java and Spring knowledge
 - Docker essentials
 - Kubernetes essentials
 - Access to a GKE cluster

---

## Docker and the JVM - the Good

 - Java runs on Linux, so it can easily run in Docker container
 - Good support - base images for all JDK, JRE and Maven versions

## Building Java apps

 - Just use Maven or any other build tool
 - Maven cache will not be used
 - But Docker layer caching makes up for it
 - Supported base image for Maven

## Docker and the JVM - the Bad

 - Java memory management designed be single process on machine
 - No more sharing of JVM by deploying to Java App Server (Tomcat)
 - JVM before version 9 doesn't respect container memory limits
 
## Solutions

 - 

## TODO

slides

resource limits,requests


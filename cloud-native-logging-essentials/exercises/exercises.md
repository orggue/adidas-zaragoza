---
title: Cloud Native Logging Essentials
revealOptions:
    transition: 'none'
    slideNumber: 'true'
---

# Cloud Native Logging Essentials - Exercises

---

## Inspecting logs with `kubectl logs`

* We will deploy a pod, deployment and service

* Inspect the logs

* Make changes and inspect the logs again


---


### Preparation

* Go to `training-modules/cloud-native-logging-essentials/exercises`

* This directory contains this slide deck

* The `files` directory contains code, k8s manifests and a `Dockerfile`

* Edit `deployment.yaml` and replace the string `$YOUR_USERNAME` with your VM username

---


### Build the image

* Build the Docker image for `server.js`

* `gcloud docker -- build -t eu.gcr.io/$YOUR_USERNAME/server -f Dockerfile_node .`


---


### Push the image

*  The image will be pushed to the Google Container Registry (GCR)

* `gcloud docker -- push eu.gcr.io/$YOUR_USERNAME/server`


---


###  Create a deployment

* `kubectl create -f deployment.yaml`


---


### Check the logs

* `kubectl logs $POD_NAME`

* If the pod `STATUS` is `ContainerCreating` so you won't see logs yet

---


### Change the code

* Add `console.log(request)` to `server.js` inside the request loop

* Hack, hack


---


### Delete the deployment


* `kubectl delete deployment server`


---


### Build & push again

* `gcloud docker -- build -t eu.gcr.io/$YOUR_USERNAME/server -f Dockerfile_node .`

* `gcloud docker -- push eu.gcr.io/$YOUR_USERNAME/server`


---


### Now deploy the service again

* `kubectl -f create service.yaml`


---


### Now follow the logs

* `kubectl logs -f $POD_NAME`


---

### Enable port forwarding

* SSH into the VM with another session

* Port forwarding in the background

* `kubectl port-forward $POD_NAME 8080:8080 &`


---


### Hit the server with curl

* `curl localhost:8080`


* Check the logs in the other terminal
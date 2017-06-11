### Storage

A Pod is made up of one or several containers plus some data volumes that can be mounted inside the containers. In this section you will learn how to: 

* define a deployment backed by a emptyDir
* define a deployment backed by a emptyDir(memory backed storage)
* define a deployment backed by a hostPath 
* define a deployment backed by a persistent volume and persistent volume claim 
* define a deployment backed by a persistent volume and persistent volume claim using a StorageClass

Before going further, you can spend time on these little exercises. They will clarify how volumes are defined in Pods.

### emptyDir

* In this exercise we will demonstrate the use of an emptyDir as a volume.

----
The volume is of type `emptyDir`. The kubelet will create an empty directory on the node when the Pod is scheduled. Once the Pod is destroyed, the kubelet will delete the directory. This is the simplest type of volumes used in Kubernetes.

```
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busy
    image: busybox
    volumeMounts:
    - name: test
      mountPath: /busy
    command:
      - sleep
      - "3600"
  - name: box
    image: busybox
    volumeMounts:
    - name: test
      mountPath: /box
    command:
      - sleep
      - "3600"
  volumes:
  - name: test
    emptyDir: {} 
``` 

Once the pods are deployed we can exec into one pod, create a file, then verify the existence of that file in the other pod.

```
$ kubectl exec -ti busybox -c box -- touch /box/foobar
$ kubectl exec -ti busybox -c busy -- ls -l /busy
total 0
-rw-r--r--    1 root     root             0 Nov 19 16:26 foobar
```
----


### emptyDir - memory backed storage

* This excerise is similar to the above but with a slight twist, this time instead of just an emptyDir we'll demonstrate an emptyDir backed by a memory backed storage.





### hostPath

* In this excecise we'll demonstrate the usefulness of having a hostPath by mounting a directory and writing to it.

```
apiVersion: v1
kind: Pod
metadata:
  name: alpine
spec:
  containers:
  - name: alp
    image: alpine
    volumeMounts:
    - name: test
      mountPath: /tmp
    command:
      - sleep
      - "3600"
  volumes:
  - name: test
    hostPath:
        path: /tmp
```

Once the pod has been deployed we can echo a word into a file in that directory and verify it's existence from the host. Since we're running this in minikube the host isn't our host but 
minikube therefore we'll need to run the command through minikube.

```
$ kubectl -it alpine -- /bin/sh -c "echo 'test' >> /tmp/test.txt" 
$ minikube ssh cat /tmp/test.txt
```

### Persistent Volumes and Claims

* In this exercise we'll demonstrate the use of Persistent Volumes(PV) and Persistent Volume Claims(PVC).

First we need to create a PV, otherwise we won't have anything to claim, for the sake of this exercise we'll be using a hostPath volume. The definition of this is given below.

```
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv0001
  labels:
    type: local
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/somepath/data01"
```

----

Create the PV and check it's status with the `get` and `describe` command.

```
kubectl create -f pv.yaml
kubectl get pv
kubectl describe pv
```

----

Next we need to create a PVC which takes a slice of the PV defined above. The definition of this is given below.

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

----

Create the PVC and check it's status with the `get` and `describe` command.

```
kubectl create -f pvc.yaml
kubectl get pvc
kubectl describe pvc
```

----

Lastly we'll create a Pod which will use the previously described PVC to claim some storage for use. The definition for this is given below.

```
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busy
    image: busybox
    volumeMounts:
    - name: test
      mountPath: /busy
    command:
      - sleep
      - "3600"
  - name: box
    image: busybox
    volumeMounts:
    - name: test
      mountPath: /box
    command:
      - sleep
      - "3600"
  volumes:
    - name: test
      persistentVolumeClaim:
        claimName: myclaim
```

----

Create the pod and check it's status via the `get`and `describe` command. 

```
kubectl create -f pod_pvc.yaml
kubectl get pods
kubectl describe pods
```

### PV and PVC using StorageClass


### Dynamic Provisioning

While handling volumes with a persistent volume definition and abstracting the storage provider using a claim is powerful, an administrator of the cluster still needs to create those volumes in the first place.

Since Kubernetes 1.4 it is possible to use dynamic provisioning of persistent volumes (beta)

A new API resource has been introduced in Kubernetes 1.2 called StorageClass. If configured and a user requests a claim, this claim will be created even if an existing pv does not exist. The volume provisioner defined in the StorageClass will dynamically create the volume.

Here is an example of a StorageClass on AWS:

```
kind: StorageClass
apiVersion: storage.k8s.io/v1beta1
metadata:
  name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
```

You might be interested to test this using this [example](https://github.com/kubernetes/kubernetes/tree/master/examples/experimental/persistent-volume-provisioning).

----

### Do it yourselfe

* Create a PV and PVC using HostPath /somepath/log01
* Use the PVC in the nginx POD (Deployment) and map it to /var/log
* Validate the existence

As the host-folder will be empty, there are no logs. Also not in the container.

----

### Cheat

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv0002
  labels:
    type: local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/somepath/log01"

---

kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: logclaim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi

---

apiVersion: v1
kind: Pod
metadata:
  name: nginx-logs
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: logs
      mountPath: /var/log
    command:
      - sleep
      - "3600"
  volumes:
    - name: logs
      persistentVolumeClaim:
        claimName: logclaim

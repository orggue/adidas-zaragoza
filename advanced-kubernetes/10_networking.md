### Networking with Flannel


In this section we'll look at running Flannel as the pod network within Kubernetes.

----

### Example

For this hands on exercise we will set up a single node Kubernetes cluster using kubeadm.

Setup - 

Create (ubuntu) instance on Google Cloud (>= 2 CPU)

```
gcloud compute instances create kube-test --image-project ubuntu-os-cloud --image-family ubuntu-1604-lts --zone europe-west1-d --machine-type n1-standard-2
```

----

Install kubernetes via kubeadm

Copy script from `./resources/installK8sWithFlannel.sh`

----

Some follow up steps...

```
sudo cp /etc/kubernetes/admin.conf $HOME/
sudo chown $(id -u):$(id -g) $HOME/admin.conf
export KUBECONFIG=$HOME/admin.conf
````

----

Verify cluster is up:

```
$ kubectl cluster-info
```

----

##REMOVE THIS##

Add RBAC role for Flannel

```
kubectl create -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel-rbac.yml --validate=false
```

----

Several Flannel resources were created on our cluster. Let's take a look at each of them.


First there is a Flannel Service Account

```
$ kubectl describe sa flannel --namespace=kube-system
Name:  		flannel
Namespace:     	kube-system
Labels:		<none>
Annotations:   	kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","kind":"ServiceAccount","metadata":{"annotations":{},"name":"flannel","namespace":"kube-system"}}


Image pull secrets:    	<none>

Mountable secrets:     	flannel-token-0vwgw

Tokens:                	flannel-token-0vwgw
```

----

We also created a Config Map. This contains two sets of Configuration. The CNI configuration and the Flannel configuration.


```
$ kubectl describe cm kube-flannel-cfg --namespace=kube-system
Name:  		kube-flannel-cfg
Namespace:     	kube-system
Labels:		app=flannel
       		tier=node
Annotations:   	kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"v1","data":{"cni-conf.json":"{\n  \"name\": \"cbr0\",\n  \"type\": \"flannel\",\n  \"delegate\": {\n    \"isDefaultGateway\": true\n  }\...

Data
====
cni-conf.json:
----
{
  "name": "cbr0",
  "type": "flannel",
  "delegate": {
    "isDefaultGateway": true
  }
}

net-conf.json:
----
{
  "Network": "10.244.0.0/16",
  "Backend": {
    "Type": "vxlan"
  }
}
```

----

The network in the Flannel configuration should (as seen above) should match the POD network CIDR. Let's verify this...

```
$ kubectl get nodes -o json | grep CIDR
                "podCIDR": "10.244.0.0/24",
```

----

The last resource we deploye is a Daemon Set. This ensures that a Flannel pod will be deployed on every node.
We can see that the pod has two containers. The flannel daemon (kube-flannel) and a container for installing the cni (install-cni).

```
$ kubectl describe ds kube-flannel-ds --namespace=kube-system
Name:  		kube-flannel-ds
Selector:      	app=flannel,tier=node
Node-Selector: 	beta.kubernetes.io/arch=amd64
Labels:		app=flannel
       		tier=node
Annotations:   	kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"extensions/v1beta1","kind":"DaemonSet","metadata":{"annotations":{},"labels":{"app":"flannel","tier":"node"},"name":"kube-flannel-ds","n...
Desired Number of Nodes Scheduled: 1
Current Number of Nodes Scheduled: 1
Number of Nodes Scheduled with Up-to-date Pods: 1
Number of Nodes Scheduled with Available Pods: 0
Number of Nodes Misscheduled: 0
Pods Status:   	1 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:      		app=flannel
       			tier=node
  Service Account:     	flannel
  Containers:
   kube-flannel:
    Image:     	quay.io/coreos/flannel:v0.7.1-amd64
    Port:
    Command:
      /opt/bin/flanneld
      --ip-masq
      --kube-subnet-mgr
    Environment:
      POD_NAME:		 (v1:metadata.name)
      POD_NAMESPACE:   	 (v1:metadata.namespace)
    Mounts:
      /etc/kube-flannel/ from flannel-cfg (rw)
      /run from run (rw)
   install-cni:
    Image:     	quay.io/coreos/flannel:v0.7.1-amd64
    Port:
    Command:
      /bin/sh
      -c
      set -e -x; cp -f /etc/kube-flannel/cni-conf.json /etc/cni/net.d/10-flannel.conf; while true; do sleep 3600; done
    Environment:       	<none>
    Mounts:
      /etc/cni/net.d from cni (rw)
      /etc/kube-flannel/ from flannel-cfg (rw)
  Volumes:
   run:
    Type:      	HostPath (bare host directory volume)
    Path:      	/run
   cni:
    Type:      	HostPath (bare host directory volume)
    Path:      	/etc/cni/net.d
   flannel-cfg:
    Type:      	ConfigMap (a volume populated by a ConfigMap)
    Name:      	kube-flannel-cfg
    Optional:  	false
Events:
  FirstSeen    	LastSeen       	Count  	From   		SubObjectPath  	Type   		Reason 			Message
  ---------    	--------       	-----  	----   		-------------  	--------       	------ 			-------
  27m  		27m    		1      	daemon-set     			Normal 		SuccessfulCreate       	Created pod: kube-flannel-ds-fqnh5
 ```

----

Now that everything seems to be up and running. Let's try launching an app and see if pods can communicate....

The famous guestbook

```
kubectl create -f https://raw.githubusercontent.com/kubernetes/kubernetes/master/examples/guestbook/all-in-one/guestbook-all-in-one.yaml --validate=false
```

----

We can access this via the frontend service.

----


Let's try switching the Flannel backend to UDP


```
kubectl edit cm kube-flannel-cfg --validate=false --namespace=kube-system
```

We just need to restart flannel for the change to take effect.

----



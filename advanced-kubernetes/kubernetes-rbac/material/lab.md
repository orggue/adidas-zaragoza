---
pagetitle: Kubernetes RBAC lab
---

# Kubernetes RBAC lab

This lab is about Role Based Access Control; the mechanism of how we can control permissions granted to humans or service accounts.

In this lab, we'll use Google's Container Engine (GKE) to experiment with RBAC. Each participant will get four user accounts, one admin account and three accounts that initially have no access to the Kubernetes cluster. Your goal is to implement the example in the presentation; granting permissions to the three accounts with your admin account.

# Before you start
## Setting up
1. Download the provided files
2. Start your container with `./start_container.sh`

## Kubectl + accounts
There are three four different kubectl commands available

- `admin-kubectl`
- `alice-kubectl`
- `bobby-kubectl`
- `monkey-kubectl`

Each of these corresponds to a different google account.  Initially, we'll only use `admin-kubectl`, given that the other accounts don't have any permissions yet.

The names of these accounts vary per participant, and are stored in `$ALICE`, `$BOBBY` and `$MONKEY` (you won't need to refer to the admin account; it already has all permissions).

For example:
```
$ echo $ALICE; echo $BOBBY; echo $MONKEY

alice-3@rbac-workshop-test.iam.gserviceaccount.com
bobby-3@rbac-workshop-test.iam.gserviceaccount.com
monkey-3@rbac-workshop-test.iam.gserviceaccount.com
```


## Editing files
The `./start-container.sh` script mounts your current working directory. Edit your files outside of the container; no editor is installed by default in the `google/cloudsdk` image that we're using.

# Checking that the other accounts do not have access
Before we're going to implement the example, let's verify that the other accounts indeed have no access.

```
$ alice-kubectl get pods
```

This will cause a permission error.  Try the same for the `bobby` and `monkey` accounts.

# Inspecting the default (cluster)roles
## Clusterroles
Run the following command to inspect the available clusterroles. There are global to whole cluster.

`$ admin-kubectl get clusterroles`

## Details of clusterroles
You can inspect a cluster role by asking kubectl to output yaml; pretty printing is not yet supported in the beta release of RBAC.

For example, let's see what the 'admin' cluster role is about:

`$ admin-kubectl get clusterrole admin --output yaml`

## Roles
Roles are scoped to a namespace, just like Pods. We can find the roles predefined by Kubernetes by running:
```
admin-kubectl get roles --all-namespaces

NAMESPACE     NAME                                        AGE
kube-public   system:controller:bootstrap-signer          8h
kube-system   extension-apiserver-authentication-reader   8h
kube-system   system:controller:bootstrap-signer          8h
kube-system   system:controller:token-cleaner             8h
```


# Implementing the example
We're going to implement the situation is as shown below.

![example](img/what-is-rbac.pdf)


We'll perform the following steps

- Creating namespaces
- Defining roles
- Creating role bindings
- Verifying that it is working

## Creating namespaces
Create the `production` and `test` namespaces with `admin-kubectl namespace create <NAME>`

## Alice the `app-admin`

Roles are resources in Kubernetes, just like Pods and Deployments. 
Typically, they are written in a text file, and applied to the Kubernetes cluster with `kubectl apply`.
Alternatively, one can use `kubectl create role`.


Let's create the `app-admin` role first. This role will be able to list, get the details, create and delete deployments on the production namespace.

```
  admin-kubectl create role app-admin \
    --verb=get \
    --verb=list \
    --verb=create \
    --verb=delete \
    --resource=deployments \
    --namespace=production
```

According to the diagram, we'll have make Alice an `app-admin`, in order to give her permissions to create Deployments.

Let's first check that alice indeed cannot create a new deployment

```
alice-kubectl run my-web-app --image=nginx --namespace=production
```
This command is a shortcut to create a deployment with the name `my-web-app` with one container of the `nginx` image.

For your convenience, we have already set the environmental variable `$ALICE` to point to her username.
Let's create the role binding.

```
  admin-kubectl create rolebinding teamleads \
    --role=app-admin \
    --user=$ALICE \
    --namespace=production
```


### Verifying that Alice can deploy
Now, alice should be able to create a deployment.
```
alice-kubectl run my-web-app --image=nginx --namespace=production
```

Check that indeed one container is running.


Now try to _update_ the deployment, by scaling it up to two pods
```
alice-kubectl scale deployment my-web-app --replicas=2 --namespace=production
```

This will fail, because we have not granted alice the `container.deployments.update` permission to Alice.
If we look at the diagram, we see that the Developer role should be allowed to update deployments.


## The `developers` role
Create a role with the name `app-developer`, with the verbs `get` and `update` on the resource type `deployments, in the namespace `production`. (see how we created a role for Alice)
 
<!-- admin-kubectl create role app-developer --verb=get --verb=update --resource=deployments --namespace=production -->

Then create a rolebinding, in which we'll grant this role to both Alice and Bobby.
Use `admin-kubectl create rolebinding developers`, to create a rolebinding with the name `developers`.
Add two user flags (for `$ALICE` and `$BOBBY`), and grant them the `app-developer` role. Don't forget to add the `production` namespace flag.

<!-- admin-kubectl create rolebinding developers --role=app-developer --user=$ALICE --user=$BOBBY --namespace=production -->
Aside: note that kubernetes RBAC supports groups. At the moment, it is not possible to have groups on GKE. If it did support groups, we could create a group "developers", and use the `--group` flag on `kubectl create rolebinding`.

Now both Bobby and Alice should be able to update the deployments in the production namespace. 
```
alice-kubectl scale deployment my-web-app --replicas=2 --namespace=production
alice-kubectl get deployments --namespace production

# Note that bobby can _get_ a deployment
bobby-kubectl get deployment my-web-app --namespace=production

# But he does not have permission to list all deployments
bobby-kubectl get deployments --namespace=production
```
# Chaos Monkey
Chaos Monkeys can be an interesting tool to improve the resilience of your infrastructure. In this example, we'll only let the chaos monkey delete pods in the test namespace.

- Create a new role named 'chaos-monkey' in the `test` namespace, with the `list`, `get` and `delete` permissions on the `pods` resources.
- Create a new rolebinding named 'monkeys in the `test` namespace, that grants the role `chaos-monkey` to `$MONKEY`.

<!-- 
  admin-kubectl create role chaos-monkey \
    --verb=get \
    --verb=list \
    --verb=delete \
    --resource=pods \
    --namespace=test

admin-kubectl create rolebinding monkeys --role=chaos-monkey --user=$MONKEY --namespace=test
-->


Test the result with
```
  $ admin-kubectl run banana --image=nginx --replicas 3 --namespace test
  $ monkey-kubectl get pods --namespace=test
  NAME                      READY     STATUS    RESTARTS   AGE
  banana-3802458111-crk77   1/1       Running   0          21s
  banana-3802458111-dkrfm   1/1       Running   0          21s
  banana-3802458111-r0vns   1/1       Running   0          21s
```
 Now kill one of the bananas, as the monkey user
```
$ monkey-kubectl delete pod banana-3802458111-crk77 --namespace=test
  pod "banana-3802458111-crk77" deleted
```

If you run next command fast enough, you'll see something like this:
```
  $ monkey-kubectl get pods --namespace=test
  NAME                      READY     STATUS        RESTARTS   AGE
  banana-3802458111-1dtkf   1/1       Running       0          8s
  banana-3802458111-crk77   0/1       Terminating   0          1m
  banana-3802458111-dkrfm   1/1       Running       0          1m
  banana-3802458111-r0vns   1/1       Running       0          1m

```

# Test sandbox for developers
_This is a sligtly more advanced exercise, it's interesting if time permits it._

In our example, developers are allowed to do anything on the `test` namespace.
Kubernetes has a built-in cluster role for that, called `admin`, but it's cluster-wide!

1. Use ```admin-kubectl get clusterrole admin --output yaml > test-admin.yaml``` to  dump the role to a file.
2. Change the kind from `ClusterRole` to `Role`
3. Remove all metadata, except the name.
4. Add 'namespace: test' to the metadata.
5. `admin-kubectl apply -f test-admin.yaml`
6. Create a rolebinding named 'sandbox' to grant `$BOBBY` acccess to this 'admin' role

<!-- admin-kubectl create rolebinding sandbox --role=admin --user=$BOBBY --namespace=test -->


To verify that Bobby can now indeed run his side projects in the test namespace, run:
```
bobby-kubectl run side-project --image=nginx --namespace=test
```


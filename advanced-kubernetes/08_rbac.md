## RBAC

### A bit about roles

Role Based Access Control (RBAC) is a common approach to managing users’ access to resources or operations.

Permissions specify exactly which resources and actions can be accessed. 

The basic principle is this: instead of separately managing the permissions of each user, permissions are given to roles, which are then assigned to users, or better - groups of users.

----

### Roles Bundle Permissions

- Managing permissions per user can be a tedious task when many users are involved. 
- As users are added to the system, maintaining user permissions becomes harder and more prone to errors. 
- Incorrect assignment of permissions can block users’ access to required systems, or worse - allow unauthorized users to access restricted areas or perform risky operations.

----

* A regular user can only perform a limited number of actions (e.g. get, watch, list). 
* A closer look into these user actions can reveal that some actions tend to go together e.g. checking logs.
* Roles are not necessarily related to job titles or organizational structure, but rather reflect related user actions.
* Once roles are properly identified and assigned to each user, permissions can then be assigned to roles, instead of users. 

Managing the permissions of a small number of roles is a much easier task.

----

### Basic concept

Concepts

Rule -- grants permission
* Applies to resource types
* Grants verbs (create, edit, view, delete)
(Cluster)Role
* Cluster wide / within a namespace
* List of rules
(Cluster)RoleBinding
* Connects (Cluster)Role to User
* Both human & service account

----

### API overview

The RBAC API declares four top-level types which will be covered in this section:
* Role
* ClusterRole
* RoleBinding
* ClusterRoleBinding

----

### Role
In the RBAC API, a role contains rules that represent a set of permissions. Permissions are purely additive (there are no “deny” rules). A role can be defined within a namespace with a Role, or cluster-wide with a ClusterRole.

A Role can only be used to grant access to resources within a single namespace. Here’s an example Role in the “default” namespace that can be used to grant read access to pods:

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

### ClusterRole

* A ClusterRole can be used to grant the same permissions as a Role, but because they are cluster-scoped, they can also be used to grant access to:
* cluster-scoped resources (like nodes)
* non-resource endpoints (like “/healthz”)
* namespaced resources (like pods) across all namespaces (needed to run kubectl get pods --all-namespaces, for example)

----

### ClusterRole

The following ClusterRole can be used to grant read access to secrets in any particular namespace, or across all namespaces

```
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```

----

### RoleBinding

A role binding grants the permissions defined in a role to a user a groups or service accounts and a reference to the role being granted. 
Permissions can be granted within a namespace with a RoleBinding, or cluster-wide with a ClusterRoleBinding.

A RoleBinding may reference a Role in the same namespace. The following RoleBinding grants the “pod-reader” role to the user “jane” within the “default” namespace. This allows “jane” to read pods in the “default” namespace.

```
# This role binding allows "jane" to read pods in the "default" namespace.
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: jane
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

----

In this other example, even though the following RoleBinding refers to a ClusterRole, 
`dave` (the subject) will only be able read secrets in the `development` namespace (the namespace of the RoleBinding).

```
# This role binding allows "dave" to read secrets in the "development" namespace.
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: read-secrets
  namespace: development # This only grants permissions within the "development" namespace.
subjects:
- kind: User
  name: dave
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

A RoleBinding may also reference a ClusterRole to define a set of common roles for the entire cluster, then reuse them within multiple namespaces.

----

### ClusterRoleBinding
A ClusterRoleBinding may be used to grant permission at the cluster level and in all namespaces. The following ClusterRoleBinding allows any user in the group “manager” to read secrets in any namespace.

```
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

----

### Refering to resources

Most resources are represented by a string representation of their name, such as “pods”, just like in the URL for the relevant API endpoint. However, some Kubernetes APIs involve a “subresource”, such as the logs for a pod. The URL for the pods logs endpoint is:
GET /api/v1/namespaces/{namespace}/pods/{name}/log

In this case, “pods” is the namespaced resource, and “log” is a subresource of pods. To represent this in an RBAC role, use a slash to delimit the resource and subresource. To allow a subject to read both pods and pod logs, you would write:

```
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  namespace: default
  name: pod-and-pod-logs-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]

```

----

### Roles example

Allow reading the resource “pods” in the core API group:

```
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

----

Allow reading/writing “deployments” in both the “extensions” and “apps” API groups:

```
rules:
- apiGroups: ["extensions", "apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

### Role Binding Examples

Only the subjects section of a RoleBinding is shown in the following examples.

For a user named “alice@example.com”:

```
subjects:
- kind: User
  name: "alice@example.com"
  apiGroup: rbac.authorization.k8s.io
```

----

For a group named “frontend-admins”:

```
subjects:
- kind: Group
  name: "frontend-admins"
  apiGroup: rbac.authorization.k8s.io
```

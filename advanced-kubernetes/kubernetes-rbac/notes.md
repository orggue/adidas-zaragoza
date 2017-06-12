# Notes

## Resources

- RBAC support blog 
  http://blog.kubernetes.io/2017/04/rbac-support-in-kubernetes.html

  - https://www.youtube.com/watch?v=Cd4JU7qzYbE#t=8m01s
    - on GKE just admin role
    - restrict k8s api & secrets 

- K8s docs
  https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding


VERSCHIL TUSSEN MINIKUBE EN GKE --> waar users vandaan komen.


1. Show default admin role

- kubectl get clusterroles
- kubectl get clusterroles admin -o yaml

2. Create two service accounts
   - robot-alice
   - robot-max

3. Create ns
   - foo
   - desert

4. Create rolebinding
   - robot-alice can do everything in her wonderland
   - robot-max can do everything in his desert
   - robot-alice is also allowed to view what max is doing
   - max is mad, and cannot be allowed to see what alice is up to.

5. Run two ninx containers to demonstrate
   -


M:LJ:LFJD:LSF;l
- authentication
 
  - service accounts (managed by k8s)
  - normal users managed by authorizer. (https://kubernetes.io/docs/admin/authorization/)

    - managed outside of k8s.
    - cannot be added (from  within k8s) via an API call

- authorization

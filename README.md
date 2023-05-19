# watches-eshop

Databases are created manually to simplify argocd deployment and configuration (will be managed by ArgoCD and Helm charts).

```sh
# Create Namespaces
oc new-project argo-gitops
oc new-project watches-eshop

# Install ArgoCD
oc apply -f argocd/install/subscription.yaml
# ! Wait until installed
oc apply -f argocd/install/roles.yaml
oc apply -f argocd/install/instance.yaml

# Install applications
oc apply -f argocd/watches-eshop.yaml
```

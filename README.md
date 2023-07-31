# watches-eshop

Databases are created manually to simplify argocd deployment and configuration (will be managed by ArgoCD).

```sh
# Create Namespaces
oc new-project openshift-gitops
oc new-project watches-eshop

# Install ArgoCD
oc apply -f install/subscription.yaml
# ! Wait until installed
oc apply -f install/roles.yaml
oc apply -f install/instance.yaml

# Install applications
oc apply -f watches-eshop.yaml
```

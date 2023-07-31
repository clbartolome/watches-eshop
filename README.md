# watches-eshop

Databases are created manually to simplify argocd deployment and configuration (will be managed by ArgoCD).

Create a branch for a new cluster deployment and change all ocurrences of:

- **CHANGE_BRANCH_NAME**: new branch name
- **CHANGE_APPS_URL**: cluster apps url (ex: *.apps.ocp4cluster.ocp4.cfernand.com*)

!! Master version cannot be deployed without previous changes

```sh
# Create Namespaces
oc new-project openshift-gitops
oc new-project watches-eshop

# Install OpenShift GitOps (basic instalation)

# Apply roles
oc apply -f install/roles.yaml

# Install applications
oc apply -f watches-eshop.yaml
```

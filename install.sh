#!/bin/bash

##############################################################################
# -- FUNCTIONS --
info() {
    printf "\n++++++++++ INFO: $@\n"
}

err() {
  printf "\n!!!!!!!!!! ERROR: $1\n"
  exit 1
}
create_postgres() # service_name, user, pass, database, namespace, main_app
{
  info "Deploying Postgresql $1 in $5 ..."
  oc new-app postgresql-persistent \
    --param DATABASE_SERVICE_NAME=$1 \
    --param POSTGRESQL_USER=$2 \
    --param POSTGRESQL_PASSWORD=$3 \
    --param POSTGRESQL_DATABASE=$4 \
    -n $5
  oc label dc $1 \
    app.kubernetes.io/part-of=$6 \
    app.openshift.io/runtime=postgresql \
    -n $5
  sleep 5
  oc wait pod -l name=$1 --for=condition=Ready -n $5
}
create_mongo() # service_name, user, pass, namespace, main_app
{
  info "Deploying MongoDB $1 in $4 ..."
  oc new-app --docker-image=mongo:latest \
    -e MONGO_INITDB_ROOT_USERNAME=$2 \
    -e MONGO_INITDB_ROOT_PASSWORD=$3 \
    --name $1 \
    -n $4
  oc label deploy $1 \
    app.kubernetes.io/part-of=$5 \
    app.openshift.io/runtime=mongodb \
    -n $4
  sleep 5
  oc wait pod -l deployment=$1 --for=condition=Ready -n $4
}
##############################################################################

##############################################################################
# -- VALUES --
declare -r APP="watches-eshop"
declare -r DEV_PR="$APP-dev"
declare -r PRO_PR="$APP-prod"
declare -r CICD_PR="$APP-cicd"
declare -r DB_USER="db_user"
declare -r DB_PASS="pa5sw0rD"
##############################################################################

##############################################################################
# -- EXECUTION --
# oc version >/dev/null 2>&1 || err "no oc client found or not logged into a valid OCP cluster"

# NAMESPACES
info "Creating namespaces $CICD_PR, $DEV_PR, $PRO_PR"
oc apply -f  resources/ocp_namespaces.yaml

# DATABASES
# info "Deploying databases into application namespaces"
create_postgres "catalog-db-dev" $DB_USER $DB_PASS "catalog-db" $DEV_PR $DEV_PR 
create_postgres "catalog-db-prod" $DB_USER $DB_PASS "catalog-db" $PRO_PR $PRO_PR
# create_postgres "order-db-dev" $DB_USER $DB_PASS "order-db" $DEV_PR $DEV_PR 
# create_postgres "order-db-prod" $DB_USER $DB_PASS "order-db" $PRO_PR $PRO_PR
# create_mongo "payment-db-dev" $DB_USER $DB_PASS $DEV_PR $DEV_PR 
# create_mongo "payment-db-prod" $DB_USER $DB_PASS $PRO_PR $PRO_PR

# GITEA
info "Deploying GITEA to $CICD_PR namespace"
oc apply -f resources/gitea/gitea_deployment.yaml -n $CICD_PR

GITEA_HOSTNAME=$(oc get route gitea -o template --template='{{.spec.host}}' -n $CICD_PR)
sed "s/@HOSTNAME/$GITEA_HOSTNAME/g" resources/gitea/gitea_configuration.yaml | oc create -f - -n $CICD_PR
oc rollout status deployment/gitea -n $CICD_PR

info "Configuring GITEA repository (user, repositories and host)"
sed "s/@HOSTNAME/$GITEA_HOSTNAME/g" resources/gitea/gitea_configuration_job.yaml | oc apply -f - --wait -n $CICD_PR
oc wait --for=condition=complete job/configure-gitea --timeout=60s -n $CICD_PR

# BUILDS
# This will be executed by Tekton



# ARGOCD
info "Using default ArgoCD instance in openshift-gitops namespace"
ARGO_URL=$(oc get route openshift-gitops-server -ojsonpath='{.spec.host}' -n openshift-gitops)
ARGO_PASS=$(oc get secret openshift-gitops-cluster -n openshift-gitops -ojsonpath='{.data.admin\.password}' | base64 -d)
info "ArgoCD URL: "


info "Creating Watches Eshop Applications"
sed "s/@GITEA_HOSTNAME/$GITEA_HOSTNAME/g" resources/argocd/watches-eshop.yaml | oc apply -f -

# ##############################################################################

##############################################################################
# -- INFORMATION --
info "-INSTALLATION FINISHED-"
info "GITEA URL: http://$GITEA_HOSTNAME"
info "GITEA USER: gitea"
info "GITEA PASS: openshift"
info "ArgoCD URL: $ARGO_URL"
info "ArgoCD USER: admin"
info "ArgoCD PASS: $ARGO_PASS"
info "- -"
##############################################################################
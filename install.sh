#!/bin/bash

##############################################################################
# FUNCTIONS
info() {
    printf "\n# INFO: $@\n"
}

err() {
  printf "\n# ERROR: $1\n"
  exit 1
}
create_postgres()
{
  local service_name=$1
  local user=$2
  local pass=$3
  local database=$4
  local namespace=$5
  local main_app=$6
  info "Deploying Postgresql $service_name in $namespace ..."
  oc new-app postgresql-persistent \
    --param DATABASE_SERVICE_NAME=$service_name \
    --param POSTGRESQL_USER=$user \
    --param POSTGRESQL_PASSWORD=$pass \
    --param POSTGRESQL_DATABASE=$database \
    -n $namespace
  oc label dc catalog-db-dev \
    app.kubernetes.io/part-of=$main_app \
    app.openshift.io/runtime=postgresql \
    -n $namespace

  echo "Waiting for $1 pod to start.  You can safely exit this with Ctrl+C or just wait."
  until  oc get pods -l name=$service_name -n $namespace | grep -m 1 "Running"
  do
    sleep 2
  done
  info "Deployed Postgresql $service_name in $namespace!"
}
##############################################################################

##############################################################################
# VALUES
declare -r APP="watches-eshop"
declare -r DEV_PR="$APP-dev"
declare -r PRO_PR="$APP-prod"
declare -r CICD_PR="$APP-cicd"
declare -r DB_USER="db_user"
declare -r DB_PASS="pa5sw0rD"
##############################################################################

##############################################################################
# EXECUTION
oc version >/dev/null 2>&1 || err "no oc client found"

# NAMESPACES
info "Creating namespaces $CICD_PR, $DEV_PR, $PRO_PR"
oc apply -f  resources/ocp_namespaces.yaml

# DATABASES
info "Deploying databases into application namespaces"
create_postgres "catalog-db-dev" $DB_USER $DB_PASS "catalog-db" $DEV_PR $DEV_PR 
create_postgres "catalog-db-prod" $DB_USER $DB_PASS "catalog-db" $PRO_PR $PRO_PR
##############################################################################

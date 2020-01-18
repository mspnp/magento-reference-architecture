#!/bin/bash

set -exuo pipefail

. ./.env

az group create --name ${MAGENTO_RESOURCE_GROUP} --location ${RESOURCE_LOCATION}
az group deployment create \
    --resource-group ${MAGENTO_RESOURCE_GROUP} \
    --template-file azuredeploy.json  \
    --parameters \
        mysqlAdministratorLogin=${MAGENTO_DB_USER} \
        mysqlAdministratorPassword=${MAGENTO_DB_PASSWORD} \
        aksServicePrincipalClientId=${AKS_SERVICE_PRINCIPAL_CLIENT_ID} \
        aksServicePrincipalSecret=${AKS_SERVICE_PRINCIPAL_SECRET}

VIRTUAL_NETWORK_ID=$(az network vnet list --resource-group ${MAGENTO_RESOURCE_GROUP} --query "[0].id" --output tsv)

az group create --name ${SETUP_VM_RESOURCE_GROUP} --location ${RESOURCE_LOCATION}

az group deployment create \
    --resource-group ${SETUP_VM_RESOURCE_GROUP} \
    --name setup-docker-vm \
    --template-file dockervm.azuredeploy.json \
    --parameters \
        adminUserName=${SETUP_VM_ADMIN_USERNAME} \
        keyData="${SETUP_VM_SSH_DATA}" \
        virtualNetworkResourceId=${VIRTUAL_NETWORK_ID}

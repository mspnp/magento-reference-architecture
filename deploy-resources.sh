#!/bin/bash

set -exuo pipefail

. ./.env

SETUP_VM_SSH_DATA=$(cat "${SETUP_VM_SSH_PRIVATE_KEY_FILE}.pub")

az group create \
    --name ${MAGENTO_RESOURCE_GROUP} \
    --location ${RESOURCE_LOCATION} \
    --subscription ${SUBSCRIPTION_ID}

# We will validate the template first because AKS will check core availability
az group deployment validate \
    --resource-group ${MAGENTO_RESOURCE_GROUP} \
    --template-file azuredeploy.json  \
    --parameters \
        mysqlAdministratorLogin=${MAGENTO_DB_USER} \
        mysqlAdministratorPassword=${MAGENTO_DB_PASSWORD} \
        aksServicePrincipalClientId=${AKS_SERVICE_PRINCIPAL_CLIENT_ID} \
        aksServicePrincipalSecret=${AKS_SERVICE_PRINCIPAL_SECRET}

az group deployment create \
    --resource-group ${MAGENTO_RESOURCE_GROUP} \
    --subscription ${SUBSCRIPTION_ID} \
    --template-file azuredeploy.json  \
    --parameters \
        mysqlAdministratorLogin=${MAGENTO_DB_USER} \
        mysqlAdministratorPassword=${MAGENTO_DB_PASSWORD} \
        aksServicePrincipalClientId=${AKS_SERVICE_PRINCIPAL_CLIENT_ID} \
        aksServicePrincipalSecret=${AKS_SERVICE_PRINCIPAL_SECRET}

VIRTUAL_NETWORK_ID=$(az network vnet list \
    --resource-group ${MAGENTO_RESOURCE_GROUP} \
    --subscription ${SUBSCRIPTION_ID} \
    --query "[0].id" \
    --output tsv \
)

az group create \
    --name ${SETUP_VM_RESOURCE_GROUP} \
    --location ${RESOURCE_LOCATION} \
    --subscription ${SUBSCRIPTION_ID}

az group deployment create \
    --resource-group ${SETUP_VM_RESOURCE_GROUP} \
    --subscription ${SUBSCRIPTION_ID} \
    --name setup-docker-vm \
    --template-file dockervm.azuredeploy.json \
    --parameters \
        adminUserName=${SETUP_VM_ADMIN_USERNAME} \
        keyData="${SETUP_VM_SSH_DATA}" \
        virtualNetworkResourceId=${VIRTUAL_NETWORK_ID}
#
MAGENTO_DOCKER_VM_NIC_ID=$(az vm show \
	--name magento-docker-vm \
	--resource-group ${SETUP_VM_RESOURCE_GROUP} \
	--subscription ${SUBSCRIPTION_ID} \
	--query "networkProfile.networkInterfaces[0].id" \
	--output tsv)

MAGENTO_DOCKER_VM_NIC_PUBLIC_IP_ADDRESS_ID=$(az network nic show \
	--id ${MAGENTO_DOCKER_VM_NIC_ID} \
	--query "ipConfigurations[0].publicIpAddress.id" \
	--output tsv)

MAGENTO_DOCKER_VM_PUBLIC_IP_ADDRESS=$(az network public-ip show \
	--id ${MAGENTO_DOCKER_VM_NIC_PUBLIC_IP_ADDRESS_ID} \
	--query "ipAddress" \
	--output tsv)

SSH_LOGIN="${SETUP_VM_ADMIN_USERNAME}@${MAGENTO_DOCKER_VM_PUBLIC_IP_ADDRESS}"

ssh -i "${SETUP_VM_SSH_PRIVATE_KEY_FILE}" ${SSH_LOGIN} 'git clone https://github.com/mspnp/magento-reference-architecture.git; cd magento-reference-architecture; git checkout andrew/wip;'
scp -i "${SETUP_VM_SSH_PRIVATE_KEY_FILE}" ./.env ${SSH_LOGIN}:./magento-reference-architecture
echo Run '"'"ssh -i "'"'"${SETUP_VM_SSH_PRIVATE_KEY_FILE}"'"'" ${SSH_LOGIN}"'"'" to log into setup VM"


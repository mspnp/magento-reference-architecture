#!/bin/bash

set -exuo pipefail

. ./.env

# See if the AZ CLI is logged in, and if not, login
$(az account show > /dev/null || az login > /dev/null)

ACR_NAME=$(az acr list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].name" --output tsv \
)
ACR_LOGIN_SERVER=$(az acr list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].loginServer" \
      --output tsv \
)
ACR_USERNAME=$(az acr credential show \
      --name ${ACR_NAME} \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "username" \
      --output tsv \
)
ACR_PASSWORD=$(az acr credential show \
      --name ${ACR_NAME} \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "passwords[0].value" \
      --output tsv \
)
AKS_NAME=$(az aks list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].name" \
      --output tsv \
)
MAGENTO_CACHE_NAME=$(az redis list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].name" \
      --output tsv
)

MAGENTO_DB_HOST=$(az mysql server list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].fullyQualifiedDomainName" \
      --output tsv \
)
# We need to overwrite this because Azure adds the host name after the user.
MAGENTO_DB_USER=$(az mysql server list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "join('@', [[0].administratorLogin, [0].name])" \
      --output tsv \
)
MAGENTO_CACHE_HOST=$(az redis list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].hostName" \
      --output tsv \
)
MAGENTO_CACHE_PASSWORD=$(az redis list-keys \
      --name ${MAGENTO_CACHE_NAME} \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "primaryKey" \
      --output tsv \
)

PUB_STORAGE_ACCOUNT_NAME=$(az storage account list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --query "[0].name" \
      --output tsv \
)

PUB_STORAGE_ACCOUNT_KEY=$(az storage account keys list \
      --account-name ${PUB_STORAGE_ACCOUNT_NAME} \
      --query "[0].value" \
      --output tsv \
)

MAGENTO_CDN_HOSTNAME=$(az cdn endpoint list \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID} \
      --profile-name $(az cdn profile list \
            --resource-group ${MAGENTO_RESOURCE_GROUP} \
	    --subscription ${SUBSCRIPTION_ID} \
	    --query "[0].name" \
	    --output tsv) \
      --query "[0].hostName" \
      --output tsv
)

# Login to the container registry
az acr login \
      --name ${ACR_NAME} \
      --subscription ${SUBSCRIPTION_ID} \
      --username ${ACR_USERNAME} \
      --password ${ACR_PASSWORD}

# Configure kubectl
az aks get-credentials \
      --name ${AKS_NAME} \
      --resource-group ${MAGENTO_RESOURCE_GROUP} \
      --subscription ${SUBSCRIPTION_ID}

kubectl create secret docker-registry magento-registry-cred \
      --docker-server=${ACR_LOGIN_SERVER} \
      --docker-username=${ACR_USERNAME} \
      --docker-password=${ACR_PASSWORD} \
      --docker-email="notused@email.com" \
      --dry-run=true \
      --output yaml | \
      kubectl apply -f -


kubectl create secret generic azurefilecreds \
      --from-literal=azurestorageaccountname=${PUB_STORAGE_ACCOUNT_NAME} \
      --from-literal=azurestorageaccountkey="${PUB_STORAGE_ACCOUNT_KEY}" \
      --dry-run=true \
      --output yaml | \
      kubectl apply -f -

kubectl apply -f magento-loadbalancer.yaml

LOAD_BALANCER_EXTERNAL_IP=$(kubectl get service magentoweb -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
until [[ -n "${LOAD_BALANCER_EXTERNAL_IP}" ]]
do
      echo "Waiting for load balancer external IP address"
      sleep 10
      LOAD_BALANCER_EXTERNAL_IP=$(kubectl get service magentoweb -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
done

MAGENTO_BASE_URL=http://${LOAD_BALANCER_EXTERNAL_IP}/

sed -e 's@MAGENTO_COMPOSER_USERNAME=$@MAGENTO_COMPOSER_USERNAME='"${MAGENTO_COMPOSER_USERNAME}"'@g' \
      -e 's@MAGENTO_COMPOSER_PASSWORD=$@MAGENTO_COMPOSER_PASSWORD='"${MAGENTO_COMPOSER_PASSWORD}"'@g' \
      -e 's@MAGENTO_DB_HOST=$@MAGENTO_DB_HOST='"${MAGENTO_DB_HOST}"'@g' \
      -e 's#MAGENTO_DB_USER=$#MAGENTO_DB_USER='"${MAGENTO_DB_USER}"'#g' \
      -e 's@MAGENTO_DB_PASSWORD=$@MAGENTO_DB_PASSWORD='"${MAGENTO_DB_PASSWORD}"'@g' \
      -e 's@MAGENTO_CACHE_HOST=$@MAGENTO_CACHE_HOST='"${MAGENTO_CACHE_HOST}"'@g' \
      -e 's@MAGENTO_CACHE_PASSWORD=$@MAGENTO_CACHE_PASSWORD='"${MAGENTO_CACHE_PASSWORD}"'@g' \
      -e 's@MAGENTO_BASE_URL=$@MAGENTO_BASE_URL='"${MAGENTO_BASE_URL}"'@g' \
      -e 's@MAGENTO_BASE_STATIC_URL=$@MAGENTO_BASE_STATIC_URL='"http://${MAGENTO_CDN_HOSTNAME}/pub/static"'@g' \
      -e 's@MAGENTO_BASE_MEDIA_URL=$@MAGENTO_BASE_MEDIA_URL='"http://${MAGENTO_CDN_HOSTNAME}/pub/media"'@g' ./.env > ./.env_build

wget -O azcopy_v10.tar.gz https://azcopyvnext.azureedge.net/release20200124/azcopy_linux_amd64_10.3.4.tar.gz \
      && tar -xf azcopy_v10.tar.gz --strip-components=1

# Build the local builder and tag it so we can get the generated configuration file out
docker build . -f Dockerfile-magento \
      --target builder \
      --build-arg MAGENTO_TIMEZONE=${MAGENTO_TIMEZONE} \
      --build-arg MAGENTO_PHP_MEMORYLIMIT=${MAGENTO_PHP_MEMORYLIMIT} \
      -t magento2-builder | \
      tee magento2-builder.log

docker build . -f Dockerfile-magento \
      --target magento2 \
      --build-arg MAGENTO_TIMEZONE=${MAGENTO_TIMEZONE} \
      --build-arg MAGENTO_PHP_MEMORYLIMIT=${MAGENTO_PHP_MEMORYLIMIT} \
      -t ${ACR_LOGIN_SERVER}/magento2 | \
      tee magento2.log

docker build . -f Dockerfile-varnish -t ${ACR_LOGIN_SERVER}/varnish | tee varnish.log

docker push ${ACR_LOGIN_SERVER}/magento2

docker push ${ACR_LOGIN_SERVER}/varnish

docker run --rm magento2-builder /bin/sh -c 'sleep 3600' &

# Wait just a bit
sleep 10
CONTAINER_ID=$(docker ps --filter ancestor=magento2-builder -q)
rm -rf ./media
rm -rf ./static
docker cp --archive ${CONTAINER_ID}:/var/www/html/magento2/app/etc/env.php ./env.php
docker cp --archive ${CONTAINER_ID}:/var/www/html/magento2/pub/media ./media
docker cp --archive ${CONTAINER_ID}:/var/www/html/magento2/pub/static ./static

SAS_TOKEN=$(az storage file generate-sas \
      --account-name ${PUB_STORAGE_ACCOUNT_NAME} \
      --path / \
      --permissions rcdw \
      --share-name pub \
      --output tsv
)
# There is a bug in docker cp with the --archive flag
sudo chown -R 101:82 ./media/ && sudo chown -R 101:82 ./static/
azcopy copy ./media "https://${PUB_STORAGE_ACCOUNT_NAME}.file.core.windows.net/pub?${SAS_TOKEN}" --recursive 
azcopy copy ./static "https://${PUB_STORAGE_ACCOUNT_NAME}.file.core.windows.net/pub?${SAS_TOKEN}" --recursive 
docker stop ${CONTAINER_ID}

kubectl create secret generic magento-config \
      --from-file ./env.php \
      --dry-run=true \
      --output yaml | \
      kubectl apply -f -

# Delete the env.php file since it has secrets
rm ./env.php

# Deploy Magento to the Kubernetes cluster
echo '"'"sed -e "'"'"s/ACR_LOGIN_SERVER/${ACR_LOGIN_SERVER}/g"'"'" ./magento-deployment.yaml | kubectl apply -f -"'"'


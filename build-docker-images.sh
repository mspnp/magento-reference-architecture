#!/bin/sh

set -exuo pipefail

. ./.env

WORK_DIR=/magento/work
mkdir -p ${WORK_DIR}

docker build . -f Dockerfile-docker \
       --no-cache \
       --target builder \
       --network magento-reference-architecture_default \
       --tag magento2-builder:0.9 | tee ${WORK_DIR}/magento2-builder.log
docker build . -f Dockerfile-docker \
       --network magento-reference-architecture_default \
       --tag ${ACR_LOGIN_SERVER}/magento2:0.9 | tee ${WORK_DIR}/magento2.log
docker build . -f Dockerfile-varnish -t ${ACR_LOGIN_SERVER}/varnish:0.9 | tee ${WORK_DIR}/varnish.log

#docker push ${ACR_LOGIN_SERVER}/magento2:0.9

#docker push ${ACR_LOGIN_SERVER}/varnish:0.9

# Stop any running containers, which may happen if the script is rerun.
EXISTING_CONTAINER_IDS=$(docker ps --all --quiet --filter name=magento2_builder)
if [ -n "$EXISTING_CONTAINER_IDS" ]; then
        echo "Stopping running containers"
        docker stop $EXISTING_CONTAINER_IDS
fi

CONTAINER_ID=$(docker run --rm --name magento2_builder -d magento2-builder:0.9 /bin/sh -c 'sleep 120')

# Wait just a bit for the container to start
sleep 10

# Copy the shared tar archive locally
docker cp magento2_builder:/magento/magento-shared.tar.gz ${WORK_DIR}/magento-shared.tar.gz

docker stop $CONTAINER_ID

# Dump the mysql database
docker exec magento-reference-architecture_mysql_1 sh -c 'mysqldump -hlocalhost -uroot -p'${MAGENTO_DB_PASSWORD}' --column_statistics=0 magento2 > '${WORK_DIR}'/magento2.sql'

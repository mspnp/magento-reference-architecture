#!/bin/bash

set -exuo pipefail

#docker build . -f Dockerfile-runtime -t mytestmagentocr.azurecr.io/magento
#docker push mytestmagentocr.azurecr.io/magento

#docker build . -f Dockerfile-setup -t mytestmagentocr.azurecr.io/magento-setup
#docker push mytestmagentocr.azurecr.io/magento-setup

docker run -it --rm redis redis-cli -h mytestmagentoredis.redis.cache.windows.net -a "bXGDYw5q+20UmIRTxhUkfMGBHvANuJltcxQT97oRLL0=" flushall
docker run -it --rm mysql mysql -hmytestmagentodb.mysql.database.azure.com -uaoakley@mytestmagentodb -p"Ehe5Mb42S%nBoK*c" -e "drop database if exists magento2; create database magento2;"
docker build . -f Dockerfile -t mytestmagentocr.azurecr.io/magento2 --no-cache | tee magento2-build-log.txt
docker push mytestmagentocr.azurecr.io/magento2

#!/bin/sh

set -exu pipefail

docker build . -f Dockerfile-runtime -t mytestmagentocr.azurecr.io/magento
docker push mytestmagentocr.azurecr.io/magento

docker build . -f Dockerfile-setup -t mytestmagentocr.azurecr.io/magento-setup
docker push mytestmagentocr.azurecr.io/magento-setup

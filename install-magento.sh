#!/bin/bash

set -exuo pipefail

/var/www/html/magento2/bin/magento setup:install \
      --base-url=${MAGENTO_BASE_URL} \
      --db-host=${MAGENTO_DB_HOST} \
      --db-user=${MAGENTO_DB_USER} \
      --db-password="${MAGENTO_DB_PASSWORD}" \
      --db-ssl-ca="/etc/ssl/certs/BaltimoreCyberTrustRoot.crt.pem" \
      --admin-firstname=${MAGENTO_ADMIN_FIRST_NAME} \
      --admin-lastname=${MAGENTO_ADMIN_LAST_NAME} \
      --admin-email=${MAGENTO_ADMIN_EMAIL} \
      --admin-user=${MAGENTO_ADMIN_USERNAME} \
      --admin-password=${MAGENTO_ADMIN_PASSWORD} \
      --currency=${MAGENTO_CURRENCY} \
      --language=${MAGENTO_LANGUAGE} \
      --timezone=${MAGENTO_TIMEZONE} \
      --use-rewrites=1

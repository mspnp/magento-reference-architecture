#!/bin/bash

set -exuo pipefail

/var/www/html/magento2/bin/magento setup:config:set \
      --cache-backend=redis \
      --cache-backend-redis-server=${MAGENTO_CACHE_HOST} \
      --cache-backend-redis-port=6379 \
      --cache-backend-redis-password="${MAGENTO_CACHE_PASSWORD}" \
      --cache-backend-redis-db=0

/var/www/html/magento2/bin/magento setup:config:set \
      --session-save=redis \
      --session-save-redis-host=${MAGENTO_CACHE_HOST} \
      --session-save-redis-port=6379 \
      --session-save-redis-password="${MAGENTO_CACHE_PASSWORD}" \
      --session-save-redis-db=2

/var/www/html/magento2/bin/magento config:set \
    system/full_page_cache/caching_application 2

/var/www/html/magento2/bin/magento config:set \
    system/full_page_cache/varnish/access_list localhost

/var/www/html/magento2/bin/magento config:set \
    system/full_page_cache/varnish/backend_host localhost

/var/www/html/magento2/bin/magento config:set \
    system/full_page_cache/varnish/backend_port 8080

/var/www/html/magento2/bin/magento deploy:mode:set production
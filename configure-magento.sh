#!/bin/bash

set -exuo pipefail

/var/www/html/magento2/bin/magento setup:config:set -vvv \
      --cache-backend=redis \
      --cache-backend-redis-server=${MAGENTO_CACHE_HOST} \
      --cache-backend-redis-port=6379 \
      --cache-backend-redis-password="${MAGENTO_CACHE_PASSWORD}" \
      --cache-backend-redis-db=0

/var/www/html/magento2/bin/magento setup:config:set -vvv \
      --session-save=redis \
      --session-save-redis-host=${MAGENTO_CACHE_HOST} \
      --session-save-redis-port=6379 \
      --session-save-redis-password="${MAGENTO_CACHE_PASSWORD}" \
      --session-save-redis-db=2

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/caching_application 2

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/varnish/access_list localhost

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/varnish/backend_host localhost

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/varnish/backend_port 8080

/var/www/html/magento2/bin/magento config:set -vvv \
    web/unsecure/base_static_url ${MAGENTO_BASE_STATIC_URL}

/var/www/html/magento2/bin/magento config:set -vvv \
    web/unsecure/base_media_url ${MAGENTO_BASE_MEDIA_URL}

/var/www/html/magento2/bin/magento config:set -vvv \
	    dev/css/merge_css_files 1

/var/www/html/magento2/bin/magento config:set -vvv \
	    dev/css/minify_files 1

/var/www/html/magento2/bin/magento config:set -vvv \
	    dev/js/enable_js_bundling 0

/var/www/html/magento2/bin/magento config:set -vvv \
	    dev/js/merge_files 1

/var/www/html/magento2/bin/magento config:set -vvv \
	    dev/js/minify_files 1

/var/www/html/magento2/bin/magento deploy:mode:set -vvv production


#!/bin/bash

set -exuo pipefail

# TODO - Just to change the script so docker will re-run this step

# Redis
/var/www/html/magento2/bin/magento setup:config:set -vvv --no-interaction \
    --cache-backend=redis \
	--cache-backend-redis-server=${MAGENTO_CACHE_HOST} \
	--cache-backend-redis-port=6379 \
	--cache-backend-redis-password=${MAGENTO_CACHE_PASSWORD} \
	--cache-backend-redis-db=0 \
	--session-save=redis \
	--session-save-redis-host=${MAGENTO_CACHE_HOST} \
	--session-save-redis-port=6379 \
	--session-save-redis-password=${MAGENTO_CACHE_PASSWORD} \
	--session-save-redis-db=2
	# This must be here due to a bug in Magento 2.
	# --db-ssl-ca=${MAGENTO_DB_SSL_CA_PATH} \
	# --db-ssl-verify \
	# --db-ssl-cert="" \
	# --db-ssl-key=""
# /var/www/html/magento2/bin/magento setup:config:set -vvv \
#       --cache-backend=redis \
#       --cache-backend-redis-server=${MAGENTO_CACHE_HOST} \
#       --cache-backend-redis-port=6379 \
#       --cache-backend-redis-password="${MAGENTO_CACHE_PASSWORD}" \
#       --cache-backend-redis-db=0

# /var/www/html/magento2/bin/magento setup:config:set -vvv \
#       --session-save=redis \
#       --session-save-redis-host=${MAGENTO_CACHE_HOST} \
#       --session-save-redis-port=6379 \
#       --session-save-redis-password="${MAGENTO_CACHE_PASSWORD}" \
#       --session-save-redis-db=2

# Full-page cache (Varnish)
/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/caching_application 2

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/varnish/access_list magentoweb

/var/www/html/magento2/bin/magento config:set -vvv \
    system/full_page_cache/varnish/backend_host magentoweb

/var/www/html/magento2/bin/magento config:set -vvv \
   system/full_page_cache/varnish/backend_port 8080

# CDN
/var/www/html/magento2/bin/magento config:set -vvv \
    web/unsecure/base_static_url ${MAGENTO_BASE_STATIC_URL}

/var/www/html/magento2/bin/magento config:set -vvv \
    web/unsecure/base_media_url ${MAGENTO_BASE_MEDIA_URL}

/var/www/html/magento2/bin/magento config:set -vvv \
    web/secure/base_static_url ${MAGENTO_BASE_STATIC_URL_SECURE}

/var/www/html/magento2/bin/magento config:set -vvv \
    web/secure/base_media_url ${MAGENTO_BASE_MEDIA_URL_SECURE}

# Search
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/engine 'elasticsearch7'
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/elasticsearch7_server_hostname ${MAGENTO_ELASTICSEARCH_HOST}
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/elasticsearch7_enable_auth 0
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/elasticsearch7_index_prefix 'magento2'
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/elasticsearch7_server_port 9200
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/search/elasticsearch7_server_timeout 15

# Magento optimizations
# Make sure pub/static/_cache is writable due to https://github.com/magento/magento2/issues/13225
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

# Turn off product count
/var/www/html/magento2/bin/magento config:set -vvv \
    catalog/layered_navigation/display_product_count 0

# Disable email
/var/www/html/magento2/bin/magento config:set -vvv \
    system/smtp/disable 1

#/var/www/html/magento2/bin/magento deploy:mode:set -vvv production

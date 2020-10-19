#!/bin/bash

CLI_COMMAND=$1

set -exuo pipefail

function install_magento {
    /var/www/html/magento2/bin/magento setup:install \
      --base-url=${MAGENTO_BASE_URL} \
      --base-url-secure=${MAGENTO_BASE_URL_SECURE} \
      --db-host=${MAGENTO_DB_HOST} \
      --db-user=${MAGENTO_DB_USER} \
      --db-password="${MAGENTO_DB_PASSWORD}" \
      --db-name=magento2 \
      --db-ssl-ca="/etc/ssl/certs/Baltimore_CyberTrust_Root.pem" \
      --admin-firstname=${MAGENTO_ADMIN_FIRST_NAME} \
      --admin-lastname=${MAGENTO_ADMIN_LAST_NAME} \
      --admin-email=${MAGENTO_ADMIN_EMAIL} \
      --admin-user=${MAGENTO_ADMIN_USERNAME} \
      --admin-password=${MAGENTO_ADMIN_PASSWORD} \
      --currency=${MAGENTO_CURRENCY} \
      --language=${MAGENTO_LANGUAGE} \
      --timezone=${MAGENTO_TIMEZONE} \
      --use-rewrites=1 \
      --search-engine=elasticsearch7 \
      --elasticsearch-host=${MAGENTO_ELASTICSEARCH_HOST} \
      --elasticsearch-port=9200 \
      --elasticsearch-index-prefix='magento2' \
      --elasticsearch-timeout=15 \
      --elasticsearch-enable-auth=false
}

function extract_magento {
    mkdir -p /var/www/html/magento2
    tar -xzf /magento/magento-ce-2.4.0-2020-07-24-11-15-38.tar.gz --directory /var/www/html/magento2
    cd /var/www/html/magento2
    find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
    find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
    chown -R magento:www-data /var/www/html/magento2
    chmod u+x bin/magento
}

function configure_magento {
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

    /var/www/html/magento2/bin/magento deploy:mode:set -vvv production
}

case "$CLI_COMMAND" in
    extract)
        echo "Extracting magento2"
        extract_magento
        echo "Magento2 xtract complete"
        ;;
    install)
        echo "Installing magento2"
        install_magento
        echo "Magento2 install complete"
        ;;
    configure)
        echo "Configuring magento2"
        configure_magento
        echo "Magento2 configure complete"
        ;;
    "")
        echo "Extracting, installing, and configuring magento2"
        extract_magento
        install_magento
        configure_magento
        echo "Magento2 extract, install, and configure complete"
        ;;
    *)
        echo "Unknown action: $1";
        exit 1;
        ;;
esac

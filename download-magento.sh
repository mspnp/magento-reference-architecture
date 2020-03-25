#!/bin/sh

set -exuo pipefail

mkdir /home/magento/.composer

cat <<EOF > /home/magento/.composer/auth.json
{
    "http-basic": {
        "repo.magento.com": {
            "username": "${MAGENTO_COMPOSER_USERNAME}",
            "password": "${MAGENTO_COMPOSER_PASSWORD}"
        }
    }
}
EOF

composer create-project --repository=https://repo.magento.com/ magento/project-community-edition /var/www/html/magento2

cd /var/www/html/magento2
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
chown -R :www-data *
chmod u+x bin/magento

# This is to work around a bug in Magento so we can install the sample data
# https://github.com/magento/magento2/issues/2523
mkdir /var/www/html/magento2/var/composer_home
ln -s /home/magento/.composer/auth.json /var/www/html/magento2/var/composer_home

# Let's add the sample data
/var/www/html/magento2/bin/magento sampledata:deploy
/var/www/html/magento2/bin/magento setup:upgrade

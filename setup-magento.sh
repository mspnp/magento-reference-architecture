#!/bin/sh

if [ ! -d "/var/www/html/magento2" ]
then
  # We have to reset these since we now have a new drive attached, just in case
  chown -R www-data:www-data /var/www && \
  chmod go-rwx /var/www && \
  chmod go+x /var/www && \
  chgrp -R www-data /var/www && \
  chmod -R go-rwx /var/www && \
  chmod -R g+rx /var/www && \
  chmod -R g+rwx /var/www && \
  # Setup Composer authentication for magento
  su -m magento -c 'cat <<EOF > /home/magento/.composer/auth.json
{
    "http-basic": {
        "repo.magento.com": {
            "username": "${MAGENTO_COMPOSER_USERNAME}",
            "password": "${MAGENTO_COMPOSER_PASSWORD}"
        }
    }
}
EOF' && \
  su - magento -c 'cd /var/www/html && \
  composer create-project --repository=https://repo.magento.com/ magento/project-community-edition magento2 && \
  cd /var/www/html/magento2 && \
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
  find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + && \
  chown -R :www-data * && \
  chmod u+x bin/magento'
fi
"$@"

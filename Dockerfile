FROM magentocrxvxgwbf2ivsiu.azurecr.io/magento2-builder:latest
RUN rm /var/www/html/magento2/app/etc/env.php
CMD /bin/sh -c 'php-fpm -D && httpd -D FOREGROUND'

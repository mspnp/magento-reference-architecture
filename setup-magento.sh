#!/bin/sh
#mkdir /etc/smbcredentials && \
#echo "username=mytestmagentostor" >> /etc/smbcredentials/mytestmagentostor.cred && \
#echo "password=/YKjJcf+Xmzyi7pAUYfbGeXl5o/RYp7rXuVNsDPHV4wIzk/0V0p4EcAmEiXxJBstYnc3U0NBQMM/MPYbEaI5Mg==" >> /etc/smbcredentials/mytestmagentostor.cred && \
#chmod 600 /etc/smbcredentials/mytestmagentostor.cred && \
#echo "//mytestmagentostor.file.core.windows.net/magento2 /var/www/html/magento2 cifs nofail,vers=3.0,credentials=/etc/smbcredentials/mytestmagentostor.cred,dir_mode=0777,file_mode=0777,serverino,gid=$(id -g www-data),uid=$(id -u www-data)" >> /etc/fstab && \
#mount -t cifs //mytestmagentostor.file.core.windows.net/magento2 /var/www/html/magento2 -o vers=3.0,credentials=/etc/smbcredentials/mytestmagentostor.cred,dir_mode=0777,file_mode=0777,serverino,gid=$(id -g www-data),uid=$(id -u www-data) && \


# We have to reset these since we now have a new drive attached, just in case
# chown -R www-data:www-data /var/www && \
#     chmod go-rwx /var/www && \
#     chmod go+x /var/www && \
#     chgrp -R www-data /var/www && \
#     chmod -R go-rwx /var/www && \
#     chmod -R g+rx /var/www && \
#     chmod -R g+rwx /var/www && \
# su - magento -c 'cd /var/www/html && \
# composer create-project --repository=https://repo.magento.com/ magento/project-community-edition magento2 && \
# cd /var/www/html/magento2 && \
# find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
# find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + && \
# chown -R :www-data * && \
# chmod u+x bin/magento && \
# "$@"'
if [ ! -d "/var/www/html/magento2" ]
then
  chown -R www-data:www-data /var/www && \
  chmod go-rwx /var/www && \
  chmod go+x /var/www && \
  chgrp -R www-data /var/www && \
  chmod -R go-rwx /var/www && \
  chmod -R g+rx /var/www && \
  chmod -R g+rwx /var/www && \  
  su - magento -c 'cd /var/www/html && \
  composer create-project --repository=https://repo.magento.com/ magento/project-community-edition magento2 && \
  cd /var/www/html/magento2 && \
  find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
  find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + && \
  chown -R :www-data * && \
  chmod u+x bin/magento'

#   cd /var/www/html && \
#   composer create-project --repository=https://repo.magento.com/ magento/project-community-edition magento2 && \
#   cd /var/www/html/magento2 && \
#   find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
#   find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + && \
#   chown -R :www-data * && \
#   chmod u+x bin/magento
fi
"$@"

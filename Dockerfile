FROM php:7.3-fpm-alpine3.10

COPY install-composer.sh /magento/install-composer.sh
COPY magento.conf /magento/magento.conf
# COPY install-magento.sh /magento/install-magento.sh
# COPY setup-magento.sh /magento/setup-magento.sh

# Install all build-deps and then install magento.
RUN apk --no-cache --update --virtual runtime-deps add \
        apache2 \
        apache2-proxy \
        bash \
        cifs-utils \
        dcron \
        freetype \
        gzip \
        lsof \
        icu-libs \
        libcap \
        libjpeg \
        libmcrypt \
        libpng \
        libxslt \
        libzip \
        sed \
        tar && \
    apk --no-cache --update --virtual build-deps add \
        autoconf \
        binutils \
        curl-dev \
        dpkg \
        dpkg-dev \
        file \
        freetype-dev \
        g++ \
        gcc \
        gmp \
        icu-dev \
        isl \
        libatomic \
        libbz2 \
        libc-dev \
        libgcc \
        libgomp \
        libjpeg-turbo-dev \
        libmagic \
        libmcrypt-dev \
        libpng-dev \
        libstdc++ \
        libxslt-dev \
        libzip-dev \
        m4 \
        make \
        mpc1 \
        mpfr3 \
        musl-dev \
        pcre-dev \
        perl \
        pkgconf \
        pkgconfig \
        re2c && \
    pecl install xdebug && \
    docker-php-ext-install bcmath curl iconv intl json mbstring opcache pdo_mysql soap xsl zip && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd && \
    sed -i -e 's/Listen 80/Listen 8080/g' \
    # Disable the mpm prefork module
        -e '/LoadModule mpm_prefork_module/s/^/#/g' \
    # Enable the rewrite and mpm event modules
        -e '/LoadModule \(mpm_event_module\|rewrite_module\)/s/^#//g' /etc/apache2/httpd.conf && \
    # Configure Magento site
    mv /magento/magento.conf /etc/apache2/conf.d/magento.conf && \
    # Configure PHP
    mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i -e 's@;date\.timezone =@date.timezone = America/Los_Angeles@g' \
        -e 's@^;opcache.save_comments.*$@opcache.save_comments=1@g' \
        -e 's@^memory_limit.*$@memory_limit=2G@g' /usr/local/etc/php/php.ini && \
    # Install Composer
    sh -c /magento/install-composer.sh && \
    rm /magento/install-composer.sh && \
    adduser -S -s /bin/sh -D magento -G www-data && \
    # Set permissions for apache
    chown -R www-data:www-data /var/www && \
    chmod go-rwx /var/www && \
    chmod go+x /var/www && \
    chgrp -R www-data /var/www && \
    chmod -R go-rwx /var/www && \
    chmod -R g+rx /var/www && \
    chmod -R g+rwx /var/www && \
    # Cleanup
    apk del build-deps

# Normally, we should probably combine these steps to reduce the number of layers.
# However, each of these steps can fail for various reasons, so we don't want to have
# to keep running the whole thing.
COPY download-magento.sh /magento/download-magento.sh
# We need to alter the php execution time because installing the sample data can take a long time.
# We just need to make sure to reset it.
RUN sed -i -e 's@^max_execution_time.*$@max_execution_time = 1200@g' /usr/local/etc/php/php.ini && \
    su - magento -c '/magento/download-magento.sh' && \
    sed -i -e 's@^max_execution_time.*$@max_execution_time = 30@g' /usr/local/etc/php/php.ini
COPY install-magento.sh /magento/install-magento.sh
RUN su - magento -c '/magento/install-magento.sh'
COPY configure-magento.sh /magento/configure-magento.sh
RUN su - magento -c '/magento/configure-magento.sh' && \
    rm -rf /magento
#USER magento
CMD /bin/sh -c 'php-fpm -D && httpd -D FOREGROUND'

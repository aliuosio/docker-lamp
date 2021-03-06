ARG PHP_VERSION_SET
FROM php:${PHP_VERSION_SET}-fpm-alpine
ARG PHP_VERSION_SET
LABEL maintainer="Osiozekhai Aliu"
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk update && apk upgrade
RUN apk add --virtual build-dependencies \
        libc-dev \
        libxslt-dev \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
    && set -xe \
    && apk add \
        git \
        bash \
        bash-completion \
        shadow \
	    nano \
        tzdata \
        icu \
        imagemagick-dev \
        imagemagick \
        bc \
        procps \
        yarn \
        openssh-keygen \
        openssh-client \
    && apk add --virtual .php-deps \
        make \
    && apk add --virtual .build-deps \
        $PHPIZE_DEPS \
        zlib-dev \
        icu-dev \
        g++ \
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-install \
        bcmath \
        mysqli \
        intl \
        pdo_mysql \
        opcache \
        xsl \
        zip \
        soap \
        sockets \
        pcntl \
    && pecl channel-update pecl.php.net \
    && pecl install -o -f redis imagick apcu-5.1.18 xdebug \
    && docker-php-ext-enable redis imagick apcu xdebug;
RUN if [ $(echo "$PHP_VERSION_SET < 7.2"|bc) -eq 1 ]; then \
        apk add libmcrypt-dev \
        && docker-php-ext-install mcrypt; \
    fi
RUN if [ $(echo "$PHP_VERSION_SET < 7.4"|bc) -eq 1 ]; then \
        docker-php-ext-configure gd \
            --with-freetype-dir=/usr/include/freetype2 \
            --with-jpeg-dir=/usr/include \
            --with-png-dir=/usr/include; \
    else \
        docker-php-ext-configure gd \
            --with-freetype \
            --with-jpeg; \
    fi

RUN docker-php-ext-install gd;
COPY conf/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN rm -rf /var/cache/apk/* \
    && docker-php-source delete \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && rm -rf /tmp/pear;

ADD https://files.magerun.net/n98-magerun2.phar /usr/bin/n98-magerun2.phar
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /usr/bin/wait-for-it.sh
RUN chmod +x /usr/bin/n98-magerun2.phar \
    && chmod +x /usr/bin/wait-for-it.sh

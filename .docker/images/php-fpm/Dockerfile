FROM php:7-fpm

RUN apt-get update && apt-get install -y \
    libmcrypt-dev  \
    libicu-dev \
    mysql-client \
    && pecl install xdebug \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install iconv \
    && docker-php-ext-install mcrypt \
    && docker-php-ext-install intl \
    && docker-php-ext-install opcache \
    && docker-php-ext-enable xdebug

CMD ["php-fpm"]

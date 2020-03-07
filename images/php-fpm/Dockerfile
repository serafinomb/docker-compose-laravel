FROM composer:1.9 AS composer

FROM php:7.3-fpm

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN apt-get update && \
    apt-get install -y mariadb-client && \
    pecl install xdebug && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-enable xdebug

CMD ["php-fpm"]

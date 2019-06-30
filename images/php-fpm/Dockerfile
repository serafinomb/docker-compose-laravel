FROM php:7.3-fpm

RUN apt-get update && \
    apt-get install -y mysql-client && \
    pecl install xdebug && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-enable xdebug

CMD ["php-fpm"]

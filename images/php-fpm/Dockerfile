FROM php:7.3-fpm

RUN apt-get update && \
    apt-get install -y mariadb-client git zip unzip && \
    pecl install xdebug && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-enable xdebug

RUN php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/55e3ac0516cf01802649468315cd863bcd46a73f/web/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

CMD ["php-fpm"]

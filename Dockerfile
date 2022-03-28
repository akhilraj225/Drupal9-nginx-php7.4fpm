# Using base ubuntu image
FROM ubuntu:20.04

#LABEL Maintainer="Herlangga Sefani <herlanggasefani@gmail.com>" \
 #     Description="Nginx + PHP7.4-FPM Based on Ubuntu 20.04."

# Setup document root
RUN mkdir -p /var/www/app
WORKDIR /var/www/app

ADD composer.json /var/www/app/
#ADD composer.lock /
ADD prepros.config /var/www/app/
ADD core-assets.patch /var/www/app/

# Base install
RUN apt update --fix-missing
#RUN  DEBIAN_FRONTEND=noninteractive
#RUN ln -snf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime && echo Asia/Jakarta > /etc/timezone
RUN apt install wget supervisor nginx -y

# Install php7.4-fpm
# Since the repo is supported on ubuntu 20
RUN apt install php-fpm php-json php-pdo php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath php-intl -y

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"
# Check if installation successfull
RUN composer --help

#RUN wget -o drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.4.2/drush.phar
#RUN chmod +x drush.phar
#RUN mv drush.phar /usr/local/bin/drush
RUN composer self-update
#RUN composer require cweagans/composer-patches:~1.0 --update-with-dependencies
RUN COMPOSER_MEMORY_LIMIT=-1 COMPOSER_ALLOW_SUPERUSER=1 composer install
RUN composer dump-autoload

COPY ./entrypoint.sh ./entrypoint.sh

RUN chmod +x ./entrypoint.sh

RUN rm /etc/nginx/sites-enabled/default

COPY ./php/php.ini /etc/php/7.4/fpm/php.ini
COPY ./php/www.conf /etc/php/7.4/fpm/pool.d/www.conf
COPY ./nginx/server.conf /etc/nginx/sites-enabled/default.conf
COPY ./supervisor/config.conf /etc/supervisor/conf.d/supervisord.conf

# Starter file
#COPY ./php/index.php /var/www/app/index.php


EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# # Prevent exit
# ENTRYPOINT ["./entrypoint.sh"]

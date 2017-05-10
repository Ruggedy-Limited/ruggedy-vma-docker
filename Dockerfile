##########################################################################
# Ruggedy Docker Container                                               #
# Author: Ruggedy.io                                                     #
# Version 0.1 Beta                                                       #
##########################################################################

FROM ubuntu:16.04
MAINTAINER Ruggedy <hello@ruggedy.io>

##########################################################################
# Initial Server and Environment Settings                                #
##########################################################################

RUN DEBIAN_FRONTEND=noninteractive
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

ADD Files/crontab /etc/cron.d/ruggedy-cron
RUN chmod 0644 /etc/cron.d/ruggedy-cron
RUN touch /var/log/cron.log
CMD cron && tail -f /var/log/cron.log

ADD Files/nginx.conf /etc/nginx/

##########################################################################
# Repositories                                                           #
##########################################################################

RUN apt-get update
RUN apt-get upgrade -y --force-yes
RUN apt-get install -y --force-yes \
    software-properties-common\
    supervisor \
    php7.0-cli \
    php7.0-common \
    php7.0-curl \
    php7.0-json \
    php7.0-xml \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-mysql \
    php7.0-zip \
    php7.0-gd \
    php7.0-soap \
    git \
    curl \
    vim \
    nano \
    nodejs \
    zip \
    unzip \
    npm \
    nginx \
    php7.0-fpm

##########################################################################
# Configure Supervisor                                                   #
##########################################################################

RUN mkdir -p /var/log/supervisor
ADD Files/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
VOLUME ["/var/log/supervisor"]

##########################################################################
# Configure PHP-FPM and NGINX DAEMON                                     #
##########################################################################

RUN sed -i 's/;daemonize = yes/daemonize = no/g' /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i '1s/^/daemon off;\n/' /etc/nginx/nginx.conf
RUN mkdir /run/php

RUN rm /etc/php/7.0/fpm/php.ini
ADD Files/php.ini /etc/php/7.0/fpm/

RUN rm /etc/nginx/sites-available/default
RUN rm /etc/nginx/sites-enabled/default
ADD Files/default /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 
ADD Files/nginx.conf /etc/nginx/

##########################################################################
# Configure Composer                                                     #
##########################################################################

RUN curl -sS https://getcomposer.org/installer | php \
    -- --install-dir=/usr/local/bin --filename=composer

##########################################################################
# Setup and Configure Ruggedy App                                        #
##########################################################################

WORKDIR /usr/share/nginx/html/
RUN git clone https://github.com/Ruggedy-Limited/ruggedy-vma.git
ADD Files/.env /usr/share/nginx/html/ruggedy-vma

WORKDIR /usr/share/nginx/html/ruggedy-vma

RUN composer install
RUN npm install -g \
    bower

RUN npm link gulp
RUN ln -s /usr/bin/nodejs /usr/bin/node

RUN bower install --allow-root

RUN php artisan key:generate
RUN php artisan migrate --force

WORKDIR /usr/share/nginx/html
RUN chown -R www-data:www-data ./ruggedy-vma
RUN find /usr/share/nginx/html/ruggedy-vma -type d -exec chmod 755 {} \;
VOLUME ["/usr/share/nginx/html"]

CMD ["/usr/bin/supervisord"]

EXPOSE 80

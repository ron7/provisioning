#!/usr/bin/env bash

apt update
apt upgrade

# install some utilities
apt install curl build-essential

# install php${PHP_VERSION} fpm
apt install -y \
php${PHP_VERSION}-cli \
php${PHP_VERSION}-common \
php${PHP_VERSION}-curl \
php${PHP_VERSION}-fpm \
php${PHP_VERSION}-gd \
php${PHP_VERSION}-intl \
php${PHP_VERSION}-json \
php${PHP_VERSION}-ldap \
php${PHP_VERSION}-mbstring \
php${PHP_VERSION}-mysql \
php${PHP_VERSION}-opcache \
php${PHP_VERSION}-readline \
php${PHP_VERSION}-xml \
php${PHP_VERSION}-xmlrpc \
php${PHP_VERSION}-zip

apt install mariadb-server mariadb-client

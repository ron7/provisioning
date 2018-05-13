#!/usr/bin/env bash

apt update
apt upgrade

# install some utilities
apt install curl build-essential

# install php fpm
apt install -y php-cli php-common php-curl php-fpm php-gd php-intl php-json php-ldap php-mbstring php-mysql php-opcache php-readline php-xml php-xmlrpc php-zip

apt install mariadb-server mariadb-client

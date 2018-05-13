#!/usr/bin/env bash

apt update
apt upgrade

# install some utilities
apt install curl build-essential

# install php fpm
apt install -y php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-intl php7.2-json php7.2-ldap php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-readline php7.2-xml php7.2-xmlrpc php7.2-zip

#!/usr/bin/env bash

if [ ! -f /etc/php/${PHP_VERSION}/fpm/pool.d/${USER}.conf ]; then

cp ../../templates/pool.php-fpm.conf /tmp/${USER}.conf
sed -i "s/_USER_/${USER}/g" /tmp/${USER}.conf
mv /tmp/${USER}.conf /etc/php/${PHP_VERSION}/fpm/pool.d/

service php${PHP_VERSION}-fpm restart

fi
#!/usr/bin/env bash

if [ ! -d /home/${USER}/www/${DOMAIN} ]; then
    echo ${PUBLIC_HTML}
    mkdir -p ${PUBLIC_HTML}
    touch ${PUBLIC_HTML}/index.php

    chmod 751 /home/${USER}
    chown -R ${USER}.${USER} /home/${USER}/*

    cp ../../templates/vhost.nginx.conf /tmp/${DOMAIN}.conf
    sed -i "s/_DOMAIN_/${DOMAIN}/g" /tmp/${DOMAIN}.conf
    sed -i "s/_PUBLIC_HTML_/${PUBLIC_HTML_ESCAPED}/g" /tmp/${DOMAIN}.conf
    mv /tmp/${DOMAIN}.conf /etc/nginx/sites-available/
    ln -s /etc/nginx/sites-available/${DOMAIN}.conf /etc/nginx/sites-enabled/${DOMAIN}.conf

    service nginx reload
fi
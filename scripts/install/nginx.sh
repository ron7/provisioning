#!/usr/bin/env bash

cd ~

# clone openssl sources, needed for nginx SSL module compilation
git clone https://github.com/openssl/openssl --depth 1

# build nginx
bash <(curl -f -L -sS https://ngxpagespeed.com/install)  --nginx-version latest -a '\
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--user=www-data \
--group=www-data \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-http_v2_module \
--with-http_gzip_static_module \
--with-http_ssl_module \
--with-openssl=/root/openssl
'

# create sites-enabled/available skeleton
mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled
if [[ ! $(grep sites-enabled /etc/nginx/nginx.conf) ]]; then
    line=$((`grep -n "}" /etc/nginx/nginx.conf|tail -n1|cut -d ":" -f1`-1));sed -i "${line}i\    include /etc/nginx/sites-enabled/*.*;" /etc/nginx/nginx.conf;
fi

# create systems service, enable it and start it
cp ${SCRIPT_DIR}/templates/nginx.service /lib/systemd/system/nginx.service
systemctl enable --now nginx

# cleanup
rm -rf openssl
rm -rf nginx*
rm -rf incubator*
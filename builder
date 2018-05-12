#!/bin/bash
apt update -qq
apt install -y curl git
cd
git clone https://github.com/openssl/openssl --depth 1
bash <(curl -f -L -sS https://ngxpagespeed.com/install)  --nginx-version latest -a '--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=www-data --group=www-data --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module --with-http_gzip_static_module --with-openssl=/root/openssl --with-http_v2_module'

if ! grep sites-enabled /etc/nginx/nginx.conf;then line=$((`grep -n "}" /etc/nginx/nginx.conf|tail -n1|cut -d ":" -f1`-1));sed -i "${line}i\ include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf;fi

cat > /lib/systemd/system/nginx.service <<ENDD
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target

ENDD

systemctl enable --now nginx

apt install -y php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-intl php7.2-json php7.2-ldap php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-readline php7.2-sqlite3 php7.2-xml php7.2-xmlrpc php7.2-zip mariadb-server


wget -q https://raw.githubusercontent.com/ron7/provisioning/master/createDomainUser.sh -O /usr/local/bin/createDomainUser
wget -q https://raw.githubusercontent.com/ron7/provisioning/master/createMysqlUserforDB.sh -O /usr/local/bin/createMysqlUserforDB
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod u+x /usr/local/bin/createDomainUser /usr/local/bin/createMysqlUserforDB /usr/local/bin/wp

rm -rf /root/openssl /root/nginx-* /root/incubator-pagespeed-ngx-latest-stable

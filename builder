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
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

ENDD


apt install -y php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-intl php7.2-json php7.2-ldap php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-readline php7.2-sqlite3 php7.2-xml php7.2-xmlrpc php7.2-zip mariadb-server

# user level limits for open files
if ! grep "^\*\ soft\ nofile\ 64000" /etc/security/limits.conf;then echo '* soft nofile 64000' >> /etc/security/limits.conf;fi
if ! grep "^\*\ hard\ nofile\ 65000" /etc/security/limits.conf;then echo '* hard nofile 65000' >> /etc/security/limits.conf;fi
# php level limits for open files
if ! grep "^rlimit_files" /etc/php/7.2/fpm/php-fpm.conf;then sed -i '/daemonize/a rlimit_files = 64000' /etc/php/7.2/fpm/php-fpm.conf;fi

# nginx level limits for open files
if ! grep -E "^(\s+)?worker_rlimit_nofile" /etc/nginx/nginx.conf;then sed -i '/worker_processes/a worker_rlimit_nofile 64000;' /etc/nginx/nginx.conf;fi

#some more nginx global vars
if ! grep -E "^(\s+)?gzip_disable" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_disable     "msie6";' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_vary" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_vary         on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_types" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_types        text/plain text/css image/x-icon image/bmp;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_min_length" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_min_length   8;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_http_version" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_http_version 1.0;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_comp_level" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_comp_level   4;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_buffers      16 8k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_static" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_static       on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip              on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?tcp_nopush" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a tcp_nopush  on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?tcp_nodelay" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a tcp_nodelay on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?server_tokens" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a server_tokens           off;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?server_name_in_redirect" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a server_name_in_redirect off;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?sendfile" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a sendfile                 on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?recursive_error_pages" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a recursive_error_pages    on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?ignore_invalid_headers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a ignore_invalid_headers   on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_read_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_read_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_send_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_read_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_read_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_send_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_connect_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_connect_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_buffer_size 128k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_buffers 8 128k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_body_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_body_timeout 3000;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_header_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_header_timeout 3000;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a send_timeout          5;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?keepalive_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a keepalive_timeout     5 5;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?large_client_header_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a large_client_header_buffers 1 1k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_max_body_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_max_body_size      128M;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_header_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_header_buffer_size 32M;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_body_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_body_buffer_size   32k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_buffer_size 32k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_buffers 8 16k;' /etc/nginx/nginx.conf;fi

systemctl enable --now nginx
service php7.2-fpm restart

wget -q https://raw.githubusercontent.com/ron7/provisioning/master/createDomainUser.sh -O /usr/local/bin/createDomainUser
wget -q https://raw.githubusercontent.com/ron7/provisioning/master/createMysqlUserforDB.sh -O /usr/local/bin/createMysqlUserforDB
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod u+x /usr/local/bin/createDomainUser /usr/local/bin/createMysqlUserforDB /usr/local/bin/wp

rm -rf /root/openssl /root/nginx-* /root/incubator-pagespeed-ngx-latest-stable
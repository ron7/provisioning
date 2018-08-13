#!/bin/bash
export LC_ALL=C
apt update -qq
apt purge popularity-contest snapd -yqq
apt install -y curl git vim
cd
git clone https://github.com/openssl/openssl --depth 1
bash <(curl -f -L -sS https://ngxpagespeed.com/install)  --nginx-version latest -y -a '--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=www-data --group=www-data --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module --with-http_gzip_static_module --with-openssl=/root/openssl --with-http_v2_module'

mkdir /etc/nginx/sites-available /etc/nginx/sites-enabled

if ! grep sites-enabled /etc/nginx/nginx.conf;then line=$((`grep -n "}" /etc/nginx/nginx.conf|tail -n1|cut -d ":" -f1`-1));sed -i "${line}i\ include /etc/nginx/sites-enabled/*;" /etc/nginx/nginx.conf;fi

# get maximum capability of system for open files
maax=$(cat /proc/sys/fs/file-max)
# use a third of it
maxopen=$(($maax/3))

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
LimitNOFILE=$maxopen

[Install]
WantedBy=multi-user.target

ENDD


apt install -y php7.2-cli php7.2-common php7.2-curl php7.2-fpm php7.2-gd php7.2-intl php7.2-json php7.2-ldap php7.2-mbstring php7.2-mysql php7.2-opcache php7.2-readline php7.2-sqlite3 php7.2-xml php7.2-xmlrpc php7.2-zip mariadb-server certbot bash-completion

# user level limits for open files
if ! grep "^\*\ soft\ noproc\ $maxopen" /etc/security/limits.conf;then echo "* soft noproc $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^\*\ hard\ noproc\ $maxopen" /etc/security/limits.conf;then echo "* hard noproc $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^\*\ soft\ nofile\ $maxopen" /etc/security/limits.conf;then echo "* soft nofile $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^\*\ hard\ nofile\ $maxopen" /etc/security/limits.conf;then echo "* hard nofile $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^root\ soft\ noproc\ $maxopen" /etc/security/limits.conf;then echo "root soft noproc $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^root\ hard\ noproc\ $maxopen" /etc/security/limits.conf;then echo "root hard noproc $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^root\ soft\ nofile\ $maxopen" /etc/security/limits.conf;then echo "root soft nofile $maxopen" >> /etc/security/limits.conf;fi
if ! grep "^root\ hard\ nofile\ $maxopen" /etc/security/limits.conf;then echo "root hard nofile $maxopen" >> /etc/security/limits.conf;fi

# add limit to sysctl (this overwrites /proc/sys/fs/file-max value, so not using it for now..)
#if ! grep "^fs.file-max" /etc/sysctl.conf;then echo "fs.file-max = $maxopen" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.core.somaxconn" /etc/sysctl.conf;then echo "net.core.somaxconn = $maxopen" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.core.netdev_max_backlog" /etc/sysctl.conf;then echo "net.core.netdev_max_backlog = $maxopen" >> /etc/sysctl.conf;sysctl -p;fi
# some more tweaks for kernel if needed: https://serverfault.com/questions/398972/need-to-increase-nginx-throughput-to-an-upstream-unix-socket-linux-kernel-tun

if ! grep -E "^session required\s+pam_limits.so" /etc/pam.d/common-session;then echo "session required pam_limits.so" >> /etc/pam.d/common-session;fi
if ! grep -E "^session required\s+pam_limits.so" /etc/pam.d/common-session-noninteractive;then echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive;fi

# php level limits for open files
if ! grep "^rlimit_files" /etc/php/7.2/fpm/php-fpm.conf;then sed -i "/daemonize/a rlimit_files = $maxopen" /etc/php/7.2/fpm/php-fpm.conf;fi
# while we are on PHP:
sed -i "s/^upload_max_filesize = 2M/upload_max_filesize = 32M/g" /etc/php/7.2/fpm/php.ini
sed -i "s/^post_max_size = 8M/post_max_size = 64M/g" /etc/php/7.2/fpm/php.ini

# nginx level limits for open files
if ! grep -E "^(\s+)?worker_rlimit_nofile" /etc/nginx/nginx.conf;then sed -i "/worker_processes/a worker_rlimit_nofile $maxopen;" /etc/nginx/nginx.conf;fi
sed -iE "s/worker_connections.*/worker_connections $maxopen;/" /etc/nginx/nginx.conf

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
chmod u+x /usr/local/bin/createDomainUser /usr/local/bin/createMysqlUserforDB
chmod +x /usr/local/bin/wp
chmod -x /etc/update-motd.d/*

#install composer
cd
curl -sS https://getcomposer.org/installer -o composer-setup.php && php composer-setup.php --install-dir=/usr/local/bin --filename=composer

#enable bash completion
bcl=$(grep "enable bash completion in interactive shells" /etc/bash.bashrc --line-number|cut -d: -f1)
for z in `seq $(($bcl+1)) $(($bcl+7))`;do
  sed -i "${z}s/^#//" /etc/bash.bashrc
done

if ! grep "^export\ HISTCONTROL=" /etc/bash.bashrc;then echo "export HISTCONTROL=ignoredups" >> /etc/bash.bashrc;fi
if ! grep "^export\ HISTFILESIZE=" /etc/bash.bashrc;then echo "export HISTFILESIZE=" >> /etc/bash.bashrc;fi
if ! grep "^export\ HISTSIZE=" /etc/bash.bashrc;then echo "export HISTSIZE=" >> /etc/bash.bashrc;fi

rm -rf /root/openssl /root/nginx-* /root/incubator-pagespeed-ngx-latest-stable

# add /var/www, and put rainloop there as default site
mkdir -p /var/www && cd /var/www && wget -q https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip -O rainloop-community-latest.zip && unzip -q rainloop-community-latest.zip && rm -rf rainloop-community-latest.zip

# to replace the wildcard catcher, cleanup and modify the nginx.conf
sed -i "/\s*#/d" /etc/nginx/nginx.conf
sed -i "/^$/d" /etc/nginx/nginx.conf

# nginx delete from start nds to end nde:
nds=$(grep "server {" /etc/nginx/nginx.conf --line-number|cut -d: -f1)
nde=$(($(grep "include\s\+\/etc" /etc/nginx/nginx.conf --line-number|cut -d: -f1) - 1))
sed -i "${nds},${nde}d" /etc/nginx/nginx.conf

/usr/local/bin/createDomainUser _ www-data /var/www
if [[ ! `grep "listen 80 default_server" /etc/nginx/sites-available/_.conf` ]];then
  sed -i '1,/RE/s/listen 80;/listen 80 default_server;/' /etc/nginx/sites-available/_.conf
fi

if [[ ! `grep "data { deny all; }" /etc/nginx/sites-available/_.conf` ]];then
  sed -i "/.well-known/i \ \ \ \ location ^~ \/data { deny all; }" /etc/nginx/sites-available/_.conf
fi

if `nginx -qt`;then
  nginx -s reload
fi

if [ -d /etc/logrotate.d ];then
  cat > /lib/systemd/system/nginx.service <<ENDD
/var/log/nginx/*.log {
    rotate 12
    weekly
    compress
    missingok
    notifempty
    #create 644 root root
  }
ENDD
fi

apt update -qq && apt dist-upgrade -yqq && apt autoremove -yqq && dpkg -l|grep ^rc|awk '{print $2}'|xargs apt purge -yqq
# this note should always be at the end so cust can see it:
echo
echo
echo NOTE: you need to visit your server and configure rainloop at http://$(curl -s ipme.me)/?admin user: admin , default pass: 12345, CHANGE THE PASS
echo
echo


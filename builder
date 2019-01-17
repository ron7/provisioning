#!/bin/bash
export LC_ALL=C

while getopts ":n" o; do
  case "${o}" in
    n)
      #s=${OPTARG}
      NOBUILD=1
      ;;
    m)
      NOMAIL=1
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))


apt purge popularity-contest snapd -yqq

# Add php7.3
echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list
echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4F4EA0AAE5267A6C

apt update -qq


PHP_VER=$(dpkg -l|grep php|grep fpm|awk '{print $2}'|sort -n|tail -1|sed "s/php//; s/-fpm//")
if [ -z $PHP_VER ];then
  PHP_VER=7.3
fi

if [ -z $NOBUILD ];then #nobuild not set for nginx
  installnginx=
else
  installnginx=nginx
fi
apt install -y curl git vim opendkim opendkim-tools postfix $installnginx

if [ -z $NOBUILD ];then #nobuild not set for nginx

  cd
  git clone https://github.com/openssl/openssl --depth 1
  bash <(curl -f -L -sSk https://ngxpagespeed.com/install)  --nginx-version latest -y -a '--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=www-data --group=www-data --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-http_ssl_module --with-http_gzip_static_module --with-openssl=/root/openssl --with-http_v2_module --with-http_sub_module --with-http_addition_module'

fi

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

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


apt install -y php${PHP_VER}-cli php${PHP_VER}-common php${PHP_VER}-curl php${PHP_VER}-fpm php${PHP_VER}-gd php${PHP_VER}-intl php${PHP_VER}-json php${PHP_VER}-ldap php${PHP_VER}-mbstring php${PHP_VER}-mysql php${PHP_VER}-opcache php${PHP_VER}-readline php${PHP_VER}-sqlite3 php${PHP_VER}-xml php${PHP_VER}-xmlrpc php${PHP_VER}-zip mariadb-server certbot bash-completion

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

# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security_guide/sect-security_guide-server_security-disable-source-routing
# and https://askubuntu.com/questions/118273/what-are-icmp-redirects-and-should-they-be-blocked
if ! grep "^net.ipv4.conf.all.accept_redirects" /etc/sysctl.conf;then echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.ipv6.conf.all.accept_redirects" /etc/sysctl.conf;then echo "net.ipv6.conf.all.accept_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.ipv4.conf.all.send_redirects" /etc/sysctl.conf;then echo "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.ipv4.conf.default.accept_redirects" /etc/sysctl.conf;then echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.ipv6.conf.default.accept_redirects" /etc/sysctl.conf;then echo "net.ipv6.conf.default.accept_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi
if ! grep "^net.ipv4.conf.default.send_redirects" /etc/sysctl.conf;then echo "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf;sysctl -p;fi

if ! grep -E "^session required\s+pam_limits.so" /etc/pam.d/common-session;then echo "session required pam_limits.so" >> /etc/pam.d/common-session;fi
if ! grep -E "^session required\s+pam_limits.so" /etc/pam.d/common-session-noninteractive;then echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive;fi

# php level limits for open files
if ! grep "^rlimit_files" /etc/php/${PHP_VER}/fpm/php-fpm.conf;then sed -i "/daemonize/a rlimit_files = $maxopen" /etc/php/${PHP_VER}/fpm/php-fpm.conf;fi
# while we are on PHP:
sed -i "s/^upload_max_filesize = 2M/upload_max_filesize = 32M/g" /etc/php/${PHP_VER}/fpm/php.ini
sed -i "s/^post_max_size = 8M/post_max_size = 64M/g" /etc/php/${PHP_VER}/fpm/php.ini
#set opcache optimal settings: https://secure.php.net/manual/en/opcache.installation.php
if ! grep -E "^opcache.max_accelerated_files" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.max_accelerated_files=50000' /etc/php/${PHP_VER}/fpm/php.ini ;fi
if ! grep -E "^opcache.revalidate_freq" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.revalidate_freq=2' /etc/php/${PHP_VER}/fpm/php.ini ;fi
if ! grep -E "^opcache.memory_consumption" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.memory_consumption=128' /etc/php/${PHP_VER}/fpm/php.ini ;fi
if ! grep -E "^opcache.interned_strings_buffer" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.interned_strings_buffer=8' /etc/php/${PHP_VER}/fpm/php.ini ;fi
if ! grep -E "^opcache.fast_shutdown" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.fast_shutdown=1' /etc/php/${PHP_VER}/fpm/php.ini ;fi
if ! grep -E "^opcache.enable_cli" /etc/php/${PHP_VER}/fpm/php.ini ;then sed -iE '/^\[opcache\]/a opcache.enable_cli=1' /etc/php/${PHP_VER}/fpm/php.ini ;fi

# nginx level limits for open files
if ! grep -E "^(\s+)?worker_rlimit_nofile" /etc/nginx/nginx.conf;then sed -i "/worker_processes/a worker_rlimit_nofile $maxopen;" /etc/nginx/nginx.conf;fi
sed -iE "s/worker_connections.*/worker_connections $maxopen;/" /etc/nginx/nginx.conf

#some more nginx global vars
if ! grep -E "^(\s+)?gzip_proxied" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_proxied expired no-cache no-store private auth;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_disable" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_disable "msie6";' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_vary" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_vary on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_types" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript text/x-js image/x-icon image/bmp;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_min_length" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_min_length 8;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_http_version" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_http_version 1.0;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_comp_level" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_comp_level 4;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_buffers 16 8k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip_static" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip_static on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?gzip\s\+?on" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a gzip on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?tcp_nopush" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a tcp_nopush on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?tcp_nodelay" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a tcp_nodelay on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?server_tokens" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a server_tokens off;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?server_name_in_redirect" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a server_name_in_redirect off;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?sendfile" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a sendfile on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?recursive_error_pages" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a recursive_error_pages on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?ignore_invalid_headers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a ignore_invalid_headers on;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_read_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_read_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_send_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_read_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_read_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_send_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_connect_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_connect_timeout 1200s;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_buffer_size 128k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?fastcgi_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a fastcgi_buffers 8 128k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_body_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_body_timeout 3000;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_header_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_header_timeout 3000;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?send_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a send_timeout 5;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?keepalive_timeout" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a keepalive_timeout 5 5;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?large_client_header_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a large_client_header_buffers 1 1k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_max_body_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_max_body_size 128M;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_header_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_header_buffer_size 32M;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?client_body_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a client_body_buffer_size 32k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_buffer_size" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_buffer_size 32k;' /etc/nginx/nginx.conf;fi
if ! grep -E "^(\s+)?proxy_buffers" /etc/nginx/nginx.conf;then sed -iE '/http\s\+{/a proxy_buffers 8 16k;' /etc/nginx/nginx.conf;fi

systemctl enable --now nginx
service php${PHP_VER}-fpm restart

for z in web_nginx db cho certbot_me; do
  wget -q https://raw.githubusercontent.com/ron7/provisioning/master/$z -O /usr/local/bin/$z
  chmod u+x /usr/local/bin/$z
done
wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp
chmod +x /usr/local/bin/wp
chmod -x /etc/update-motd.d/*

#install composer
cd
curl -sS https://getcomposer.org/installer -o composer-setup.php && php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm -f composer-setup.php

#enable bash completion
bcl=$(grep "enable bash completion in interactive shells" /etc/bash.bashrc --line-number|cut -d: -f1)
for z in `seq $(($bcl+1)) $(($bcl+7))`;do
  sed -i "${z}s/^#//" /etc/bash.bashrc
done

if ! grep "^export\ HISTCONTROL=" /etc/bash.bashrc;then echo "export HISTCONTROL=ignoredups" >> /etc/bash.bashrc;fi
if ! grep "^export\ HISTFILESIZE=" /etc/bash.bashrc;then echo "export HISTFILESIZE=" >> /etc/bash.bashrc;fi
if ! grep "^export\ HISTSIZE=" /etc/bash.bashrc;then echo "export HISTSIZE=" >> /etc/bash.bashrc;fi

if [ -z $NOBUILD ];then #nobuild not set for nginx
  rm -rf /root/openssl /root/nginx-* /root/incubator-pagespeed-ngx-latest-stable
fi

if [ -z $NOMAIL ];then # do not exclude webmail
  # add /var/www, and put rainloop there as default site
  mkdir -p /var/www && cd /var/www && wget -q https://www.rainloop.net/repository/webmail/rainloop-community-latest.zip -O rainloop-community-latest.zip && unzip -qo rainloop-community-latest.zip && rm -rf rainloop-community-latest.zip
fi

echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>404</title><style> html, body {margin:0;padding:0;width:100%;height:100%;} @keyframes bob {0% {top:0;} 50% {top:0.2em;} } body {background:#53bfe0;vertical-align:middle;text-align:center;transform:translate3d(0, 0, 0);} body:before {content:"";display:inline-block;height:100%;vertical-align:middle;margin-right:-0.25em;} .scene {display:inline-block;vertical-align:middle;} .text {color:white;font-size:2em;font-family:helvetica;font-weight:bold;} .sheep {display:inline-block;position:relative;font-size:1em;} .sheep * {transition:transform 0.3s;} .sheep .top {position:relative;top:0;animation:bob 1s infinite;} .sheep:hover .head {transform:rotate(0deg);} .sheep:hover .head .eye {width:1.25em;height:1.25em;} .sheep:hover .head .eye:before {right:30%;} .sheep:hover .top {animation-play-state:paused;} .sheep .head {display:inline-block;width:5em;height:5em;border-radius:100%;background:#211e21;vertical-align:middle;position:relative;top:1em;transform:rotate(30deg);} .sheep .head:before {content:"";display:inline-block;width:80%;height:50%;background:#211e21;position:absolute;bottom:0;right:-10%;border-radius:50% 40%;} .sheep .head:hover .ear.one, .sheep .head:hover .ear.two {transform:rotate(0deg);} .sheep .head .eye {display:inline-block;width:1em;height:1em;border-radius:100%;background:white;position:absolute;overflow:hidden;}.sheep .head .eye:before {content:"";display:inline-block;background:black;width:50%;height:50%;border-radius:100%;position:absolute;right:10%;bottom:10%;transition:all 0.3s;}.sheep .head .eye.one {right:-2%;top:1.7em;}.sheep .head .eye.two {right:2.5em;top:1.7em;}.sheep .head .ear {background:#211e21;width:50%;height:30%;border-radius:100%;position:absolute;}.sheep .head .ear.one {left:-10%;top:5%;transform:rotate(-30deg);}.sheep .head .ear.two {top:2%;right:-5%;transform:rotate(20deg);}.sheep .body {display:inline-block;width:7em;height:7em;border-radius:100%;background:white;position:relative;vertical-align:middle;margin-right:-3em;}.sheep .legs {display:inline-block;position:absolute;top:80%;left:10%;z-index:-1;}.sheep .legs .leg {display:inline-block;background:#141214;width:0.5em;height:2.5em;margin:0.2em;}.sheep:before {content:"";display:inline-block;position:absolute;top:112%;width:100%;height:10%;border-radius:100%;background:rgba(0, 0, 0, 0.4);}</style></head><body>  <div class="scene"><div class="text">404</div><div class="text">Page Not Found!</div><br><div class="sheep"><span class="top"><div class="body"></div><div class="head"><div class="eye one"></div><div class="eye two"></div><div class="ear one"></div><div class="ear two"></div></div></span><div class="legs"><div class="leg"></div><div class="leg"></div><div class="leg"></div><div class="leg"></div></div></div></div></body></html>' > /var/www/404.html

echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>Error 500</title><style>body {background:#22a7f0;font-family:"Roboto", sans-serif;width:100%;overflow:hidden;}.cloud-container {position:absolute;top:0px;left:0px;}.cloud-container > svg {display:block;position:absolute;width:200px;left:0px;fill:#fff;opacity:0.2;-webkit-transform:translateX(-100%);transform:translateX(-100%);-webkit-animation:cloud-passover linear infinite;animation:cloud-passover linear infinite;}.cloud-container > svg:nth-child(1) {top:20px;-webkit-animation-delay:2s;animation-delay:2s;-webkit-animation-duration:12s;animation-duration:12s;}.cloud-container > svg:nth-child(2) {top:160px;-webkit-animation-delay:4s;animation-delay:4s;-webkit-animation-duration:13s;animation-duration:13s;}.cloud-container > svg:nth-child(3) {top:280px;-webkit-animation-delay:6s;animation-delay:6s;-webkit-animation-duration:11s;animation-duration:11s;}@-webkit-keyframes cloud-passover {from {-webkit-transform:translateX(-100%);transform:translateX(-100%);}  to {-webkit-transform:translateX(100vw);transform:translateX(100vw);}}@keyframes cloud-passover {from {-webkit-transform:translateX(-100%);transform:translateX(-100%);}  to {-webkit-transform:translateX(100vw);transform:translateX(100vw);}}.container {display:flex;width:100vw;height:100vh;align-items:center;justify-content:center;}.content {color:#fff;width:600px;}.heading {font-size:100px;font-weight:300;}.sorry {margin-top:20px;font-size:35px;font-weight:300;line-height:1.5;text-align:center;}</style></head><body><div class="cloud-container"><svg xmlns="http://www.w3.org/2000/svg" viewBox="31 111 450 290"><text x="120" y="320" font-size="100">Error</text><path d="M399.3 232.8c0-1.2.2-2.4.2-3.6 0-64.3-52.8-117.2-116.8-117.2-46.1 0-85.8 27.9-104.4 67-8.1-4.1-17.1-6.4-26.8-6.4-29.6 0-54.1 23.7-58.9 52C57.4 236.8 32 268.8 32 308.4c0 49.8 40.1 91.6 89.6 91.6H398c45 0 82-38.9 82-84.3 0-45.6-35.4-82.8-80.7-82.9zm-1.8 150.8l-3.2.4H122.4c-40.9 0-74.2-34.9-74.2-76.1 0-31.9 20.2-58.4 50.2-68.8l8.4-3 1.5-8.8c3.6-21.6 22.1-39.3 43.9-39.3 6.9 0 13.7 1.6 19.9 4.8l13.5 6.8 6.5-13.7c16.6-34.9 52.1-58.2 90.4-58.2 55.3 0 100.9 44.1 100.9 99.7 0 13.3-.2 20.3-.2 20.3l15.2.1c36.7.5 65.6 30.5 65.6 67.4 0 36.9-29.8 68.2-66.5 68.4z" /></svg><svg xmlns="http://www.w3.org/2000/svg" viewBox="31 111 450 290"><text x="150" y="320" font-size="100">500</text><path d="M399.3 232.8c0-1.2.2-2.4.2-3.6 0-64.3-52.8-117.2-116.8-117.2-46.1 0-85.8 27.9-104.4 67-8.1-4.1-17.1-6.4-26.8-6.4-29.6 0-54.1 23.7-58.9 52C57.4 236.8 32 268.8 32 308.4c0 49.8 40.1 91.6 89.6 91.6H398c45 0 82-38.9 82-84.3 0-45.6-35.4-82.8-80.7-82.9zm-1.8 150.8l-3.2.4H122.4c-40.9 0-74.2-34.9-74.2-76.1 0-31.9 20.2-58.4 50.2-68.8l8.4-3 1.5-8.8c3.6-21.6 22.1-39.3 43.9-39.3 6.9 0 13.7 1.6 19.9 4.8l13.5 6.8 6.5-13.7c16.6-34.9 52.1-58.2 90.4-58.2 55.3 0 100.9 44.1 100.9 99.7 0 13.3-.2 20.3-.2 20.3l15.2.1c36.7.5 65.6 30.5 65.6 67.4 0 36.9-29.8 68.2-66.5 68.4z" /></svg><svg xmlns="http://www.w3.org/2000/svg" viewBox="31 111 450 290"><text x="200" y="320" font-size="100">:(</text><path d="M399.3 232.8c0-1.2.2-2.4.2-3.6 0-64.3-52.8-117.2-116.8-117.2-46.1 0-85.8 27.9-104.4 67-8.1-4.1-17.1-6.4-26.8-6.4-29.6 0-54.1 23.7-58.9 52C57.4 236.8 32 268.8 32 308.4c0 49.8 40.1 91.6 89.6 91.6H398c45 0 82-38.9 82-84.3 0-45.6-35.4-82.8-80.7-82.9zm-1.8 150.8l-3.2.4H122.4c-40.9 0-74.2-34.9-74.2-76.1 0-31.9 20.2-58.4 50.2-68.8l8.4-3 1.5-8.8c3.6-21.6 22.1-39.3 43.9-39.3 6.9 0 13.7 1.6 19.9 4.8l13.5 6.8 6.5-13.7c16.6-34.9 52.1-58.2 90.4-58.2 55.3 0 100.9 44.1 100.9 99.7 0 13.3-.2 20.3-.2 20.3l15.2.1c36.7.5 65.6 30.5 65.6 67.4 0 36.9-29.8 68.2-66.5 68.4z" /></svg></div><div class="container"><div class="content"><div class="heading">System Error</div><div class="sorry">Error 500</div></div></div></body></html>' > /var/www/500.html

cat > /etc/nginx/include_standard_errors.conf <<ENDD
error_page 404 /404.html;
error_page 500 502 503 504 /500.html;
location = /500.html { root /var/www; internal; }
location = /404.html { root /var/www; internal; }
ENDD

cat > /etc/nginx/include_cache.conf <<ENDD
# https://www.nginx.com/blog/nginx-caching-guide/
# needs in nginx.conf>http: proxy_cache_path /var/cache/nginx/my_cache levels=1:2 keys_zone=my_cache:10m max_size=10g inactive=60m use_temp_path=off;
proxy_cache_valid 200 1d;
proxy_cache_revalidate on;
proxy_cache_min_uses 3;
proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
proxy_cache_background_update on;
proxy_cache_lock on;
ENDD

# to replace the wildcard catcher, cleanup and modify the nginx.conf
sed -i "/\s*#/d" /etc/nginx/nginx.conf
sed -i "/^$/d" /etc/nginx/nginx.conf

# nginx delete from start nds to end nde:
nds=$(grep "server {" /etc/nginx/nginx.conf --line-number|cut -d: -f1)
nde=$(($(grep "include\s\+\/etc" /etc/nginx/nginx.conf --line-number|cut -d: -f1) - 1))
sed -i "${nds},${nde}d" /etc/nginx/nginx.conf

if ! grep -rE "default_server" /etc/nginx/sites-enabled/*;then
  /usr/local/bin/web_nginx _ www-data /var/www
  if [[ ! `grep "listen 80 default_server" /etc/nginx/sites-available/_.conf` ]];then
    sed -i '1,/RE/s/listen 80;/listen 80 default_server;/' /etc/nginx/sites-available/_.conf
  fi

  if [[ ! `grep "data { deny all; }" /etc/nginx/sites-available/_.conf` ]];then
    sed -i "/.well-known/i \ \ \ \ location ^~ \/data { deny all; }" /etc/nginx/sites-available/_.conf
  fi
fi

if `nginx -qt`;then
  nginx -s reload
fi

if [ -d /etc/logrotate.d ];then
  if [ ! -f /etc/logrotate.d/nginx ];then
    cat > /etc/logrotate.d/nginx <<ENDD
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
fi
#locales:
locale-gen bg_BG.UTF-8 en_US.UTF-8
echo LANG=C.UTF-8 > /etc/default/locale

apt update -qq && apt dist-upgrade -yqq && apt autoremove -yqq && dpkg -l|grep ^rc|awk '{print $2}'|xargs apt purge -yqq

#DKIM (partial) config
host=$(hostname -f|awk -F'.' '{gsub("http://|/.*","")} NF>2{$1="";$0=substr($0, 2)}1' OFS='.')
opendkim-genkey -d $host -D /etc/dkimkeys/
#add postfix to group: opendkim so it can read sock
adduser postfix opendkim
sed -iE "s/^UMask.*/UMask 002/" /etc/opendkim.conf
if ! grep -E "^Selector" /etc/opendkim.conf ;then sed -iE '/^UMask/a Selector default' /etc/opendkim.conf ;fi
if ! grep -E "^KeyFile" /etc/opendkim.conf ;then sed -iE '/^UMask/a KeyFile /etc/dkimkeys/default.private' /etc/opendkim.conf ;fi
if ! grep -E "^Domain" /etc/opendkim.conf ;then sed -iE "/^UMask/a Domain $host" /etc/opendkim.conf ;fi
if ! grep -E "^Socket" /etc/opendkim.conf ;then sed -iE '/^UMask/a Socket inet:8892@localhost' /etc/opendkim.conf ;fi
#add few lines to postfix main.cf for DKIM:
if ! grep -E "^milter_default_action" /etc/postfix/main.cf ;then echo "milter_default_action = accept" >> /etc/postfix/main.cf ;fi
if ! grep -E "^milter_protocol" /etc/postfix/main.cf ;then echo "milter_protocol = 6" >> /etc/postfix/main.cf ;fi
if ! grep -E "^smtpd_milters" /etc/postfix/main.cf ;then echo "smtpd_milters = inet:localhost:8892" >> /etc/postfix/main.cf ;fi
if ! grep -E "^non_smtpd_milters" /etc/postfix/main.cf ;then echo "non_smtpd_milters = inet:localhost:8892" >> /etc/postfix/main.cf ;fi
if [ -e /etc/dkimkeys/default.txt ];then
  echo
  echo ::: DKIM
  echo
  echo Please set this DKIM record for host: $host
  cat /etc/dkimkeys/default.txt
  echo
  echo
fi

service postfix restart
service opendkim restart

# this note should always be at the end so cust can see it:
if [ -z $NOMAIL ];then # do not exclude webmail
  echo
  echo NOTE: you need to visit your server and configure rainloop at http://$(curl -s ipme.me)/?admin user: admin , default pass: 12345, CHANGE THE PASS
  echo
fi


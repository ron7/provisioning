#!/usr/bin/env bash
if [ "$1" != "" ]; then
#echo first argument is $1
echo Domain is: $1
echo User is: $2
#echo Optional ID is: $3
currentpath=`pwd`
#install php5-fpm
echo Creating user $2:
groupadd $2
useradd -s /bin/false -d /home/$2 -m -g $2 $2
mkdir -p /home/$2/www;mkdir -p /home/$2/dev;touch /home/$2/www/index.php;touch /home/$2/dev/index.php;chmod 751 /home/$2/www /home/$2/dev;chown -R $2.$2 /home/$2/*
echo
echo Domain contents should be in /home/$2/www/
echo
id=`id $2 -u`
#port=$(($id+8000))
mkdir -p /etc/nginx/sites-enabled/;mkdir -p /etc/nginx/sites-available/
echo Creating NginX config file: /etc/nginx/sites-available/$1.conf
cat > /etc/nginx/sites-available/$1.conf <<ENDD
#limit_req_zone \$binary_remote_addr zone=one:10m rate=20r/m;
#limit_rate 300K; limit_conn_zone \$binary_remote_addr zone=two:4m;
server {
    server_name  www.$1;
    rewrite ^(.*) http://$1\$1 permanent;
}
server {
  set \$rewritetossl 1;
  set \$enablessl 1; #not working yet

  listen 80;
  server_name $1;
  root /home/$2/www;

  if (\$rewritetossl = 1) {
    set \$check_ssl_prot "\${ssl_protocol}P";
  }

#  ## SSL: forcing SSL:
#      if (\$check_ssl_prot = P) {
#         rewrite ^   https://\$server_name\$request_uri? permanent;
#      }

##  if (\$enablessl = 1) {
#    listen 443 ssl http2;
#    ssl_certificate /home/$2/$1.pem;
#    ssl_certificate_key /home/$2/$1.key;

#  ## Optimizing SSL/TLS
#    ssl_session_cache shared:SSL:1m;
#    ssl_session_timeout  10m;
#    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
#    ssl_prefer_server_ciphers on;
#    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
#    ssl_ecdh_curve secp384r1;
#    ssl_session_tickets on;
#    ssl_stapling on;
#    ssl_stapling_verify on;
#    resolver 8.8.8.8 8.8.4.4 valid=300s;
#    resolver_timeout 5s;

#  ## SSL END
##}

  access_log /var/log/nginx/$1_access.log;
  error_log /var/log/nginx/$1_error.log;
  index index.php index.html;


  if (\$request_method !~ ^(GET|HEAD|POST)$ ) { return 444;  }

    location = /favicon.ico { try_files /favicon.ico =204; access_log off; log_not_found off; }
    location = /favicon.png { try_files /favicon.png =204; access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }

    location ~ /.well-known { allow all;}
    location ~ /\\. { deny  all; access_log off; log_not_found off; }
    location ~* ^/(?:README|LICENSE[^.]*|LEGALNOTICE)(?:\\.txt)*$ {  return 404;  }
    location ~* ^.+.(jpg|jpeg|gif|png|ico|css|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|txt|tar|mid|midi|wav|bmp|rtf|js)$ {
    valid_referers server_names;
    if (\$invalid_referer)  { return 444; }
      expires    max;
      access_log off;
      add_header Cache-Control public;
      add_header Access-Control-Allow-Origin *;
      break;
    }

    gzip             on;
    gzip_min_length  1000;
    gzip_buffers  4 32k;
    gzip_proxied     expired no-cache no-store private auth;
    gzip_types       text/plain application/xml application/x-javascript application/javascript text/css;
    gzip_disable     "MSIE [1-6]\\.";
    gzip_disable     "msie6";
    gzip_vary on;


    location / {
#   root /home/$2/www;
    index index.php index.html;
    try_files \$uri \$uri/ /index.php?q=\$uri;

    gzip             on;
    gzip_min_length  1000;
    gzip_buffers  4 32k;
    gzip_proxied     expired no-cache no-store private auth;
    gzip_types       text/plain application/xml application/x-javascript application/javascript text/css;
    gzip_disable     "MSIE [1-6]\\.";
    gzip_disable     "msie6";
    gzip_vary on;

#   limit_req zone=one burst=5 nodelay;
#   limit_conn two 1;
  }


  location ~ \.php$ {
  fastcgi_connect_timeout 60;
  fastcgi_send_timeout 180;
#  fastcgi_read_timeout 180;
  fastcgi_buffer_size 128k;
  fastcgi_buffers 4 256k;
  fastcgi_busy_buffers_size 256k;
  fastcgi_temp_file_write_size 256k;
  fastcgi_intercept_errors on;
#  fastcgi_cache_key \$host\$request_uri;
  fastcgi_pass   unix:/var/run/php-fpm_$2.sock;
  fastcgi_index  index.php;
#  fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
  fastcgi_param  SCRIPT_FILENAME  \$fastcgi_script_name;
  fastcgi_param  SCRIPT_NAME  \$fastcgi_script_name;
  include fastcgi_params;
  fastcgi_param USER  $2;
  fastcgi_read_timeout 1800;

#          limit_req zone=one burst=5 nodelay;
#          limit_conn two 1;
      }
#          error_page 503 /error_503.html;
  }

### Dev subdomain:
server {
  listen 80;
  server_name dev.$1;
  root /home/$2/dev;
  access_log /var/log/nginx/dev.$1_access.log;
  error_log /var/log/nginx/dev.$1_error.log;
  index index.php index.html;

  location = /robots.txt { access_log off; log_not_found off; }
  location ~ /\\. { deny  all; access_log off; log_not_found off; }
  location ~* ^/(?:README|LICENSE[^.]*|LEGALNOTICE)(?:\\.txt)*$ {  return 404;  }
  location ~* ^.+.(jpg|jpeg|gif|png|ico|css|tgz|gz|rar|bz2|doc|xls|exe|pdf|ppt|txt|tar|mid|midi|wav|bmp|rtf|js)$ {
  valid_referers server_names;
  if (\$invalid_referer)  { return 444; }
    expires    max;
    access_log off;
    add_header Cache-Control public;
    add_header Access-Control-Allow-Origin *;
    break;
  }
  location / {
  index index.php index.html;
  try_files \$uri \$uri/ /index.php?q=\$uri;
      }

      location ~ \.php$ {
      fastcgi_cache_key \$host\$request_uri;
      fastcgi_pass   unix:/var/run/php-fpm_$2.sock;
      fastcgi_index  index.php;
      fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
      fastcgi_param  SCRIPT_FILENAME  \$fastcgi_script_name;
      fastcgi_param  SCRIPT_NAME  \$fastcgi_script_name;
      include fastcgi_params;
      fastcgi_param USER  $2;
      fastcgi_read_timeout 600;
    }
}

ENDD
echo Done. This file can be edited to add additional features !!
echo Creating NginX SymLink...
cd /etc/nginx/sites-enabled/
ln -s ../sites-available/$1.conf $1.conf
cd $currentpath
echo Adding pool to php-fpm...
mkdir -p /etc/php/7.2/fpm/pool.d/
cat > /etc/php/7.2/fpm/pool.d/$2.conf <<ENDD
[$2]
listen.owner = $2
listen.group = $2
listen.mode = 0666
listen = /var/run/php-fpm_$2.sock
user = $2
group = $2
pm = dynamic
pm.max_children = 5
pm.start_servers = 1
pm.min_spare_servers = 1
pm.max_spare_servers = 2
;pm.max_requests = 500
php_admin_value[cgi.fix_pathinfo] = 0;
ENDD
if  [[ -z `grep "SCRIPT_FILENAME" /etc/nginx/fastcgi_params`  ]];then sed -i '/SCRIPT_NAME/i fastcgi_param  SCRIPT_FILENAME    \$document_root\$fastcgi_script_name;' /etc/nginx/fastcgi_params ;fi

echo Reloading services:
#/etc/init.d/nginx reload
service nginx reload
/etc/init.d/php7.2-fpm reload

#echo Adding $1 to Piwik, with ID:
#piwikid=`curl -sk "https://7.xron.net/index.php?module=API&method=SitesManager.addSite&siteName=$1&urls=http://$1&format=JSON&token_auth=446ef1efb369403c57f45ca6214dfe56"|grep -o '[0-9]*'`
#echo $piwikid
#echo add the following to cron:
##!/bin/bash
#echo python /home/dev/www/dev/7/misc/log-analytics/import_logs.py --url=http://7.xron.net/ /var/log/nginx/$1* --idsite=$piwikid --recorders=4 --enable-http-redirects --enable-http-errors --enable-bots --enable-static --recorder-max-payload-size=300 --log-format-name=ncsa_extended
#echo wait
#echo php /home/dev/www/dev/7/console core:archive --url=http://7.xron.net/ \>\> /var/log/piwik_\`date +\\%G-\\%m-\\%d\`-archive.log
#echo I think it is all done


else
echo Usage: $0 domain.com username
echo Example: $0 xron.net xron
echo All 2 parameters must be present !
fi


#!/usr/bin/env bash
PHP_VER=7.2

if ! nginx -v 2>/dev/null;then echo -e "\n::: nginx missing, aborting\n\n";exit 1;fi
if ! php-fpm${PHP_VER} -v 1>/dev/null;then echo -e "\n::: php missing, aborting\n\n";exit 1;fi

if [ "$1" != "" ]; then
  echo Domain is: $1
  echo User is: $2
  currentpath=`pwd`
  echo Creating user $2:
  groupadd $2
  useradd -s /bin/false -d /home/$2 -m -g $2 $2
  mkdir -p /home/$2/www;mkdir -p /home/$2/dev;touch /home/$2/www/index.php;touch /home/$2/dev/index.php;chmod 751 /home/$2/www /home/$2/dev;chown -R $2.$2 /home/$2/*
  echo -e "\nDomain contents should be in /home/$2/www/\n"
  id=`id $2 -u`
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
#         rewrite ^   https://\$server_name\$request_uri permanent;
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
#    resolver 1.1.1.1 8.8.8.8 valid=300s;
#    resolver_timeout 5s;

#  ## SSL END
##}

  access_log /var/log/nginx/$1_access.log;
  error_log /var/log/nginx/$1_error.log;
  index index.php index.html;

#  include include_cache.conf;

  if (\$request_method !~ ^(GET|HEAD|POST)$ ) { return 444;  }

    location = /favicon.ico { try_files /favicon.ico =204; access_log off; log_not_found off; }
    location = /favicon.png { try_files /favicon.png =204; access_log off; log_not_found off; }
    location = /robots.txt { access_log off; log_not_found off; }

    location ~ /.well-known { allow all;}
    location ~ /\\. { deny  all; access_log off; log_not_found off; }
    location ~* ^/(?:README|LICENSE[^.]*|LEGALNOTICE)(?:\\.txt)*$ {  return 404;  }

    location ~* \\.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)$ {
    valid_referers server_names;
    if (\$invalid_referer)  { return 444; }
      add_header Cache-Control "public";
      add_header Access-Control-Allow-Origin *;
      add_header X-Frame-Options "DENY";
      expires +1y;
      try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location ~* \\.(zip|gz|gzip|bz2|csv|xml)$ {
      add_header Cache-Control "no-store";
      add_header Access-Control-Allow-Origin *;
      add_header X-Frame-Options "DENY";
      expires    off;
      try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    add_header X-Frame-Options "DENY";

    gzip             on;
    gzip_min_length  1000;
    gzip_buffers  4 32k;
    gzip_proxied     expired no-cache no-store private auth;
    gzip_types       text/plain application/xml application/x-javascript application/javascript text/css;
    gzip_disable     "MSIE [1-6]\\.";
    gzip_disable     "msie6";
    gzip_vary on;


    location / {
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
  fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
#  fastcgi_param  SCRIPT_FILENAME  \$fastcgi_script_name;
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
  location ~* ^.+.(jpg|jpeg|gif|png|ico|css|js)$ {
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
    #  fastcgi_param  SCRIPT_FILENAME  \$fastcgi_script_name;
      fastcgi_param  SCRIPT_NAME  \$fastcgi_script_name;
      include fastcgi_params;
      fastcgi_param USER  $2;
      fastcgi_read_timeout 600;
    }
  }

ENDD


if [[ $varnish -eq 1 ]];then

if [[ `varnishd -V` ]];then

cat > /etc/varnish/default.vcl <<ENDD
vcl 4.0;
backend default {
        .host = "localhost";
        .port = "8080";
}
#Allow cache-purging requests only from localhost using the acl directive:
acl purger {
        "localhost";
#"203.0.113.100";
}

sub vcl_recv {
#Redirect HTTP requests to HTTPS for our SSL website:
#       if (client.ip != "127.0.0.1" && req.http.host ~ "test.digitalcopy.pro") { set req.http.x-redir = "https://test.digitalcopy.pro" + req.url; return(synth(850, "")); }

        if (req.method == "PURGE") {
                if (!client.ip ~ purger) {
                        return(synth(405, "This IP is not allowed to send PURGE requests."));
                }
                return (purge);
        }

        if (req.restarts == 0) {
                if (req.http.X-Forwarded-For) {
                        set req.http.X-Forwarded-For = client.ip;
                }
        }
#Exclude POST requests or those with basic authentication from caching:
        if (req.http.Authorization || req.method == "POST") {
                return (pass);
        }
#Exclude RSS feeds from caching:
        if (req.url ~ "/feed") {
                return (pass);
        }
#Tell Varnish not to cache the WordPress admin and login pages:
        if (req.url ~ "wp-admin|wp-login") {
                return (pass);
        }
#WordPress sets many cookies that are safe to ignore. To remove them, add the following lines:
        set req.http.cookie = regsuball(req.http.cookie, "wp-settings-\d+=[^;]+(; )?", "");
        set req.http.cookie = regsuball(req.http.cookie, "wp-settings-time-\d+=[^;]+(; )?", "");
        if (req.http.cookie == "") {
                unset req.http.cookie;
        }

}

#Redirect HTTP to HTTPS using the sub vcl_synth directive with the following settings:
sub vcl_synth {
        if (resp.status == 850) {
                set resp.http.Location = req.http.x-redir;
                set resp.status = 302;
                return (deliver);
        }
}
#Cache-purging for a particular page must occur each time we make edits to that page
sub vcl_purge {
        set req.method = "GET";
        set req.http.X-Purger = "Purged";
        return (restart);
}

#The sub vcl_backend_response directive is used to handle communication with the backend server, NGINX. We use it to set the amount of time the content remains in the cache. We can also set a grace period, which determines how Varnish will serve content from the cache even if the backend server is down. Time can be set in seconds (s), minutes (m), hours (h) or days (d). Here, we've set the caching time to 24 hours, and the grace period to 1 hour, but you can adjust these settings based on your needs:
sub vcl_backend_response {
        set beresp.ttl = 24h;
        set beresp.grace = 1h;
#allow cookies to be set only if you are on admin pages or WooCommerce-specific pages:
        if (bereq.url !~ "wp-admin|wp-login|product|cart|checkout|my-account|/?remove_item=") {
                unset beresp.http.set-cookie;
        }
}
#Change the headers for purge requests by adding the sub vcl_deliver directive:
sub vcl_deliver {
        if (req.http.X-Purger) {
                set resp.http.X-Purger = req.http.X-Purger;
        }
}

ENDD

else
echo -e "\n::: Varnish NOT installed\n"
fi

fi

echo Creating Nginx links...
cd /etc/nginx/sites-enabled/
ln -s ../sites-available/$1.conf $1.conf
cd $currentpath
echo Adding pool to php-fpm...
mkdir -p /etc/php/${PHP_VER}/fpm/pool.d/
cat > /etc/php/${PHP_VER}/fpm/pool.d/$2.conf <<ENDD
[$2]
listen.owner = $2
listen.group = $2
listen.mode = 0666
listen.backlog = 65535
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
service nginx reload
service php${PHP_VER}-fpm reload

else
  echo Usage: $0 domain.com username
  echo Example: $0 xron.net xron
  echo All 2 parameters must be present !
fi


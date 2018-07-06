#!/usr/bin/env bash
# Generate a random password
#  $1 = number of characters; defaults to 32
#  $2 = include special characters; 1 = yes, 0 = no; defaults to 1
function randpass() {
  [ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]" || CHAR="#"
    cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32}
    echo
}

if [ "$1" != "" ] ; then
#echo first argument is $1
echo Database to use: $1
if [ "$2" != "" ]; then
        user=$2
else
        user=$1
fi
echo User is: $user
if [ "$3" != "" ]; then
	pass=$3
else
	pass=`randpass 20 0`
fi
echo Pass is: $pass
echo "INFO: $(date +"%Y%m%d_%H:%m:%S")_$(id -un)|$1|$user|$pass" >> /root/dbusers
echo "mysql -e \"create database if not exists $1 DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_general_ci\"" >> /root/dbusers
echo "mysql -e \"GRANT ALL PRIVILEGES ON $1.* TO '$user'@'%' identified by '$pass'\"" >> /root/dbusers
#mysql -e "create database if not exists $1"
mysql -e "create database if not exists $1 DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_general_ci"
mysql -e "GRANT ALL PRIVILEGES ON $1.* TO '$user'@'%' identified by '$pass'"
echo Done.
else
echo Usage: $0 ExistingDB username pass
echo Example: $0 interesting interesting 823796$^589
#randpass 30 0 
fi

#!/bin/bash

#Check variables before run
set -u

#CHECK_WP_INSTALLED=`mysqlshow --user=root --password=password --host mysql_master wordpress | grep -o wp_options`
echo "---------------------------------------------------------------------"
echo "---------------------  * Wait 40 sec for MySQL  ---------------------"
echo "---------------------------------------------------------------------"

sleep ${WP_WAIT_MYSQL}
echo
echo "* Check wp-cli info"
echo
wp --info
echo
echo "---------------------"
echo

chown -R 33:33 /var/www/${MYSQL_DATABASE}

if [ -z "$(ls -A /var/www/wordpress | grep -v wp-content)" ]; then
   echo "* Web root directory is empty. Install Wordpress"
   wp core download --version=${WP_VERSION}
   wp core config --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_WP_PASSWORD}" --dbhost="${MYSQL_MASTER}" --dbprefix=wp_
   wp core install --url="${WP_URL}" --title="${WP_TITLE}" --admin_user="${WP_ADMIN_USERNAME}" --admin_password="${WP_ADMIN_PASSWORD}" --admin_email="${WP_ADMIN_EMAIL}"
else
   echo "* Wordpres directory is not empty. Nothing more to do."
fi

# //TODO Install HyperDB Plugin and split reads between master and slave
# // https://pantheon.io/docs/hyperdb/

php-fpm

#!/bin/bash
BASE_PATH=$(dirname $0)

#Give 30 seconds for master and slave to come up
echo
echo "---------------------------------------------------------------------"
echo "---------------------  * Wait 30 sec for MySQL  ---------------------"
echo "---------------------------------------------------------------------"
sleep ${MYSQL_INIT_WAIT_SEC}
echo
echo "* Create master/slave replication"
echo
echo "---------------------"
echo
echo "* Create user credentials file"
#//TODO: Pass secrets from variables
cat > ~/.slave.cnf <<-'EOF'
[client]
user=root
password=password
EOF

cat > ~/.master.cnf <<-'EOF'
[client]
user=root
password=password
EOF
chmod 600 ~/.slave.cnf ~/.master.cnf
echo
echo "---------------------"
echo
echo "* Create replication user on SLAVE"
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e \
    "CREATE USER IF NOT EXISTS '${MYSQL_REPLICATION_USER}'@'%'; \
    GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '${MYSQL_REPLICATION_PASSWORD}'; \
    FLUSH PRIVILEGES;"
echo
echo "* Create replication user on MASTER"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -AN -e \
    "CREATE USER IF NOT EXISTS '${MYSQL_REPLICATION_USER}'@'%'; \
    GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REPLICATION_USER}'@'%' IDENTIFIED BY '${MYSQL_REPLICATION_PASSWORD}'; \
    FLUSH PRIVILEGES;"
echo
echo "---------------------"
echo
echo "* Stop SLAVE"
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e 'STOP SLAVE;';
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e 'RESET SLAVE ALL;';
echo
#//TODO Clean hardcoded db hostnnames
echo "* Getting POSITION on MASTER"
MYSQL01_Position=$(eval "mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
echo "** MySQL POSITION: ${MYSQL01_Position}"
echo
MYSQL01_File=$(eval "mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")
echo "** MySQL FILE: ${MYSQL01_File}"
echo
MASTER_IP=$(eval "getent hosts mysql_master|awk '{print \$1}'")
echo "** Master IP: ${MASTER_IP}"
echo
echo "Setup SLAVE"
echo
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e "CHANGE MASTER TO master_host='mysql_master', master_port=3306, \
        master_user='${MYSQL_REPLICATION_USER}', master_password='${MYSQL_REPLICATION_PASSWORD}', master_log_file='${MYSQL01_File}', \
        master_log_pos=${MYSQL01_Position};"
echo
echo "---------------------"
echo
echo "* Getting POSITION on SLAVE"
MYSQL02_Position=$(eval "mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
echo "** MySQL POSITION: ${MYSQL02_Position}"
echo
MYSQL02_File=$(eval "mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")
echo "** MySQL FILE: ${MYSQL02_File}"
echo
SLAVE_IP=$(eval "getent hosts mysql_slave|awk '{print \$1}'")
echo "** Master IP: ${SLAVE_IP}"
echo
echo "Setup MASTER"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -AN -e \
    "STOP SLAVE IO_THREAD; \
    CHANGE MASTER TO master_host='mysql_slave', master_port=3306, master_user='${MYSQL_REPLICATION_USER}', \
    master_password='${MYSQL_REPLICATION_PASSWORD}', master_log_file='${MYSQL02_File}', \
    master_log_pos=${MYSQL02_Position}; START SLAVE IO_THREAD;"
echo
echo "---------------------"
echo
echo "* Start SLAVE"
echo
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e "start slave;"
echo "---------------------"

echo "* Increase the max_connections to 2000"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -AN -e 'set GLOBAL max_connections=2000';
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -AN -e 'set GLOBAL max_connections=2000';
echo
echo "* SLAVE status"
mysql --defaults-extra-file='~/.slave.cnf' --host mysql_slave -e "show slave status \G"
echo
echo "* MASTER status"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e "show master status \G"
echo
echo "* Create a database for Wordpress if needed"
echo
CHECK_WP_DB_EXIST=`mysqlshow --user=root --password=${MYSQL_ROOT_PASSWORD} --host mysql_master ${MYSQL_DATABASE} | grep -o ${MYSQL_DATABASE}`
if [ "$CHECK_WP_DB_EXIST" == "${MYSQL_DATABASE}" ]; then
    echo Database wordpress exist. Nothing to do.
    exit 0
fi
echo
echo "* Database does not exist. Creating."
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} CHARACTER SET UTF8mb4 collate utf8mb4_unicode_ci;"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e "CREATE USER IF NOT EXISTS ${MYSQL_USER}@'%' IDENTIFIED BY '${MYSQL_WP_PASSWORD}';"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO ${MYSQL_USER}@'%';"
mysql --defaults-extra-file='~/.master.cnf' --host mysql_master -e "FLUSH PRIVILEGES;"

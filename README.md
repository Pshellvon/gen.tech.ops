
# Prerequisites

```
K(Ubuntu)       18:04
Docker          18.06.0-ce, build 0ffa825
Docker-Compose  1.21.2, build a133471
```

# Versions

```
NGINX           nginx/1.15.0
PHP             7.1.20
WP-CLI          1.5.1
```

# Create .env file from example

Set WP_URL to your URL

Please, do not store secrets in public.

```
MYSQL_ROOT_PASSWORD=password

MYSQL_USER=wordpress
MYSQL_DATABASE=wordpress
MYSQL_WP_PASSWORD=password

MYSQL_SLAVE_PASSWORD=password
MYSQL_MASTER_PASSWORD=password
MYSQL_REPLICATION_USER=repl
MYSQL_REPLICATION_PASSWORD=password
MYSQL_SLAVE=mysql_slave

MYSQL_INIT=mysql_configure
MYSQL_INIT_WAIT_SEC=30

MYSQL_MASTER=mysql_master
WP_VERSION=latest
WP_URL=192.168.1.143
WP_TITLE="BlogZis"
WP_ADMIN_USERNAME=admin
WP_ADMIN_PASSWORD=password
WP_ADMIN_EMAIL=pshellvon@gmail.com
WP_WAIT_MYSQL=40
```


# Run

```
git clone https://github.com/Pshellvon/gen.tech.ops.git
cd gen.tech.ops
sudo docker network create backend
sudo docker network create frontend
sudo docker-compose up
```


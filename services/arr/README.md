# 'ARR Stack

This stack contains the primary 'ARR apps (Lidarr, Prowlarr, Readarr, Radarr, and Sonarr).

## Scripts

`chmod +x ./scripts/*.sh`

In Docker, go to Connect -> Custom Script and add `radarr-featurettes.sh`. This script will handle importing extras.

## PostgreSQL Setup

To use PostgreSQL with an 'ARR app, you simply need to edit the configuration in both `appname-volume` and `appname-db-config-volume*`.

```sh
sudo nano /path/to/docker/volumes/appname-volume/_data/config.xml
```

```xml
<!-- if you are using readarr, add the following -->
<!-- <PostgresCacheDb>appname-cache</PostgresCacheDb> -->
<!-- if you're using prowlarr, set host to 127.0.0.1 -->
<PostgresHost>appname-db</PostgresHost>
<PostgresLogDb>appname-log</PostgresLogDb>
<PostgresMainDb>appname-main</PostgresMainDb>
<PostgresPassword>whatever_your_pass_is_in_env</PostgresPassword>
<PostgresPort>5432</PostgresPort>
<PostgresUser>postgres</PostgresUser>
```

```sh

# start; wait for initialization; shut down 'arr app
docker compose up -d appname appname-db
docker compose down appname

# create databases
docker compose exec -it appname-db sh
psql --user=postgres
```

```SQL
CREATE DATABASE "appname-main";
CREATE DATABASE "appname-log";

-- if you are using readarr, do this
-- CREATE DATABASE "appname-cache";
\q
```

```sh
exit

# update psql config
sudo nano /path/to/docker/volumes/appname-db-config-data/_data/pg_hba.conf
host appname-main postgres 0.0.0.0/0 password
host appname-log postgres 0.0.0.0/0 password

# if you are using readarr, add this
# host appname-cache postgres 0.0.0.0/0 password
```

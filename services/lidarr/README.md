# Lidarr

In order to configure Lidarr to use PostgreSQL, we will need to edit the configuration file.
We are going to use one database for all data - it's not ideal, but it works right now.

```sh
# https://wiki.servarr.com/en/lidarr/postgres-setup
sudo nano /var/lib/docker/volumes/lidarr-volume/_data/config.xml
```

```XML
<PostgresHost>lidarr-db</PostgresHost>
<PostgresLogDb>postgres</PostgresLogDb>
<PostgresMainDb>postgres</PostgresMainDb>
<PostgresPassword>COPY_YOUR_ENV_VAR_HERE</PostgresPassword>
<PostgresPort>5432</PostgresPort>
<PostgresUser>postgres</PostgresUser>
```

Upon reboot, Lidarr should start using PostgreSQL. It may error about UpdateHistory, but who cares.

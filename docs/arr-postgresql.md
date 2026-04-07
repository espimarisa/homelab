# 'ARR Apps

The following documentation applies to the primary 'ARR apps (Bazarr, Lidarr, Prowlarr, Radarr, and Sonarr).

## PostgreSQL Setup

It's heavily suggested to configure each 'ARR app to use PostgreSQL instead of SQLite for better performance and reliability. The `arr-db` container is a PostgreSQL container meant for usage by each primary 'ARR app.

In order to configure each 'ARR app to use PostgreSQL, you will need to do some manual configuration.

1. Start the PostgreSQL container. `docker compose up -d arr-db`
2. Connect to sh inside of the container. `docker compose exec -it arr-db sh`.
3. Connect to a PostgreSQL shell. `psql -U postgres`
4. Create the required databases for each 'ARR app. Replace `appname` with the name of your 'ARR app.
    1. `CREATE DATABASE "appname-main";`
    2. `CREATE DATABASE "appname-logs";`
5. Exit the PostgreSQL shell and container shell. `\q` and then `exit`.
6. Stop the PostgreSQL container. `docker compose down arr-db`.
7. Edit the `pg_hba.conf` file. `sudo nano /path/to/docker/volumes/arr-db-config-volume/_data/pg_hba.conf`
    1. Append `host all all 0.0.0.0/0 password` to the bottom.
8. Start the PostgreSQL container again. `docker compose up -d arr-db`

Now, we need to tell each app to use PostgreSQL.

1. Start each 'ARR app for the first time. `docker compose up -d lidarr prowlarr radarr sonarr`.
2. Stop each 'ARR app when they finish starting. `docker compose down lidarr prowlarr radarr sonarr`

Next, you will want to update the configuration file. Replace appname-main and appname-logs with the name of your 'ARR app.

`sudo nano /path/to/docker/volumes/appname-volume/_data/config.xml`

```xml
       <PostgresHost>arr-db</PostgresHost>
       <PostgresMainDb>appname-main</PostgresMainDb>
       <PostgresLogDb>appname-logs</PostgresLogDB>
       <PostgresPassword>your-psql-password</PostgresPassword>
       <PostgresPort>5432</PostgresPort>
       <PostgresUser>postgres</PostgresUser>
```

Finally, you can start your 'ARR apps again and they should be using PostgreSQL.

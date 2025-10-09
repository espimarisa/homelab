# Chhoto URL Shortener

Chhoto is a snazzy little URL shortener. Before you start using it, you need to initialze the database and take ownership of the volume.

```sh
sudo touch /path/to/docker-volumes/chhoto/_data/urls.sqlite

# replace 1000:1000 with your puid/pgid and /var/bla to wherever you have docker
sudo chown -R 1000:1000 /var/lib/docker/volumes/chhoto-volume
```

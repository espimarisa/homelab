# OpenCloud

OpenCloud is a fork of OwnCloud Infinite Scale. It does what you think it does.

Before starting OpenCloud, you need to take ownership of the config volume properly.

```sh
# replace 1000:1000 with your puid/pgid and /var/bla to wherever you have docker
sudo chown -R 1000:1000 /var/lib/docker/volumes/opencloud-config-volume
```

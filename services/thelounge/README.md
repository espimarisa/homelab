# The Lounge

The Lounge is a web-based IRC client. I primarily use it to keep up with private trackers.

Before using The Lounge, you will need to take ownership of the volume, and then create a user.

```sh
# replace 1000:1000 with your puid/pgid and /var/bla to wherever you have docker
sudo chown -R 1000:1000 /var/lib/docker/volumes/thelounge-volume

# after doing so, start thelounge
# be sure thelounge is running! docker compose up -d thelounge
docker exec -it thelounge thelounge add exampleUsername
```

The Lounge will then prompt for a password to set, and whether or not to save log files to the disk. I personally do not.

## Useful commands

```sh
# remove a user
docker exec -it thelounge thelounge remove exampleUsername

# reset a user's password
docker exec -it thelounge thelounge reset exampleUsername

# edit a user's configuration file directly
docker exec -it thelounge thelounge edit exampleUsername
```

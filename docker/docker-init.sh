#!/bin/bash

DOWNLOADS_DIRECTORIES=(
	"readarr"
	"deezer"
	"soulseek"
	"torrents"
)

MEDIA_LIBRARY_DIRECTORIES=(
	"anime"
	"audiobooks"
	"books"
	"comics"
	"manga"
	"movies"
	"music"
	"tv-shows"
)

TORRENTS_DIRECTORIES=(
	".incomplete"
	".torrent-files"
	"readarr"
	"lidarr"
	"radarr"
	"sonarr"
)

VOLUMES=(
	"beszel-agent-volume"
	"beszel-data-volume"
	"beszel-socket-volume"
	"readarr-db-backups-volume"
	"readarr-db-config-volume"
	"readarr-db-data-volume"
	"readarr-volume"
	"caddy-backups-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"chhoto-volume"
	"dozzle-volume"
	"gatus-db-backups-volume"
	"gatus-db-config-volume"
	"gatus-db-data-volume"
	"gluetun-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"lidarr-db-backups-volume"
	"lidarr-db-config-volume"
	"lidarr-db-data-volume"
	"lidarr-volume"
	"opencloud-config-volume"
	"profilarr-volume"
	"prowlarr-volume"
	"qbittorrent-config-volume"
	"qbittorrent-data-volume"
	"radarr-db-backups-volume"
	"radarr-db-config-volume"
	"radarr-db-data-volume"
	"radarr-volume"
	"slskd-volume"
	"socket-proxy-volume"
	"sonarr-db-backups-volume"
	"sonarr-db-config-volume"
	"sonarr-db-data-volume"
	"sonarr-volume"
	"thelounge-volume"
	"vaultwarden-db-backups-volume"
	"vaultwarden-db-config-volume"
	"vaultwarden-db-data-volume"
	"vaultwarden-volume"
)

CHOWN_VOLUMES=(
	"chhoto-volume"
	"opencloud-config-volume"
	"thelounge-volume"
	"vaultwarden-volume"
)

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
	echo "Using sudo for privileged commands."
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"

if [ -f "$ENV_FILE" ]; then
	echo "Sourced environment variables from ${ENV_FILE}."
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
else
	echo "Error: ${ENV_FILE} not found."
	exit 1
fi

for directory in "${DOWNLOADS_DIRECTORIES[@]}"; do
	mkdir -p "$DOWNLOADS_PATH/$directory"
done

for directory in "${TORRENTS_DIRECTORIES[@]}"; do
	mkdir -p "$DOWNLOADS_PATH/torrents/$directory"
done

for directory in "${MEDIA_LIBRARY_DIRECTORIES[@]}"; do
	mkdir -p "$MEDIA_LIBRARY_PATH/$directory"
done

mkdir -p "${APPDATA_PATH}"/opencloud

docker network create --driver=bridge --subnet=172.19.0.0/16 --gateway=172.19.0.1 "gluetun-network"
docker network create --driver=bridge --internal "socket-proxy-network"
docker network create --driver=bridge --internal "internal-only-network"
docker network create --driver=bridge "caddy-network"

for volume in "${VOLUMES[@]}"; do
	docker volume create "$volume"
done

# initialize chhoto
$SUDO touch "/var/lib/docker/volumes/chhoto-volume/_data/urls.sqlite"

# todo: i need to dynamically get the configured docker volume path
# i could use an env var but tbh i'm just gonna hardcode it.
# fuck it, we ball. bitch.
for volume in "${CHOWN_VOLUMES[@]}"; do
	$SUDO chown -R "${PUID}:${PGID}" "/var/lib/docker/volumes/$volume"
done

$SUDO chown -R "${PUID}:${PGID}" \
	"${APPDATA_PATH}" \
	"${DOWNLOADS_PATH}" \
	"${MEDIA_LIBRARY_PATH}"

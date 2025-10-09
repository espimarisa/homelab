#!/bin/bash

# List of downloads directories to create.
DOWNLOADS_DIRECTORIES=("deezer" "bookshelf" "soulseek" "torrents")
TORRENTS_DIRECTORIES=(
	".incomplete"
	".torrent-files"
	"bookshelf"
	"lidarr"
	"radarr"
	"sonarr"
)

# List of media library directories to create.
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

# List of volumes to create.
VOLUMES=(
	"beszel-agent-volume"
	"beszel-data-volume"
	"beszel-socket-volume"
	"bookshelf-volume"
	"caddy-backup-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"dozzle-volume"
	"gatus-db-volume"
	"gluetun-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"lidarr-volume"
	"profilarr-volume"
	"prowlarr-volume"
	"qbittorrent-config-volume"
	"qbittorrent-data-volume"
	"radarr-volume"
	"slskd-volume"
	"socket-proxy-volume"
	"sonarr-volume"
)

# Run privileged commands with sudo if not root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
	echo "Using sudo for privileged commands."
fi

# Gets environment variables from .env file.
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

# Verify that all required environment variables are set.
REQUIRED_VARS=(
	"APPDATA_PATH"
	"DOWNLOADS_PATH"
	"MEDIA_LIBRARY_PATH"
	"STORAGE_PATH"
)

for var in "${REQUIRED_VARS[@]}"; do
	if [ -z "${!var}" ]; then
		echo "Error: Required environment variable ${var} is not set in .env file." >&2
		exit 1
	fi
done

# Creates downloads directory structure.
echo "Creating downloads structure..."
for directory in "${DOWNLOADS_DIRECTORIES[@]}"; do
	mkdir -p "$DOWNLOADS_PATH/$directory"
done
mkdir -p "$DOWNLOADS_PATH/soulseek/.incomplete"

# Creates torrents subdirectory structure.
echo "Creating torrents structure..."
for directory in "${TORRENTS_DIRECTORIES[@]}"; do
	mkdir -p "$DOWNLOADS_PATH/torrents/$directory"
done

# Creates media library structure.
echo "Creating media library structure..."
for directory in "${MEDIA_LIBRARY_DIRECTORIES[@]}"; do
	mkdir -p "$MEDIA_LIBRARY_PATH/$directory"
done

# Creates application data structure.
echo "Creating application data structure..."
mkdir -p "${APPDATA_PATH}"/{chhoto,opencloud,thelounge,vaultwarden}
mkdir -p "${APPDATA_PATH}"/opencloud/{config,data}

# Docker network setup.
docker network create --driver=bridge --subnet=172.19.0.0/16 --gateway=172.19.0.1 "gluetun-network" || true
echo "Creating Docker networks..."
docker network create --internal "socket-proxy-network" || true
docker network create "caddy-network" || true

# Docker volume setup.
echo "Creating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
	docker volume create "$volume" || true
done

# Sets ownership for all created data directories.
echo "Setting ownership..."
$SUDO chown -R "${PUID}:${PGID}" \
	"${APPDATA_PATH}" \
	"${DOWNLOADS_PATH}" \
	"${MEDIA_LIBRARY_PATH}"

echo "Initial setup complete."

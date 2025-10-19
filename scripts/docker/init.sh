#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# Appdata directories to create.
readonly APPDATA_DIRECTORIES=(
	"opencloud"
)

# Download directories to create.
readonly DOWNLOADS_DIRECTORIES=(
	".torrent-files"
	"deezer"
	"lidarr"
	"prowlarr"
	"radarr"
	"sonarr"
	"soulseek"
	"torrents"
	"uncategorized"
)

# Incomplete download directories to create.
readonly DOWNLOADS_CACHE_DIRECTORIES=(
	"soulseek"
	"torrents"
)

# Media library directories to create.
readonly MEDIA_LIBRARY_DIRECTORIES=(
	"anime"
	"audiobooks"
	"books"
	"comics"
	"manga"
	"movies"
	"music"
	"tv-shows"
)

# Docker volumes to create.
readonly VOLUMES=(
	"bazarr-db-backups-volume"
	"bazarr-db-config-volume"
	"bazarr-db-data-volume"
	"bazarr-volume"
	"beszel-agent-volume"
	"beszel-data-volume"
	"beszel-socket-volume"
	"caddy-backups-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"caddy-logs-volume"
	"chhoto-volume"
	"cleanuparr-volume"
	"gatus-db-backups-volume"
	"gatus-db-config-volume"
	"gatus-db-data-volume"
	"gluetun-volume"
	"homarr-db-backups-volume"
	"homarr-db-config-volume"
	"homarr-db-data-volume"
	"homarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"lidarr-db-backups-volume"
	"lidarr-db-config-volume"
	"lidarr-db-data-volume"
	"lidarr-volume"
	"navidrome-backups-volume"
	"navidrome-cache-volume"
	"navidrome-data-volume"
	"opencloud-config-volume"
	"profilarr-volume"
	"prowlarr-db-backups-volume"
	"prowlarr-db-config-volume"
	"prowlarr-db-data-volume"
	"prowlarr-volume"
	"qbittorrent-config-volume"
	"qbittorrent-data-volume"
	"qui-config-volume"
	"qui-logs-volume"
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

# Docker volumes to take ownership of.
readonly CHOWN_VOLUMES=(
	"caddy-logs-volume"
	"chhoto-volume"
	"homarr-volume"
	"navidrome-backups-volume"
	"navidrome-cache-volume"
	"navidrome-data-volume"
	"opencloud-config-volume"
	"thelounge-volume"
	"vaultwarden-volume"
)

# Function to ensure a directory exists.
create_dirs() {
	local base_path="$1"
	shift
	local -a dirs=("$@")
	for dir in "${dirs[@]}"; do
		echo "Ensuring directory exists: ${base_path}/${dir}"
		mkdir -p "${base_path}/${dir}"
	done
}

# Function to create a Docker network if it doesn't exist.
create_network() {
	local network_name="$1"
	shift
	if ! docker network inspect "$network_name" &>/dev/null; then
		echo "Creating Docker network: $network_name"
		docker network create "$@" "$network_name"
	else
		echo "Docker network '$network_name' already exists."
	fi
}

# Function to create a Docker volume if it doesn't exist.
create_volume() {
	local volume_name="$1"
	if ! docker volume inspect "$volume_name" &>/dev/null; then
		echo "Creating Docker volume: $volume_name"
		docker volume create "$volume_name" >/dev/null
	else
		echo "Docker volume '$volume_name' already exists."
	fi
}

# Use sudo for privileged commands if not running as root.
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
	echo "Script not run as root. Using 'sudo' for privileged commands."
fi

# Source environment variables from .env file.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"
if [ -f "$ENV_FILE" ]; then
	echo "Sourcing environment variables from ${ENV_FILE}."
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
else
	echo "Error: Environment file not found at ${ENV_FILE}." >&2
	exit 1
fi

# Validate that required environment variables are set.
readonly REQUIRED_VARS=("APPDATA_PATH" "DOWNLOADS_PATH" "DOWNLOADS_CACHE_PATH" "MEDIA_LIBRARY_PATH" "PUID" "PGID")
for var in "${REQUIRED_VARS[@]}"; do
	if [ -z "${!var-}" ]; then
		echo "Error: Required environment variable '$var' is not set in ${ENV_FILE}." >&2
		exit 1
	fi
done

# Create bind mount directories on the host.
echo -e "\nCreating bind mount directories..."
create_dirs "$APPDATA_PATH" "${APPDATA_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_PATH" "${DOWNLOADS_DIRECTORIES[@]}"
create_dirs "$MEDIA_LIBRARY_PATH" "${MEDIA_LIBRARY_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_CACHE_PATH" "${DOWNLOADS_CACHE_DIRECTORIES[@]}"

# Create Docker networks.
echo -e "\nCreating Docker networks..."
create_network "caddy-network" --driver=bridge
create_network "gluetun-network" --driver=bridge --subnet=172.19.0.0/16 --gateway=172.19.0.1
create_network "internal-only-network" --driver=bridge --internal
create_network "socket-proxy-network" --driver=bridge --internal

# Create Docker volumes.
echo -e "\nCreating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
	create_volume "$volume"
done

# Initialize files in volumes using a temporary container.
echo -e "\nInitializing files in volumes..."
docker run --rm \
	-v "chhoto-volume:/data" \
	alpine:3.22.2 \
	touch /data/urls.sqlite

docker run --rm \
	-v "homarr-volume:/data" \
	alpine:3.22.2 \
	mkdir /data/redis

# Set ownership of volumes using a temporary container.
echo -e "\nSetting volume permissions ---"
for volume in "${CHOWN_VOLUMES[@]}"; do
	echo "Setting ownership for volume: '$volume' to ${PUID}:${PGID}"
	docker run --rm \
		-v "$volume:/data" \
		alpine:3.22.2 \
		chown -R "${PUID}:${PGID}" /data
done

# Set ownership of the main bind mount directories on the host.
echo -e "\nSetting bind mount permissions..."
echo "Setting ownership for host directories..."
$SUDO chown -R "${PUID}:${PGID}" \
	"${APPDATA_PATH}" \
	"${DOWNLOADS_PATH}" \
	"${DOWNLOADS_CACHE_PATH}" \
	"${MEDIA_LIBRARY_PATH}"

echo -e "\nInitial setup complete!"

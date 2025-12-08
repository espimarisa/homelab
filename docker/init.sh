#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# List of required environment variables.
readonly REQUIRED_VARS=(
	"DOWNLOADS_INCOMPLETE_PATH"
	"DOWNLOADS_PATH"
	"MEDIA_LIBRARY_PATH"
	"OPENCLOUD_DATA_PATH"
	"PGID"
	"PUID"
	"STORAGE_PATH"
	"TZ"
	"UMASK"
)

# Sources environment variables from .env.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
SUDO=""

# Reads the environment variable file.
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

# Validates required environment variables.
for var in "${REQUIRED_VARS[@]}"; do
	if [ -z "${!var-}" ]; then
		echo "Error: Required environment variable '$var' is not set." >&2
		exit 1
	fi
done

# Use sudo for privileged commands if not running as root.
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
	echo "Script not run as root. Using 'sudo' for privileged commands."
fi

# Download directories to create.
readonly DOWNLOADS_DIRECTORIES=(
	"deezer"
	"soulseek"
	"torrents/.torrent-files"
	"torrents/lidarr"
	"torrents/permaseed"
	"torrents/radarr"
	"torrents/readarr"
	"torrents/sonarr"
	"torrents/uncategorized"
)

# Incomplete download directories to create.
readonly DOWNLOADS_INCOMPLETE_DIRECTORIES=(
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
	"backrest-cache-volume"
	"backrest-config-volume"
	"backrest-data-volume"
	"backrest-tmp-volume"
	"beszel-agent-volume"
	"beszel-data-volume"
	"beszel-socket-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"chhoto-volume"
	"configarr-volume"
	"dozzle-volume"
	"gatus-db-config-volume"
	"gatus-db-data-volume"
	"gluetun-volume"
	"homarr-db-config-volume"
	"homarr-db-data-volume"
	"homarr-volume"
	"huntarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"kavita-volume"
	"lidarr-db-config-volume"
	"lidarr-db-data-volume"
	"lidarr-volume"
	"navidrome-volume"
	"opencloud-config-volume"
	"prowlarr-db-config-volume"
	"prowlarr-db-data-volume"
	"prowlarr-volume"
	"qbittorrent-config-volume"
	"qbittorrent-data-volume"
	"radarr-db-config-volume"
	"radarr-db-data-volume"
	"radarr-volume"
	"slskd-volume"
	"sonarr-db-config-volume"
	"sonarr-db-data-volume"
	"sonarr-volume"
	"thelounge-volume"
	"unpackerr-volume"
	"vaultwarden-db-backups-volume"
	"vaultwarden-db-config-volume"
	"vaultwarden-db-data-volume"
	"vaultwarden-volume"
)

# Docker volumes to take ownership of.
readonly CHOWN_VOLUMES=(
	"beszel-agent-volume"
	"beszel-data-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"chhoto-volume"
	"configarr-volume"
	"dozzle-volume"
	"homarr-volume"
	"huntarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"navidrome-volume"
	"opencloud-config-volume"
	"slskd-volume"
	"thelounge-volume"
	"unpackerr-volume"
	"vaultwarden-volume"
)

# Function to create a directory.
create_dirs() {
	local base_path="$1"
	shift
	local -a dirs=("$@")
	for dir in "${dirs[@]}"; do
		echo "Ensuring directory exists: ${base_path}/${dir}"
		mkdir -p "${base_path}/${dir}"
	done
}

# Function to create a Docker volume.
create_volume() {
	local volume_name="$1"
	if ! docker volume inspect "$volume_name" &>/dev/null; then
		echo "Creating Docker volume: $volume_name"
		docker volume create "$volume_name" >/dev/null
	else
		echo "Docker volume '$volume_name' already exists."
	fi
}

# Function to create a Docker network.
create_network() {
	local network_name="$1"
	local ipv4_gateway="$2"
	local ipv4_subnet="$3"

	if ! docker network inspect "$network_name" &>/dev/null; then
		echo "Creating Docker network: $network_name"
		docker network create --gateway="$ipv4_gateway" --subnet="$ipv4_subnet" "$network_name"
	else
		echo "Docker network '$network_name' already exists."
	fi
}

# Create bind mount directories on the host.
echo -e "\nCreating bind mount directories..."
create_dirs "$DOWNLOADS_INCOMPLETE_PATH" "${DOWNLOADS_INCOMPLETE_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_PATH" "${DOWNLOADS_DIRECTORIES[@]}"
create_dirs "$MEDIA_LIBRARY_PATH" "${MEDIA_LIBRARY_DIRECTORIES[@]}"

# Create Docker networks.
echo -e "\nCreating Docker networks..."
create_network "external-network" "172.18.0.1" "172.18.0.0/16"
create_network "gluetun-network" "172.19.0.1" "172.19.0.0/16"

# Creates the private internal network.
if ! docker network inspect "internal-network" &>/dev/null; then
	echo "Creating Docker network: internal-network"
	docker network create --gateway 172.20.0.1 --subnet "172.20.0.0/16" internal-network
fi

# Create Docker volumes.
echo -e "\nCreating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
	create_volume "$volume"
done

# Create required application structure for specific apps.
CHHOTO_DATA_PATH="${DOCKER_VOLUMES_PATH}/chhoto-volume/_data"
HOMARR_DATA_PATH="${DOCKER_VOLUMES_PATH}/homarr-volume/_data"
$SUDO mkdir -p "${OPENCLOUD_DATA_PATH}"
$SUDO mkdir -p "${HOMARR_DATA_PATH}/redis"
$SUDO touch "${CHHOTO_DATA_PATH}/urls.sqlite"

# Set ownership of volumes by chowning their _data directory on the host.
echo -e "\nSetting volume permissions..."
for volume in "${CHOWN_VOLUMES[@]}"; do
	VOLUME_DATA_PATH="${DOCKER_VOLUMES_PATH}/${volume}/_data"
	if $SUDO [ -d "$VOLUME_DATA_PATH" ]; then
		echo "Setting ownership for volume: '$volume' to ${PUID}:${PGID}"
		$SUDO chown -R "${PUID}:${PGID}" "$VOLUME_DATA_PATH"
	else
		echo "Warning: Could not find data directory for volume '$volume' at $VOLUME_DATA_PATH"
	fi
done

# Sets ownership of the main bind mount directories on the host.
echo -e "\nSetting bind mount permissions..."
echo "Setting ownership for host directories..."
$SUDO chown -R "${PUID}:${PGID}" \
	"${DOWNLOADS_PATH}" \
	"${DOWNLOADS_INCOMPLETE_PATH}" \
	"${MEDIA_LIBRARY_PATH}" \
	"${OPENCLOUD_DATA_PATH}"

# Set permissions of the main bind mount directories on the host.
echo "Setting permissions for host directories..."
$SUDO chmod -R 775 \
	"${DOWNLOADS_PATH}" \
	"${DOWNLOADS_INCOMPLETE_PATH}" \
	"${MEDIA_LIBRARY_PATH}" \
	"${OPENCLOUD_DATA_PATH}"

echo -e "\nInitial setup complete!"

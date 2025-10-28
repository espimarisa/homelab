#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# ULA Base: fdad:21b2:bca9::/48

# Internal (Subnet #1): Used for isolated services (DBs, Socket Proxy).
readonly INTERNAL_IPV4_SUBNET="172.19.2.0/24"
readonly INTERNAL_IPV4_GATEWAY="172.19.2.1"
readonly INTERNAL_IPV6_SUBNET="fdad:21b2:bca9:1::/64"
readonly INTERNAL_IPV6_GATEWAY="fdad:21b2:bca9:1::1"

# External (Subnet #2): Used for Caddy/general external access.
readonly EXTERNAL_IPV4_SUBNET="172.19.1.0/24"
readonly EXTERNAL_IPV4_GATEWAY="172.19.1.1"
readonly EXTERNAL_IPV6_SUBNET="fdad:21b2:bca9:2::/64"
readonly EXTERNAL_IPV6_GATEWAY="fdad:21b2:bca9:2::1"

# Gluetun (Subnet #3): Used for VPN-routed apps.
readonly GLUETUN_IPV4_SUBNET="172.19.3.0/24"
readonly GLUETUN_IPV4_GATEWAY="172.19.3.1"
readonly GLUETUN_IPV6_SUBNET="fdad:21b2:bca9:3::/64"
readonly GLUETUN_IPV6_GATEWAY="fdad:21b2:bca9:3::1"

# Appdata directories to create.
readonly APPDATA_DIRECTORIES=(
	"opencloud"
	"piwigo"
)

# Download directories to create.
readonly DOWNLOADS_DIRECTORIES=(
	".torrent-files"
	"deezer"
	"soulseek"
	"torrents/sonarr"
	"torrents/radarr"
	"torrents/lidarr"
	"torrents/prowlarr"
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
	"autobrr-db-backups-volume"
	"autobrr-db-config-volume"
	"autobrr-db-data-volume"
	"autobrr-logs-volume"
	"autobrr-volume"
	"backrest-cache-volume"
	"backrest-config-volume"
	"backrest-data-volume"
	"backrest-tmp-volume"
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
	"dozzle-volume"
	"gatus-db-backups-volume"
	"gatus-db-config-volume"
	"gatus-db-data-volume"
	"gluetun-volume"
	"homarr-db-backups-volume"
	"homarr-db-config-volume"
	"homarr-db-data-volume"
	"homarr-volume"
	"huntarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"lidarr-db-backups-volume"
	"lidarr-db-config-volume"
	"lidarr-db-data-volume"
	"lidarr-volume"
	"opencloud-config-volume"
	"piwigo-db-volume"
	"piwigo-volume"
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
	"seerr-db-backups-volume"
	"seerr-db-config-volume"
	"seerr-db-data-volume"
	"seerr-volume"
	"slskd-volume"
	"socket-proxy-volume"
	"sonarr-db-backups-volume"
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
	"autobrr-logs-volume"
	"autobrr-volume"
	"beszel-agent-volume"
	"beszel-data-volume"
	"caddy-backups-volume"
	"caddy-config-volume"
	"caddy-data-volume"
	"caddy-logs-volume"
	"chhoto-volume"
	"dozzle-volume"
	"homarr-volume"
	"huntarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"opencloud-config-volume"
	"qui-config-volume"
	"qui-logs-volume"
	"seerr-volume"
	"slskd-volume"
	"thelounge-volume"
	"unpackerr-volume"
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

# Function to create a dual-stack bridge networks.
create_dual_stack_network() {
	local network_name="$1"
	local ipv4_subnet="$2"
	local ipv4_gateway="$3"
	local ipv6_subnet="$4"
	local ipv6_gateway="$5"
	local internal_flag="$6"

	if ! docker network inspect "$network_name" &>/dev/null; then
		echo "Creating dual-stack network: $network_name (IPv6: $ipv6_subnet, Internal: $internal_flag)"

		local command="docker network create --driver=bridge --ipv6 "

		# The internal network requires the internal flag and gateway defined for static IPs
		if [ "$internal_flag" = "true" ]; then
			command+="--internal "
		fi

		# We specify subnet and gateway for all, even internal, to ensure static IPs work
		command+="--subnet=${ipv4_subnet} --gateway=${ipv4_gateway} --subnet=${ipv6_subnet} --gateway=${ipv6_gateway} "

		# Append network name and execute
		eval "$command" "$network_name"

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
ENV_FILE="${SCRIPT_DIR}/../.env"
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

# 1. EXTERNAL (Routable for Internet/Caddy)
create_dual_stack_network "external-network" \
	"$EXTERNAL_IPV4_SUBNET" "$EXTERNAL_IPV4_GATEWAY" \
	"$EXTERNAL_IPV6_SUBNET" "$EXTERNAL_IPV6_GATEWAY" "false"

# 2. INTERNAL (Isolated for internal-only traffic).
create_dual_stack_network "internal-network" \
	"$INTERNAL_IPV4_SUBNET" "$INTERNAL_IPV4_GATEWAY" \
	"$INTERNAL_IPV6_SUBNET" "$INTERNAL_IPV6_GATEWAY" "true"

# 3. GLUETUN (VPN)
create_dual_stack_network "gluetun-network" \
	"$GLUETUN_IPV4_SUBNET" "$GLUETUN_IPV4_GATEWAY" \
	"$GLUETUN_IPV6_SUBNET" "$GLUETUN_IPV6_GATEWAY" "false"

# Create Docker volumes.
echo -e "\nCreating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
	create_volume "$volume"
done

# Initialize files in volumes using a temporary container.
echo -e "\nInitializing files in volumes..."
docker run --rm -v "chhoto-volume:/data" alpine:3 touch /data/urls.sqlite
docker run --rm -v "homarr-volume:/data" alpine:3 mkdir /data/redis

# Get Docker's root directory
DOCKER_ROOT=$($SUDO docker info -f '{{ .DockerRootDir }}')
if [ -z "$DOCKER_ROOT" ]; then
	echo "Error: Could not determine Docker root directory." >&2
	exit 1
fi

# Set ownership of volumes by chowning their _data directory on the host
VOLUMES_PATH="${DOCKER_ROOT}/volumes"
echo -e "\nSetting volume permissions..."
for volume in "${CHOWN_VOLUMES[@]}"; do
	VOLUME_DATA_PATH="${VOLUMES_PATH}/${volume}/_data"
	if $SUDO [ -d "$VOLUME_DATA_PATH" ]; then
		echo "Setting ownership for volume: '$volume' to ${PUID}:${PGID}"
		$SUDO chown -R "${PUID}:${PGID}" "$VOLUME_DATA_PATH"
	else
		echo "Warning: Could not find data directory for volume '$volume' at $VOLUME_DATA_PATH"
	fi
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

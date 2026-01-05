#!/bin/bash

# This script prepares (or updates) a system environment for this infrastructure.
# It parses environment variables and creates required volumes, networks, and paths.
# It also *should* take ownership of things that require PUID/PGID matches.
# This is not a great way to do it, but it works fine for my case.
# chmod +x this script and run it with bash.

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# List of required environment variables.
readonly REQUIRED_VARS=(
	"CHHOTO_DATA_PATH"
    "DOCKER_VOLUMES_PATH"
    "DOWNLOADS_INCOMPLETE_PATH"
    "DOWNLOADS_PATH"
    "DOWNLOADS_PERMASEED_PATH"
    "IMMICH_DATA_PATH"
    "IPV6_ENABLED"
    "IPV6_ULA_BASE"
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
# This will result in the following structure, for example:
# /storage/downloads/torrents/<bla>arr
readonly DOWNLOADS_DIRECTORIES=(
    "deezer"
    "soulseek"
    "torrents/.torrent-files"
    "torrents/autobrr"
    "torrents/lidarr"
    "torrents/permaseed"
    "torrents/radarr"
    "torrents/sonarr"
    "torrents/uncategorized"
)

# Incomplete download directories to create.
# These are used to store incomplete downloads from qBittorrent/soulseek.
# It's generally a good idea for DOWNLOADS_INCOMPLETE_PATH to be a feeder SSD.
# This will result in the following structure, for example, if it's mounted...
# /downloads-incomplete/torrents/<your-qbittorrent-category-setup>
readonly DOWNLOADS_INCOMPLETE_DIRECTORIES=(
    "soulseek"
    "torrents"
)

# Media library directories to create.
# These store, well, your media library structure.
# It's a good idea to keep these on their own zfs pool if you use zfs.
# Additionally, messing with these probably isn't a great idea.
# This will result in the following structure, if /storage is the base:
# /storage/media-library/<anime,tv,etc>

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
# I end all named volumes in -volume for clarity.
# If a volume already exists, it will be skipped.
# This is the same thing as just running docker volume create example-volume,
# but it's useful to have as I can  update the list and run it when adding an app.

readonly VOLUMES=(
    "autobrr-volume"
    "autobrr-db-config-volume"
    "autobrr-db-data-volume"
    "beszel-agent-volume"
    "beszel-data-volume"
    "beszel-socket-volume"
    "caddy-volume"
    "chhoto-volume"
    "configarr-volume"
    "dozzle-volume"
    "gatus-db-config-volume"
    "gatus-db-data-volume"
    "gluetun-volume"
    "huntarr-volume"
    "immich-cache-config-volume"
    "immich-cache-data-volume"
    "immich-db-volume"
    "jellyfin-cache-volume"
    "jellyfin-config-volume"
    "kavita-volume"
    "lidarr-db-config-volume"
    "lidarr-db-data-volume"
    "lidarr-volume"
    "navidrome-cache-volume"
    "navidrome-data-volume"
    "opencloud-config-volume"
    "prowlarr-db-config-volume"
    "prowlarr-db-data-volume"
    "prowlarr-volume"
    "qbittorrent-config-volume"
    "qbittorrent-data-volume"
    "qui-volume"
    "radarr-db-config-volume"
    "radarr-db-data-volume"
    "radarr-volume"
    "slskd-volume"
    "sonarr-db-config-volume"
    "sonarr-db-data-volume"
    "sonarr-volume"
    "thelounge-volume"
    "vaultwarden-db-backups-volume"
    "vaultwarden-db-config-volume"
    "vaultwarden-db-data-volume"
    "vaultwarden-volume"
)

# Docker volumes to take PUID/PGID ownership of.
# This is a list of volumes that require explicit ID ownership.
# Containers that run rootless and do *not* use s6 or drop down may need this.
# NOTE: Many containers use their own internal IDs, such as Redis.
# Additionally, 11notes images don't need this as they run as 1000:1000 internally.

readonly CHOWN_VOLUMES=(
    "autobrr-volume"
    "beszel-agent-volume"
    "beszel-data-volume"
    "chhoto-volume"
    "configarr-volume"
    "dozzle-volume"
    "huntarr-volume"
    "jellyfin-cache-volume"
    "jellyfin-config-volume"
    "navidrome-cache-volume"
    "navidrome-data-volume"
    "kavita-volume"
    "opencloud-config-volume"
    "qui-volume"
    "slskd-volume"
    "thelounge-volume"
    "vaultwarden-volume"
)

# Files to touch (create empty if they don't exist).
# This is useful for databases (sqlite) or log files that must exist
# before the container starts to prevent directory-creation errors.

readonly TOUCH_FILES=(
    "${CHHOTO_DATA_PATH}/urls.sqlite"
)

# Function to create a directory.
create_dirs() {
    local base_path="$1"
    shift
    local -a dirs=("$@")
    for dir in "${dirs[@]}"; do
        echo "Ensuring directory exists: ${base_path}/${dir}"
        $SUDO mkdir -p "${base_path}/${dir}"
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

# Unified Function to create a Docker network.
# Usage: create_network <name> <ipv4_gw> <ipv4_sub> <ipv6_gw> <ipv6_sub> [internal]
create_network() {
    local network_name="$1"
    local ipv4_gateway="$2"
    local ipv4_subnet="$3"
    local ipv6_gateway="$4"
    local ipv6_subnet="$5"
    local internal_flag="${6:-false}" # Default to false if not provided

    local network_args=("--gateway=$ipv4_gateway" "--subnet=$ipv4_subnet")

    # Handle Internal Flag
    if [[ "$internal_flag" == "internal" || "$internal_flag" == "true" ]]; then
        network_args+=("--internal")
    fi

    # Handle IPv6
    if [[ "${IPV6_ENABLED}" == "true" ]]; then
        network_args+=("--ipv6" "--gateway=$ipv6_gateway" "--subnet=$ipv6_subnet")
    fi

    if ! docker network inspect "$network_name" &>/dev/null; then
        echo "Creating Docker network: $network_name (Internal: $internal_flag, IPv6: ${IPV6_ENABLED})"
        docker network create "${network_args[@]}" "$network_name"
    else
        echo "Docker network '$network_name' already exists."
    fi
}

# Creates bind mount directories on the host.
echo -e "\nCreating bind mount directories..."
create_dirs "$DOWNLOADS_INCOMPLETE_PATH" "${DOWNLOADS_INCOMPLETE_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_PATH" "${DOWNLOADS_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_PERMASEED_PATH"
create_dirs "$MEDIA_LIBRARY_PATH" "${MEDIA_LIBRARY_DIRECTORIES[@]}"

# Creates Docker networks.
echo -e "\nCreating Docker networks..."

# We construct the IPv6 subnets based on the ULA base provided in .env
# Example Base: fd00:dead:beef
# Net 1: fd00:dead:beef:1::/64
create_network "external-network" \
    "172.18.0.1" "172.18.0.0/16" \
    "${IPV6_ULA_BASE}:1::1" "${IPV6_ULA_BASE}:1::/64"

create_network "gluetun-network" \
    "172.19.0.1" "172.19.0.0/16" \
    "${IPV6_ULA_BASE}:2::1" "${IPV6_ULA_BASE}:2::/64"

create_network "internal-network" \
    "172.20.0.1" "172.20.0.0/16" \
    "${IPV6_ULA_BASE}:3::1" "${IPV6_ULA_BASE}:3::/64" \
    "internal"

# Creates Docker volumes.
echo -e "\nCreating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
    create_volume "$volume"
done

# Creates specific application data directories.
# These are manual overrides for things not covered by standard volume logic.

echo -e "\nCreating specific application paths..."
$SUDO mkdir -p "${IMMICH_DATA_PATH}"
$SUDO mkdir -p "${OPENCLOUD_DATA_PATH}"

# Touch specific files that need to exist.
echo -e "\nTouching required files..."
for file_path in "${TOUCH_FILES[@]}"; do
    dir_path=$(dirname "$file_path")
    # Ensure the parent directory exists.
    if [ ! -d "$dir_path" ]; then
        echo "Creating parent directory: $dir_path"
        $SUDO mkdir -p "$dir_path"
    fi

    if [ ! -f "$file_path" ]; then
        echo "Creating file: $file_path"
        $SUDO touch "$file_path"
    fi
done

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
# This may take a while if you're running it on a large, fresh media library.
# You will want to be careful with this if you have sensitive permissions.
# This **WILL** use PUID/PGID - note if you use user 1001 for example and not 1000.

echo -e "\nSetting bind mount permissions..."
echo "Setting ownership for host directories..."
$SUDO chown -R "${PUID}:${PGID}" \
    "${DOWNLOADS_PATH}" \
    "${DOWNLOADS_PERMASEED_PATH}" \
    "${DOWNLOADS_INCOMPLETE_PATH}" \
    "${IMMICH_DATA_PATH}" \
    "${MEDIA_LIBRARY_PATH}" \
    "${OPENCLOUD_DATA_PATH}"

# Set permissions of the main bind mount directories on the host.
# Be careful adding something here as it could break an app expecting lower perms.

echo "Setting permissions for host directories..."
$SUDO chmod -R 775 \
    "${DOWNLOADS_PATH}" \
    "${DOWNLOADS_INCOMPLETE_PATH}" \
    "${IMMICH_DATA_PATH}" \
    "${MEDIA_LIBRARY_PATH}" \
    "${OPENCLOUD_DATA_PATH}"

echo -e "\nInitial setup complete!"


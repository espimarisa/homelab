#!/bin/bash

# This script prepares (or updates) a system environment for this infrastructure.
# It parses environment variables and creates required volumes, networks, and paths.
# It uses the Docker CLI to dynamically find volume paths for permission setting.
# chmod +x this script and run it with bash.
# This is stupid, but works fine. - Mari

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# List of required environment variables.
readonly REQUIRED_VARS=(
    "APPDATA_PATH"
    "DOWNLOADS_COMPLETE_PATH"
    "DOWNLOADS_INCOMPLETE_PATH"
    "DOWNLOADS_PERMASEED_PATH"
    "IPV6_ENABLED"
    "IPV6_ULA_BASE"
    "MEDIA_LIBRARY_PATH"
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
# These are now created inside DOWNLOADS_COMPLETE_PATH.
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
# These are created inside DOWNLOADS_INCOMPLETE_PATH.
readonly DOWNLOADS_INCOMPLETE_DIRECTORIES=(
    "soulseek"
    "torrents"
)

# Persistent bulk application data directories to create.
readonly APPDATA_DIRECTORIES=(
    "chhoto"
    "immich"
    "opencloud"
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
    "autobrr-volume"
    "autobrr-db-config-volume"
    "autobrr-db-data-volume"
    "beszel-agent-volume"
    "beszel-data-volume"
    "beszel-socket-volume"
    "caddy-volume"
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
readonly CHOWN_VOLUMES=(
    "autobrr-volume"
    "beszel-agent-volume"
    "beszel-data-volume"
    "configarr-volume"
    "dozzle-volume"
    "huntarr-volume"
    "jellyfin-cache-volume"
    "jellyfin-config-volume"
    "kavita-volume"
    "opencloud-config-volume"
    "qui-volume"
    "slskd-volume"
    "thelounge-volume"
    "vaultwarden-volume"
)

# Files to touch (create empty if they don't exist).
readonly TOUCH_FILES=(
    "${APPDATA_PATH}/chhoto/urls.sqlite"
)

# Function to create directories.
# Ensures the base path exists even if no subdirectories are provided.
create_dirs() {
    local base_path="$1"
    shift
    local -a dirs=("$@")

    echo "Ensuring base directory exists: ${base_path}"
    $SUDO mkdir -p "${base_path}"

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
create_network() {
    local network_name="$1"
    local ipv4_gateway="$2"
    local ipv4_subnet="$3"
    local ipv6_gateway="$4"
    local ipv6_subnet="$5"
    local internal_flag="${6:-false}"

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
create_dirs "$DOWNLOADS_COMPLETE_PATH" "${DOWNLOADS_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_INCOMPLETE_PATH" "${DOWNLOADS_INCOMPLETE_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_PERMASEED_PATH"
create_dirs "$APPDATA_PATH" "${APPDATA_DIRECTORIES[@]}"
create_dirs "$MEDIA_LIBRARY_PATH" "${MEDIA_LIBRARY_DIRECTORIES[@]}"

# Creates Docker networks.
# Will break if you have existing networks, but
# I don't feel like adding an environment variable.
echo -e "\nCreating Docker networks..."

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

# Touch specific files that need to exist.
echo -e "\nTouching required files..."
for file_path in "${TOUCH_FILES[@]}"; do
    dir_path=$(dirname "$file_path")
    if [ ! -d "$dir_path" ]; then
        echo "Creating parent directory: $dir_path"
        $SUDO mkdir -p "$dir_path"
    fi

    if [ ! -f "$file_path" ]; then
        echo "Creating file: $file_path"
        $SUDO touch "$file_path"
    fi
done

# Set ownership of volumes by dynamically inspecting their mount point.
echo -e "\nSetting volume permissions..."
for volume in "${CHOWN_VOLUMES[@]}"; do
    # Dynamically grab the mountpoint from Docker
    VOLUME_MOUNTPOINT=$(docker volume inspect --format '{{ .Mountpoint }}' "$volume" 2>/dev/null || true)

    if [ -z "$VOLUME_MOUNTPOINT" ]; then
        echo "Error: Could not determine mountpoint for volume '$volume'. Skipping."
        continue
    fi

    # Check if the path exists.
    # Use sudo test because the docker root dir (usually /var/lib/docker) is restricted.
    if $SUDO test -d "$VOLUME_MOUNTPOINT"; then
        echo "Setting ownership for volume: '$volume' at '$VOLUME_MOUNTPOINT' to ${PUID}:${PGID}"
        $SUDO chown -R "${PUID}:${PGID}" "$VOLUME_MOUNTPOINT"
    else
        echo "Warning: Volume path '$VOLUME_MOUNTPOINT' does not exist or is not accessible."
    fi
done

# Sets ownership of the main bind mount directories on the host.
echo -e "\nSetting bind mount permissions..."
echo "Setting ownership for host directories..."

$SUDO chown -R "${PUID}:${PGID}" \
    "${APPDATA_PATH}" \
    "${DOWNLOADS_COMPLETE_PATH}" \
    "${DOWNLOADS_INCOMPLETE_PATH}" \
    "${DOWNLOADS_PERMASEED_PATH}" \
    "${MEDIA_LIBRARY_PATH}"

# Set permissions of the main bind mount directories on the host.
echo "Setting permissions for host directories..."
$SUDO chmod -R 775 \
    "${APPDATA_PATH}" \
    "${DOWNLOADS_COMPLETE_PATH}" \
    "${DOWNLOADS_INCOMPLETE_PATH}" \
    "${DOWNLOADS_PERMASEED_PATH}" \
    "${MEDIA_LIBRARY_PATH}"

echo -e "\nInitial setup complete!"

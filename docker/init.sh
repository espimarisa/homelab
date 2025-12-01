#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# Required environment variables.
readonly REQUIRED_VARS=(
	"DOWNLOADS_INCOMPLETE_PATH" # Path to store incomplete downloads. I use a feeder SSD.
	"DOWNLOADS_PATH"            # Path to store downloads.
	"MEDIA_LIBRARY_PATH"        # Path to store the media library.
	"OPENCLOUD_DATA_PATH"			# Path to store OpenCloud data.
	"PGID"                      # Group ID to run as.
	"PUID"                      # User ID to run as.
	"STORAGE_PATH"              # Path to the storage directory.
)

# Source environment variables from .env file.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env"
SUDO=""

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
		echo "Error: Required environment variable '$var' is not set in ${ENV_FILE}." >&2
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
	".logs"                   # Log files.
	"deezer"                  # Deezer downloads.
	"soulseek"                # Soulseek downloads.
	"torrents/.torrent-files" # .torrent file storage.
	"torrents/lidarr"         # Lidarr torrents.
	"torrents/prowlarr"       # Prowlarr torrents.
	"torrents/radarr"         # Radarr torrents.
	"torrents/readarr"        # Readarr torrents.
	"torrents/sonarr"         # Sonarr torrents.
	"torrents/uncategorized"  # Uncategorized torrents.
)

# Incomplete download directories to create.
readonly DOWNLOADS_INCOMPLETE_DIRECTORIES=(
	"soulseek" # Incomplete Soulseek downloads.
	"torrents" # Incomplete torrents downloads.
)

# Media library directories to create.
readonly MEDIA_LIBRARY_DIRECTORIES=(
	"anime"      # Anime library.
	"audiobooks" # Audiobooks library.
	"books"      # Books library.
	"comics"     # Comics library.
	"manga"      # Manga library.
	"movies"     # Movies library.
	"music"      # Music library.
	"tv-shows"   # TV library.
)

# Docker volumes to create.
readonly VOLUMES=(
	"backrest-cache-volume" 		# Backrest cache.
	"backrest-config-volume" 		# Backrest configuration.
	"backrest-data-volume" 			# Backrest data.
	"backrest-tmp-volume" 			# Backrest temporary files.
	"beszel-agent-volume"           # Beszel agent cache.
	"beszel-data-volume"            # Beszel data.
	"beszel-socket-volume"          # Beszel socket cache.
	"caddy-config-volume"           # Caddy configuration.
	"caddy-data-volume"             # Caddy data.
	"chhoto-volume"                 # Chhoto database.
	"configarr-volume"              # Configarr data.
	"dozzle-volume"                 # Dozzle configuration and data.
	"gatus-db-backups-volume"       # Gatus database backups.
	"gatus-db-config-volume"        # Gatus database configuration.
	"gatus-db-data-volume"          # Gatus database data.
	"gluetun-volume"                # Gluetun cache.
	"homarr-db-backups-volume"      # Homarr database backups.
	"homarr-db-config-volume"       # Homarr database configuration.
	"homarr-db-data-volume"         # Homarr database data.
	"homarr-volume"                 # Homarr logs.
	"huntarr-volume"                # Huntarr configuration and data.
	"jellyfin-cache-volume"         # Jellyfin cache.
	"jellyfin-config-volume"        # Jellyfin configuration and data.
	"kavita-volume" 			    # Kavita configuration and data.
	"lidarr-db-backups-volume"      # Lidarr database backups.
	"lidarr-db-config-volume"       # Lidarr database configuration.
	"lidarr-db-data-volume"         # Lidarr database data.
	"lidarr-volume"                 # Lidarr configuration and data.
	"navidrome-backups-volume" 		# Navidrome backups.
	"navidrome-cache-volume" 		# Navidrome Cache.
	"navidrome-data-volume"         # Navidrome configuration and data.
	"opencloud-config-volume"       # OpenCloud configuration.
	"prowlarr-db-backups-volume"    # Prowlarr database backups.
	"prowlarr-db-config-volume"     # Prowlarr database configuration.
	"prowlarr-db-data-volume"       # Prowlarr database data.
	"prowlarr-volume"               # Prowlarr configuration and data.
	"qbittorrent-config-volume"     # qBittorrent configuration.
	"qbittorrent-data-volume"       # qBittorrent data.
	"radarr-db-backups-volume"      # Radarr database backups.
	"radarr-db-config-volume"       # Radarr database configuration.
	"radarr-db-data-volume"         # Radarr database data.
	"radarr-volume"                 # Radarr configuration and data.
	"readarr-db-backups-volume"     # Readarr database backups.
	"readarr-db-config-volume"      # Readarr database configuration.
	"readarr-db-data-volume"        # Readarr database data.
	"readarr-volume"                # Readarr configuration and data.
	"slskd-volume"                  # slskd configuration and data.
	"sonarr-db-backups-volume"      # Sonarr database backups.
	"sonarr-db-config-volume"       # Sonarr database configuration.
	"sonarr-db-data-volume"         # Sonarr database data.
	"sonarr-volume"                 # Sonarr configuration and data.
	"thelounge-volume"              # The Lounge configuration and data.
	"unpackerr-volume"              # Unpackerr data.
	"vaultwarden-db-backups-volume" # Vaultwarden database backups.
	"vaultwarden-db-config-volume"  # Vaultwarden database configuration.
	"vaultwarden-db-data-volume"    # vaultwarden database data.
	"vaultwarden-volume"            # Vaultwarden data.
)

# Docker volumes to take ownership of.
readonly CHOWN_VOLUMES=(
	"beszel-agent-volume"
	"beszel-data-volume"
	"chhoto-volume"
	"configarr-volume"
	"dozzle-volume"
	"homarr-volume"
	"huntarr-volume"
	"jellyfin-cache-volume"
	"jellyfin-config-volume"
	"navidrome-cache-volume"
	"navidrome-backups-volume"
	"navidrome-data-volume"
	"opencloud-config-volume"
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

# Create bind mount directories on the host.
echo -e "\nCreating bind mount directories..."
create_dirs "$DOWNLOADS_PATH" "${DOWNLOADS_DIRECTORIES[@]}"
create_dirs "$MEDIA_LIBRARY_PATH" "${MEDIA_LIBRARY_DIRECTORIES[@]}"
create_dirs "$DOWNLOADS_INCOMPLETE_PATH" "${DOWNLOADS_INCOMPLETE_DIRECTORIES[@]}"

# Create Docker networks.
echo -e "\nCreating Docker networks..."

# Create Docker volumes.
echo -e "\nCreating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
	create_volume "$volume"
done

# Create Chhoto database.
CHHOTO_DATA_PATH="${DOCKER_VOLUMES_PATH}/chhoto-volume/_data"
$SUDO touch "${CHHOTO_DATA_PATH}/urls.sqlite"

# Create required folders.
HOMARR_DATA_PATH="${DOCKER_VOLUMES_PATH}/homarr-volume/_data"
$SUDO mkdir -p "${HOMARR_DATA_PATH}/redis"

# Set ownership of volumes by chowning their _data directory on the host
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

# Set ownership of the main bind mount directories on the host.
echo -e "\nSetting bind mount permissions..."
echo "Setting ownership for host directories..."
$SUDO chown -R "${PUID}:${PGID}" \
	"${OPENCLOUD_DATA_PATH}" \
	"${DOWNLOADS_PATH}" \
	"${DOWNLOADS_INCOMPLETE_PATH}" \
	"${MEDIA_LIBRARY_PATH}"

# Set permissions of the main bind mount directories on the host.
echo "Setting permissions for host directories..."
$SUDO chmod -R 775 \
	"${OPENCLOUD_DATA_PATH}" \
	"${DOWNLOADS_PATH}" \
	"${DOWNLOADS_INCOMPLETE_PATH}" \
	"${MEDIA_LIBRARY_PATH}"

echo -e "\nInitial setup complete!"

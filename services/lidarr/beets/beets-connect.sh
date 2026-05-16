#!/bin/sh

# Lidarr + beets connect script
# This script requires beets to be installed inside of the Lidarr container.
# Disable Lidarr's metadata handling by setting Settings -> Metadata -> Tag Audio Files with Metadata to never.
# Add it as a Custom Script in Lidarr -> Settings -> Connect.
# Be sure to only tick On Release Import and On Release Upgrade.

# Handle Lidarr's connection test.
# shellcheck disable=SC2154
if [ "$lidarr_eventtype" = "Test" ]; then
	echo "Connection test successful."
	exit 0
fi

# Configures paths. Ensure this matches Lidarr's volumes.
export BEETSDIR="/config/beets"
LOG_DIR="/config/beets-logs"
MAIN_LOG="$LOG_DIR/beets-connect.log"
UNPROCESSED_LOG="$LOG_DIR/beets-unprocessed.log"

# Creates required directories.
mkdir -p "$LOG_DIR"
mkdir -p "$BEETSDIR"

# Injects environment variables into the final beets config.
# This allows us to not hardcode environment variables into our config. Yay :3
# We do this because beets does not support environment variable interpolation.
if [ ! -f "$BEETSDIR/config.yaml" ] || [ "/beets/config.yaml" -nt "$BEETSDIR/config.yaml" ]; then
	envsubst </beets/config.yaml >"$BEETSDIR/config.yaml"
fi

# Exit if Lidarr sends a wrongful event with no track paths.
if [ -z "$lidarr_addedtrackpaths" ]; then
	echo "No track paths provided. Exiting." >>"$MAIN_LOG"
	exit 1
fi

# Extracts the directory of the first track.
FIRST_TRACK_DIR=$(dirname "${lidarr_addedtrackpaths%%|*}")

# If Lidarr put the track in a "CD 1" or "Disc 2" subfolder, target the parent album folder instead.
# This really shouldn't happen since subfolders for disks is not good, but lets handle it anyways.
if echo "$FIRST_TRACK_DIR" | grep -qiE "/(cd|disc|volume)\s*[0-9]+$"; then
	LIDARR_ALBUM_PATH=$(dirname "$FIRST_TRACK_DIR")
else
	LIDARR_ALBUM_PATH="$FIRST_TRACK_DIR"
fi

# Extracts the directory path of the album.
ALBUM_FOLDER_NAME=$(basename "$LIDARR_ALBUM_PATH")

# Creates a log file for the run.
# shellcheck disable=SC2154
RUN_LOG="$LOG_DIR/import-${lidarr_albumrelease_mbid}-$(date +%s).log"
echo "Processing $ALBUM_FOLDER_NAME." >>"$MAIN_LOG"

# Run Beets import; use double-verbose mode for debugging the log file.
BEET_OUTPUT=$(beet -vv import -q "$LIDARR_ALBUM_PATH" 2>&1)
echo "$BEET_OUTPUT" >"$RUN_LOG"

# Parses the results of the beets run.
if echo "$BEET_OUTPUT" | grep -qiE "skipping|no matching release"; then
	echo "Failed importing $LIDARR_ALBUM_PATH. See $RUN_LOG" >>"$UNPROCESSED_LOG"
else
	echo "Successfully imported $LIDARR_ALBUM_PATH. See $RUN_LOG" >>"$MAIN_LOG"

	# Tell Lidarr's API to do a re-scan when complete.
	# 127.0.0.1 assumes we're running beets inside of the container.
	if [ -n "$LIDARR_API_KEY" ] && [ -n "$lidarr_album_id" ]; then
		curl -s -X POST "http://127.0.0.1:8686/api/v1/command" \
			-H "X-Api-Key: $LIDARR_API_KEY" \
			-H "Content-Type: application/json" \
			-d "{\"name\": \"RefreshAlbum\", \"albumId\": $lidarr_album_id}" >/dev/null
	fi
fi

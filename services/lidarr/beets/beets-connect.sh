#!/bin/sh

# Handle Lidarr's connection test
# shellcheck disable=SC2154
if [ "$lidarr_eventtype" = "Test" ]; then
	echo "Lidarr connection test successful."
	exit 0
fi

export BEETSDIR="/config/beets"
LOG_DIR="/config/beets-logs"
MAIN_LOG="$LOG_DIR/beets-connect.log"
UNPROCESSED_LOG="$LOG_DIR/beets-unprocessed.log"

mkdir -p "$LOG_DIR"
mkdir -p "$BEETSDIR"

# Inject env vars into Beets config.
if [ ! -f "$BEETSDIR/config.yaml" ] || [ "/beets/config.yaml" -nt "$BEETSDIR/config.yaml" ]; then
	envsubst </beets/config.yaml >"$BEETSDIR/config.yaml"
fi

if [ -z "$lidarr_addedtrackpaths" ]; then
	echo "$(date '+%Y-%m-%d %H:%M:%S') | ERROR | No track paths provided. Exiting." >>"$MAIN_LOG"
	exit 1
fi

# Extract the directory of the first track
FIRST_TRACK_DIR=$(dirname "${lidarr_addedtrackpaths%%|*}")

# If Lidarr put the track in a "CD 1" or "Disc 2" subfolder, target the parent album folder instead
if echo "$FIRST_TRACK_DIR" | grep -qiE "/(cd|disc|volume)\s*[0-9]+$"; then
	LIDARR_ALBUM_PATH=$(dirname "$FIRST_TRACK_DIR")
else
	LIDARR_ALBUM_PATH="$FIRST_TRACK_DIR"
fi

ALBUM_FOLDER_NAME=$(basename "$LIDARR_ALBUM_PATH")

# shellcheck disable=SC2154
RUN_LOG="$LOG_DIR/import-${lidarr_albumrelease_mbid}-$(date +%s).log"
echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO | Processing: $ALBUM_FOLDER_NAME (Rel: $lidarr_albumrelease_mbid)" >>"$MAIN_LOG"

# Run Beets import.
BEET_OUTPUT=$(beet -vv import -q "$LIDARR_ALBUM_PATH" 2>&1)
echo "$BEET_OUTPUT" >"$RUN_LOG"

# Parse results and trigger webhooks.
if echo "$BEET_OUTPUT" | grep -qiE "skipping|no matching release"; then
	echo "$(date '+%Y-%m-%d %H:%M:%S') | FAIL | $LIDARR_ALBUM_PATH | Log: $RUN_LOG" >>"$UNPROCESSED_LOG"

	if [ -n "$BEETS_DISCORD_WEBHOOK_URL" ]; then
		curl -s -H "Content-Type: application/json" -d "{\"embeds\": [{\"title\": \"❌ Beets Import Failed\", \"description\": \"**$ALBUM_FOLDER_NAME**\nCheck log: \`$RUN_LOG\`\", \"color\": 15158332}]}" "$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
	fi
else
	echo "$(date '+%Y-%m-%d %H:%M:%S') | SUCC | $LIDARR_ALBUM_PATH | Log: $RUN_LOG" >>"$MAIN_LOG"

	if [ -n "$BEETS_DISCORD_WEBHOOK_URL" ]; then
		curl -s -H "Content-Type: application/json" -d "{\"embeds\": [{\"title\": \"✅ Beets Import Success\", \"description\": \"**$ALBUM_FOLDER_NAME**\", \"color\": 3066993}]}" "$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
	fi

	# update lidarr api
	if [ -n "$LIDARR_API_KEY" ] && [ -n "$lidarr_album_id" ]; then
		curl -s -X POST "http://127.0.0.1:8686/api/v1/command" \
			-H "X-Api-Key: $LIDARR_API_KEY" \
			-H "Content-Type: application/json" \
			-d "{\"name\": \"RefreshAlbum\", \"albumId\": $lidarr_album_id}" >/dev/null
	fi
fi

# Cleanup old isolated run logs.
find "$LOG_DIR" -type f -name "import-*.log" -mtime +7 -delete

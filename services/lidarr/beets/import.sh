#!/bin/sh

# Setup directories and log paths.
export BEETSDIR="/config/beets"
LOG_DIR="/config/beets-logs"
MAIN_LOG="$LOG_DIR/beets-connect.log"
UNPROCESSED_LOG="$LOG_DIR/beets-unprocessed.log"

# Create the dedicated log directory if it doesn't exist.
mkdir -p "$LOG_DIR"

# Use envsubst to inject environment variables into the template.
# Prevent race conditions by only parsing if the template is newer than the destination config.
if [ ! -f "$BEETSDIR/config.yaml" ] || [ "/beets/config.yaml" -nt "$BEETSDIR/config.yaml" ]; then
	envsubst </beets/config.yaml >"$BEETSDIR/config.yaml"
fi

echo "[$(date)] Triggered Beets Connect Script" >>"$MAIN_LOG"

# Exit if no track paths are provided.
if [ -z "$lidarr_addedtrackpaths" ]; then
	echo "[$(date)] ERROR: No track paths provided. Exiting." >>"$MAIN_LOG"
	exit 0
fi

# Get the added track paths and album path.
lidarr_first_track=$(echo "$lidarr_addedtrackpaths" | cut -d '|' -f1)
lidarr_album_path=$(dirname "$lidarr_first_track")
ALBUM_FOLDER_NAME=$(basename "$lidarr_album_path")

# Exit if no album path is provided.
if [ -z "$lidarr_album_path" ]; then
	echo "[$(date)] ERROR: No album path provided. Exiting." >>"$MAIN_LOG"
	exit 0
fi

# Create a dedicated log file just for this specific import
# shellcheck disable=SC2154
RUN_LOG="$LOG_DIR/import-${lidarr_albumrelease_mbid}-$(date +%s).log"

# Log the high-level details to the main summary log
# shellcheck disable=SC2129
# shellcheck disable=SC2154
echo "[$(date)] Album MBID: $lidarr_album_mbid" >>"$MAIN_LOG"
echo "[$(date)] Release MBID: $lidarr_albumrelease_mbid" >>"$MAIN_LOG"
echo "[$(date)] Processing: $lidarr_album_path" >>"$MAIN_LOG"

# Capture the output of the Beets run and dump it into the isolated log file.
BEET_OUTPUT=$(beet -vv import -q "$lidarr_album_path" 2>&1)
echo "$BEET_OUTPUT" >"$RUN_LOG"

# Check if Beets decided to skip the album.
if echo "$BEET_OUTPUT" | grep -qiE "skipping|no matching release"; then
	echo "[$(date)] FAILED/SKIPPED: $lidarr_album_path (See $RUN_LOG)" >>"$UNPROCESSED_LOG"
	echo "[$(date)] Status: FAILED" >>"$MAIN_LOG"

	# Discord Webhook: FAILED
	if [ -n "$BEETS_DISCORD_WEBHOOK_URL" ]; then
		curl -s -X POST -H "Content-Type: application/json" \
			-d "{\"embeds\": [{\"title\": \"❌ Beets Import Failed\", \"description\": \"Failed to match or skipped:\\n**$ALBUM_FOLDER_NAME**\\n\\nCheck log: \`$RUN_LOG\`\", \"color\": 15158332}]}" \
			"$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
	fi
else
	echo "[$(date)] Status: SUCCESS (Verbose log saved to $RUN_LOG)" >>"$MAIN_LOG"

	# Discord Webhook: SUCCESS
	if [ -n "$BEETS_DISCORD_WEBHOOK_URL" ]; then
		curl -s -X POST -H "Content-Type: application/json" \
			-d "{\"embeds\": [{\"title\": \"✅ Beets Import Success\", \"description\": \"Successfully tagged and imported:\\n**$ALBUM_FOLDER_NAME**\", \"color\": 3066993}]}" \
			"$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
	fi

	# Trigger Lidarr to rescan the album so it sees the new tags and downloaded art Beets just wrote
	if [ -n "$LIDARR_API_KEY" ] && [ -n "$lidarr_album_id" ]; then
		echo "[$(date)] Triggering Lidarr API refresh for Album ID: $lidarr_album_id" >>"$MAIN_LOG"
		curl -s -X POST "http://127.0.0.1:8686/api/v1/command" \
			-H "X-Api-Key: $LIDARR_API_KEY" \
			-H "Content-Type: application/json" \
			-d "{\"name\": \"RefreshAlbum\", \"albumId\": $lidarr_album_id}" >/dev/null
	else
		echo "[$(date)] WARNING: Missing Lidarr API Key or Album ID. Skipping API refresh." >>"$MAIN_LOG"
	fi
fi

# Log cleanup: Find and delete isolated run logs older than 7 days
find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec rm {} \;
echo "[$(date)] Beets connect script complete." >>"$MAIN_LOG"

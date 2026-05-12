#!/bin/sh

# Configuration
LIBRARY_DIR="/library/music"
LOG_DIR="/config/beets-logs"
LOG_FILE="$LOG_DIR/manual_import_$(date +%s).log"
SKIPPED_FILE="$LOG_DIR/manual_skipped_$(date +%s).txt"

mkdir -p "$LOG_DIR"
beet -vv import -q -w "$LIBRARY_DIR" >"$LOG_FILE" 2>&1
echo "Scan complete. Parsing logs for skipped or failed items..."

# Extract skips, errors, and failures to a separate text file
grep -iE "skipping|no matching release|error|failed" "$LOG_FILE" >"$SKIPPED_FILE"

# Count the number of skipped/failed lines
SKIPPED_COUNT=$(wc -l <"$SKIPPED_FILE")

# Trigger Discord Webhook
if [ "$SKIPPED_COUNT" -gt 0 ]; then
	echo "Found skipped/failed items. Uploading report to Discord..."

	# Discord allows uploading text files directly via multipart/form-data
	curl -s -H "Content-Type: multipart/form-data" \
		-F "payload_json={\"content\": \"⚠️ **Beets Manual Library Scan Complete**\nThere were **$SKIPPED_COUNT** log entries indicating skipped items or failures. See the attached text file for details, idiot.\"}" \
		-F "file=@$SKIPPED_FILE" \
		"$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
else
	echo "No errors found."

	curl -s -H "Content-Type: application/json" \
		-d "{\"embeds\": [{\"title\": \"✅ Beets Scan Complete\", \"description\": \"Manual library scan finished with zero skips or errors.\", \"color\": 3066993}]}" \
		"$BEETS_DISCORD_WEBHOOK_URL" >/dev/null
fi

echo "Done! Full verbose log: $LOG_FILE"
echo "Skipped items log: $SKIPPED_FILE"

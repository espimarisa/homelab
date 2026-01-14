#!/bin/bash
# ------------------------------------------------------------------
# Lidarr Connect Script for Beets
# ------------------------------------------------------------------

LOGFILE="/config/beets-connect.log"
echo "--- [$(date)] Beets Connect Triggered ---" >> "$LOGFILE"

# 1. Debug: Log the event type to understand what Lidarr is doing
echo "Event: $lidarr_eventtype" >> "$LOGFILE"

# 2. Smart Path Detection
# Lidarr passes different variables depending on the event.
# We check 'lidarr_album_path' first, then fall back to constructing it.
TARGET_PATH=""

if [ -n "$lidarr_album_path" ]; then
    TARGET_PATH="$lidarr_album_path"
elif [ -n "$lidarr_artist_path" ] && [ -n "$lidarr_album_title" ]; then
    TARGET_PATH="$lidarr_artist_path/$lidarr_album_title"
fi

# 3. Validation
if [ -z "$TARGET_PATH" ]; then
    echo "Error: Could not determine album path from Lidarr variables." >> "$LOGFILE"
    exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
    echo "Error: Directory does not exist: $TARGET_PATH" >> "$LOGFILE"
    exit 1
fi

echo "Processing: $TARGET_PATH" >> "$LOGFILE"

# 4. Run Beets
# -c: Config path
# -q: Quiet mode (non-interactive)
/usr/bin/beet -c /config/config.yaml import -q "$TARGET_PATH" >> "$LOGFILE" 2>&1

echo "--- Complete ---" >> "$LOGFILE"

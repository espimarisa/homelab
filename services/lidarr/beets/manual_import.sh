#!/bin/sh

# Internal container paths
MUSIC_DIR="/library/music" 
CONFIG="/musiclibrary.blb"
LOG_FILE="/beets-logs/beet.log"
SKIPPED_FILE="/beets-logs/needs_manual_fixing.txt"

# Clear previous run log
> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO | Starting unattended Beets import..."

# Execute quiet import
beet -c "$CONFIG" import -q "$MUSIC_DIR"

# Parse skipped items
grep -i "skip" "$LOG_FILE" > "$SKIPPED_FILE"

SKIPPED_COUNT=$(wc -l < "$SKIPPED_FILE")

echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO | Import complete. $SKIPPED_COUNT items skipped."
echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO | Review skipped items in: $SKIPPED_FILE"
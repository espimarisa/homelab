#!/bin/bash

CONTAINER_NAME="lidarr"
MUSIC_DIR="/library/music"

echo "Starting Pass 1: Auto-tagging confident matches..."
docker exec -it "$CONTAINER_NAME" beet import -q "$MUSIC_DIR"

echo "Pass 1 Complete."
echo "Starting Pass 2: Interactive mode for skipped/messy albums..."

# Execute the loop entirely inside the container so paths and logs align
docker exec -it "$CONTAINER_NAME" bash -c '
  LOG_FILE="/config/beets-logs/cleanup-failed.txt"

  # Clear out the old log file from previous runs
  > "$LOG_FILE"

  # Loop through Artist/Album directories
  for dir in "$MUSIC_DIR"/*/*; do
    if [ -d "$dir" ]; then

      # Check if the Beets database has any entries for this directory path
      DB_MATCH=$(beet ls -a path:"$dir")

      # If the output is empty (-z), Beets skipped it in Pass 1
      if [ -z "$DB_MATCH" ]; then
        echo "---------------------------------------------------"
        echo "Requires manual matching: $dir"

        # Log it so you have a record of what needed fixing
        echo "$dir" >> "$LOG_FILE"

        # Run the interactive import
        beet import "$dir"
      fi

    fi
  done
'

echo "Beets cleanup complete. Check /config/beets-logs/cleanup-failed.txt inside the container for a full list of what was processed."

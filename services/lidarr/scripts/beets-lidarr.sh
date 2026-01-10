#!/bin/bash

# 1. Log startup
echo "[$(date)] Beets Connect Script Triggered" >> /config/beets-connect.log

# 2. Check for path
if [ -z "$lidarr_album_path" ]; then
    echo "No album path provided. Exiting." >> /config/beets-connect.log
    exit 0
fi

echo "Processing Album: $lidarr_album_path" >> /config/beets-connect.log

# 3. Run Beets
/usr/bin/beet -c /scripts/config.yml import "$lidarr_album_path" >> /config/beets-connect.log 2>&1

echo "Beets processing complete." >> /config/beets-connect.log

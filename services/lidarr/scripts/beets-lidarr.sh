#!/bin/bash

# 1. Log startup to a file so we know it ran
echo "[$(date)] Beets Connect Script Triggered" >> /config/beets-connect.log

# 2. Check if Lidarr sent us a path
if [ -z "$lidarr_album_path" ]; then
    echo "No album path provided by Lidarr. Exiting." >> /config/beets-connect.log
    exit 0
fi

# shellcheck disable=SC2129
echo "Processing Album: $lidarr_album_path" >> /config/beets-connect.log

# 3. Run Beets on that specific folder
# We use --noquiet to ensure it writes, but since this runs in background,
# we rely on your 'strong_rec_thresh' config to be safe.
/usr/bin/beet -c /scripts/config.yml import --noquiet "$lidarr_album_path" >> /config/beets-connect.log 2>&1

echo "Beets processing complete." >> /config/beets-connect.log

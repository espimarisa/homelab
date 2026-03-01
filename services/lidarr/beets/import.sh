#!/bin/bash

# beets connect script
# This script is meant for use with Lidarr.
# It will inject environment variables into beets/config.yaml
# and tag in-place upon fresh imports or upgrades.

# Force Beets to use Lidarr's writable config directory.
export BEETSDIR="/config/beets"
mkdir -p /config/beets

# Use envsubst to inject environment variables into the template.
envsubst </beets/config.yaml >/config/beets/config.yaml
echo "[$(date)] Beets Connect Script Triggered" >>/config/beets-connect.log

if [ -z "$lidarr_album_path" ]; then
	echo "No album path provided by Lidarr. Exiting." >>/config/beets-connect.log
	exit 0
fi

echo "Processing Album: $lidarr_album_path" >>/config/beets-connect.log
/usr/bin/beet -vv -c /beets/config.yml import --noquiet "$lidarr_album_path" >>/config/beets-connect.log 2>&1

echo "Beets processing complete." >>/config/beets-connect.log

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

# Run Beets and dump to the debug log.
# $lidarr_album_path is from Lidarr.
# shellcheck disable=SC2154
beet -vv import -q "$lidarr_album_path" >/config/beet-debug.log 2>&1

# Tell Lidarr to refresh, and send the JSON response to the void.
# $lidarr_artist_id is provided from Lidarr.
#curl -s -X POST "http://localhost:8686/api/v1/command" \
#	-H "X-Api-Key: ${LIDARR_API_KEY}" \
#	-H "Content-Type: application/json" \
#	-d '{"name": "RefreshArtist", "artistId": '"$lidarr_artist_id"'}' >/dev/null

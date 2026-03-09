#!/bin/sh

# Use the writeable configuration directory inside of the Lidarr container.
export BEETSDIR="/config/beets"

# Use envsubst to inject environment variables into the template since beets does not support this.
envsubst </beets/config.yaml >/config/beets/config.yaml
echo "[$(date)] Beets Connect script triggered" >>/config/beets-connect.log

# Do not run if $lidarr_addedtrackpaths is not provided.
if [ -z "$lidarr_addedtrackpaths" ]; then
	echo "No track paths path provided. Exiting." >>/config/beets-connect.log
	exit 0
fi

# Gets the added track paths and album path.
# $lidarr_addedtrackpaths and $lidarr_first_track are provided by Lidarr.
# shellcheck disable=SC2154
echo "$lidarr_addedtrackpaths"
lidarr_first_track=$(echo "$lidarr_addedtrackpaths" | cut -d '|' -f1)
lidarr_album_path=$(dirname "$lidarr_first_track")

# Do not run if $lidarr_album_path is not provided.
if [ -z "$lidarr_album_path" ]; then
	echo "No album path provided. Exiting." >>/config/beets-connect.log
	exit 0
fi

# Prints debug output.
# shellcheck disable=SC2154
echo "Album MBID: $lidarr_album_mbid"
# shellcheck disable=SC2154
echo "Release MBID: $lidarr_albumrelease_mbid"
echo "Processing Album: $lidarr_album_path" >>/config/beets-connect.log

# Imports the album path using beets.
# Run in double verbose mode, and any non-auto matches will be skipped due to config.yaml.
beet -vv import "$lidarr_album_path" >>/config/beets-connect.log 2>&1
echo "[$(date)] Beets connect script complete." >>/config/beets-connect.log

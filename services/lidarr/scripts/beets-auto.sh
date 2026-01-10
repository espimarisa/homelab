#!/bin/bash
# /config/scripts/auto-tag.sh

# Lidarr passes the album path in this environment variable.
# shellcheck disable=SC2154
ALBUM_PATH="$lidarr_artist_path/$lidarr_album_title"

echo "Beets is fixing metadata for: $ALBUM_PATH."

# Run beet import
# -c = path to config
# -q = quiet (auto-tag)
# "$ALBUM_PATH" = only scan this specific folder.
beet -c /scripts/config.yaml import -q "$ALBUM_PATH"

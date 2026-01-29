#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# This script scans for featurettes.
# It then imports them in Radarr.
# Add it as a connect script.

echo "Running featurettes importer..."
# shellcheck disable=SC2154
source_folder="$radarr_moviefile_sourcefolder"
# shellcheck disable=SC2154
destination_folder="$radarr_movie_path"
featurettes_source_path="$source_folder/Featurettes"
featurettes_dest_path="$destination_folder/Featurettes"

if [ -d "$featurettes_source_path" ]; then
	echo "Found 'Featurettes' folder at: $featurettes_source_path"
	echo "Copying to: $featurettes_dest_path"
	cp -rpf "$featurettes_source_path" "$destination_folder"

	echo "Successfully copied Featurettes folder."
else
	echo "No Featurettes folder found in source directory. Nothing to do."
fi

exit 0

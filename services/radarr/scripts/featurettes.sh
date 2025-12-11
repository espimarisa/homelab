#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

#################################################################################
# This script scans for a "Featurettes" folder alongside a movie file and     #
# copies it to the movie's final destination folder in the library.           #
# Configure Radarr to run this script on import.                              #
#################################################################################

echo "=== Running Radarr Featurettes Importer ==="
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

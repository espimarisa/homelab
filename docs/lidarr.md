# Lidarr

Lidarr is a music manager, organizer, and PVR and one of the primary 'ARR apps. However, it struggles with writing fully accurate metadata and generally is best left as an organizer and mover instead of a metadata writer.

## Lidarr + Beets

1. Make the script executable. `chmod +x ./services/lidarr/scripts/beets.sh`.
2. Ensure required environment variables **LIDARR_API_KEY**, **DISCOGS_API_KEY**, **GENIUS_API_KEY**, and **LASTFM_API_KEY** are set.
3. Start Lidarr, and add the beets connect script by going to Connect -> Custom Script. Point the path to `/beets/import.sh` and choose to run it only on **Release Import** and **Release Upgrade**.
4. Ensure Lidarr's metadata handling is disabled in Settings -> Metadata.

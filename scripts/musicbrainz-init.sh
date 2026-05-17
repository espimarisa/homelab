#!/bin/sh

echo "Building MusicBrainz containers..."
docker compose build musicbrainz

echo "Initializing the MusicBrainz PostgreSQL database..."
echo "This may take a while."
docker compose run --rm musicbrainz createdb.sh -fetch

echo "Starting core MusicBrainz services..."
docker compose up -d musicbrainz search indexer

echo "Downloading MusicBrainz search indexes..."
echo "This will take quite a while."

echo "Loading MusicBrainz search indexes..."
docker compose exec search load-backup-archives

echo "Cleaning up..."
docker compose exec search remove-backup-archives

echo "MusicBrainz initialized at http://127.0.0.1:5000"

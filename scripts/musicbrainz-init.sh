#!/bin/sh

echo "Configuring MusicBrainz profiles..."
cd submodules/musicbrainz || exit
sudo ./admin/configure with default replication-cron live-indexing-search

echo "Configuring MetaBrainz API token..."
sudo ./admin/set-replication-token
cd ../..

echo "Building MusicBrainz containers..."
docker compose build musicbrainz

echo "Downloading and initializing the MusicBrainz database..."
docker compose run --rm musicbrainz createdb.sh -fetch

echo "Starting core MusicBrainz services..."
docker compose up -d musicbrainz search indexer mq replication-cron

echo "Setting up message queues..."
docker compose exec musicbrainz amqp-setup.sh

echo "Installing search index updater..."
cd submodules/musicbrainz || exit
sudo ./admin/setup-sir install
cd ../..

echo "Fetching search indexes..."
docker compose exec search fetch-backup-archives

echo "Loading search indexes..."
docker compose exec search load-backup-archives

echo "Cleaning up archives..."
docker compose exec search remove-backup-archives

echo "MusicBrainz is live at http://127.0.0.1:5000"

# 'Arr Apps

This folder stores my 'ARR stack, consisting of the following applications:

- Byparr
- Huntarr
- Lidarr
- Prowlarr
- Profilarr
- Radarr
- Sonarr
- Unpackerr

## Prowlarr Configuration

### Settings -> General

1. Disable telemetry by unticking "Send Anonymous Usage Data".
2. Copy the API key to `.env` under `PROWLARR_API_KEY="<paste_here>"`.

### Settings -> Download Clients

1. Add qBittorrent with the following options:
    - Host: `127.0.0.1`
    - Port: `8080`
    - Username: `admin`
    - Password: `your-webui-password`

### Settings -> Indexers

1. Add Byparr (choose Flaresolverr) with the following options:
    - Name: `Byparr`
    - Tags: `byparr`
    - Host: `http://127.0.0.1:8191/`

### Settings -> Applications

1. Add Lidarr with the following options:
    - Name: `Lidarr`
    - Sync Level: `Full Sync`
    - Tags: `lidarr`
    - Prowlarr Server: `http://gluetun:9696`
    - Lidarr Server: `http://lidarr:8686`
    - API Key: `your api key`
2. Add Radarr with the following options:
    - Name: `Radarr`
    - Sync Level: `Full Sync`
    - Tags: `radarr`
    - Prowlarr Server: `http://gluetun:9696`
    - Radarr Server: `http://radarr:7878`
    - API Key: `your api key`
3. Add Sonarr with the following options:
    - Name: `Sonarr`
    - Sync Level: `Full Sync`
    - Tags: `sonarr`
    - Prowlarr Server: `http://gluetun:9696`
    - Sonarr Server: `http://sonarr:8989`
    - Sync Anime Standard Format Search: `Enabled`
    - API Key: `your api key`
4. Create a sync profile for limited indexers (Nyaa):
    - Name: `No RSS`
    - Enable RSS: `Disabled`
    - Enable Automatic Search: `Enabled`
    - Enable Interactive Search: `Enabled`
    - Minimum Seeders: `3`
5. Create a sync profile for interactive only indexers:
    - Name: `Interactive Only`
    - Enable RSS: `Disabled`
    - Enable Automatic Search: `Disabled`
    - Enable Interactive Search: `Enabled`
    - Minimum Seeders: `1`
6. Edit the standard sync profile to require `3` seeders.

### Indexers

You will want to add any of your own private indexers, but here are some public trackers I add:

1. 1337x:
    - Sync Profile: `Standard`
    - Base URL: `https://1337x.to`
    - Sort requested from site: `seeders`
    - Indexer priority: `30`
    - Tags: `byparr, lidarr, radarr, sonarr`
2. EZTV:
    - Sync Profile: `Standard`
    - Base URL: `https://eztvx.to`
    - Indexer priority: `30`
    - Tags: `radarr, sonarr`
3. Nyaa:
    - Sync Profile: `No RSS`
    - Base URL: `https://nyaa.si`
    - Improve Sonarr compatibility by trying to add Season information into Release Titles: `Enabled`
    - Remove first season keywords (S1/S01/Season 1), as some results do not include this for first/single season releases: `Enabled`
    - Improve Radarr compatibility by removing year information from keywords and adding it to Release Titles: `Enabled`
    - Sort requested from site: `seeders`
    - Indexer Priority: `1`
    - Tags: `radarr, sonarr`
4. The Pirate Bay:
    - Sync Profile: `Standard`
    - Base URL: `https://thepiratebay.org`
    - Indexer Priority: `30`
    - Tags: `lidarr, radarr, sonarr`
5. TorrentGalaxyClone:
    - Sync Profile: `Standard`
    - Base URL: `https://torrentgalaxy.info`
    - Indexer Priority: `30`
    - Tags: `radarr, sonarr`

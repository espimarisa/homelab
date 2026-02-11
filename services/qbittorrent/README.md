# Configuration

These are the settings I use and are generally up to date. I run my server as a permanent seedbox and download to a feeder SSD first, so your mileage may vary.

1. Navigate to `https://qbittorrent.${INTERNAL_DOMAIN}`.
2. Settings -> Downloads
    - Torrent Content Layout: **Original**
    - Append .!qB extension for incomplete files: **Enabled**
    - Default Torrent Management Mode: **Automatic**
        - When Torrent Category changed: **Relocate torrent**
        - When Default Save Path changed: **Relocate torrent**
        - When Category Save Path changed: **Relocate torrent**
    - Use Category paths in Manual Mode:
        - Default save path: **/downloads/torrents/uncategorized**
        - Default download path: **/downloads-incomplete/torrents**
        - Copy .torrent files to: **/downloads/torrents/.torrent-files**
3. Settings -> Connection
    - Peer connection protocol: **TCP**
    - Port used for incoming connections: **Whatever your forwarded port is**
    - Use UPnP/NAT-PMP port forwarding from my router: **Disabled**
4. Settings -> Speed
    - Alternative Rate Limits: **Adjust as needed.**
    - Apply rate limit to uTP protocol: **Enabled**
    - Apply rate limit to transport overhead: **Disabled**
    - Apply rate limit to peers on LAN: **Enabled**
5. Settings -> BitTorrent
    - Enable DHT (decentralized network) to find more peers: **Enabled**
    - Enable Peer Exchange (PeX) to find more peers: **Enabled**
    - Enable Local Peer Discovery to find more peers: **Enabled**
    - Encryption Mode: **Allow encryption**
    - Enable anonymouse mode: **Disabled**
    - Max active checking torrents: **1**
    - Torrent Queueing: **Enabled**
        - Maximum active downloads: **10, adjust as needed**
        - Maximum active uploads: **100, adjust as needed**
        - Maximum active torrents: **100, adjust as needed**
    - Automatically append these trackers to new downloads: **EMPTY THIS**
6. Settings -> WebUI
    - Use Alternative WebUI: **/qbittorrent/themes/vuetorrent**
    - Authentication: **Set username and password**
    - Bypass authentication for localhost: **Enabled**
    - Bypass authentication for clients in whitelisted IP subnets: **172.19.1.0/24, 172.19.2.0/24, 172.19.3.0/24**
    - Security:
        - Enable clickjacking protection: **Disabled**
        - Enable Cross-Site Request Forgery (CSRF) protection: **Disabled**
        - Enable Host header validation: **Disabled**
7. Settings -> Tags & Categories
    - Create **lidarr**, save to **/downloads/torrents/lidarr**
    - Create **sonarr**, save to **/downloads/torrents/sonarr**
    - Create **radarr**, save to **/downloads/torrents/radarr**
    - Create **uncategorized**, save to **/downloads/torrents/uncategorized**
8. Settings -> Advanced
    - Resume data storage type: **Fastresume files**
    - Save resume data interval: **5**
    - Physical memory (RAM) usage limit: **4096, adjust as needed**
    - Reannounce to all trackers when IP or port changed: **Enabled**
    - ***NETWORKING INTERFACE: tun0. THIS IS THE VPN CONNECTION!***
    - Threads:
        - Asynchronous I/O threads: **2, adjust as needed**
        - Hashing threads: **2, adjust as needed**
        - File pool size: **500**
        - Outstanding memory when checking torrents: **128**
    - Disk (I use an SSD here)
        - Disk Queue Size: **Your SSD/HDDs cache size**
        - Disk IO read mode: **Enable OS Cache**
        - Disk IO write mode: **Enable OS cache**
        - Disk IO type: **Simple pread/pwrite**
    - Use piece extent affinity: **Enabled**
    - Send upload piece suggestions: **Enabled**
    - Send buffer watermark: **1024**
    - Send buffer low watermark: **1024**
    - Send buffer watermark factor: **150**
    - uTP-TCP mixed mode algorithm: **Prefer TCP**
    - Security:
        - Enable IDN support: **Enabled**
        - Allow multiple connections from the same IP address: **Enabled**
        - Validate HTTPS tracker certificate: **Enabled**
        - Server-side request forgery mitigation: **Enabled**
    - Upload slots behavior: **Upload rate based**
    - Upload choking algorithm: **Fastest upload**

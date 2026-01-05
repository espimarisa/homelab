#!/bin/bash

# This script sends mdadm alerts to a Discord webhook. Requires curl.
# Copy this to /usr/local/bin/discord-mdadm.sh and chmod 600 && chmod +x it.
# You will need to update /etc/mdadm.conf to include a line with the following:
# PROGRAM /usr/local/bin/discord-mdadm.sh

SYSTEM_NAME="hostname-of-the-system-change-me"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
WEBHOOK_NAME="RAID Monitor"
WEBHOOK_URL="https://webhook-url-change-me.discordapp.com"

# mdadm passes these variables automatically.
EVENT=$1
DEVICE=$2

# Color generation logic. Red = fail, green = success, blue = info.
if [[ $EVENT == "Fail" || $EVENT == "Degraded" || $EVENT == "DeviceDisappeared" ]]; then
	COLOR=15158332
elif [[ $EVENT == "TestMessage" ]]; then
	COLOR=3066993
else
	COLOR=3447003
fi

# Constructs the JSON payload to send to the Discord API.
PAYLOAD=$(
	cat <<EOF
{
  "username": $WEBHOOK_NAME,
  "embeds": [{
	"title": "RAID Alert: $EVENT",
	"description": "Storage event detected on **$SYSTEM_NAME**.",
	"color": $COLOR,
	"fields": [
	  { "name": "Device", "value": "\`$DEVICE\`", "inline": true },
	  { "name": "Event", "value": "\`$EVENT\`", "inline": true },
	  { "name": "Time", "value": "$TIMESTAMP", "inline": false }
	]
  }]
}

EOF
)

# Sends the event to the Discord API.
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1

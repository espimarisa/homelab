#!/bin/bash

# This script sends smartd alerts to a Discord webhook. Requires curl.
# Copy this to /usr/local/bin/discord-smartd.sh and chmod 600 && chmod +x it.
# You will need to update /etc/smartd.conf to include an exec line. For example:
# DEVICESCAN -H -m your@email.com -M exec /usr/local/bin/discord-smartd.sh -n standby

EMBED_COLOR=16753920
SYSTEM_NAME="hostname-of-the-system-change-me"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
WEBHOOK_NAME="SMART Monitor"
WEBHOOK_URL="https://webhook-url-change-me.discordapp.com"

# smartd sets these variables automatically.
DEVICE="$SMARTD_DEVICE"
MESSAGE="$SMARTD_MESSAGE"
FAILTYPE="$SMARTD_FAILTYPE"

# Constructs the JSON payload to send to the Discord API.
PAYLOAD=$(
	cat <<EOF
{
  "username": $WEBHOOK_NAME,
  "embeds": [{
	"title": "Drive Health Alert: $FAILTYPE",
	"description": "SMART error detected on **$SYSTEM_NAME**.",
	"color": $EMBED_COLOR,
	"fields": [
	  { "name": "Device", "value": "\`$DEVICE\`", "inline": true },
	  { "name": "Time", "value": "$TIMESTAMP", "inline": true },
	  { "name": "Message", "value": "$MESSAGE", "inline": false }
	]
  }]
}

EOF
)

# Sends the event to the Discord API.
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1

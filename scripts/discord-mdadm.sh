#!/bin/bash

# /etc/smartd.conf - DEVICESCAN -H -m email@bla.com -M exec /usr/local/bin/discord-smart-alert.sh -n standby

WEBHOOK_URL="https://bla"
SYSTEM_NAME="asdf"

# mdadm passes these variables automatically
EVENT=$1
DEVICE=$2

# Get current timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Color Logic:
# Red (15158332) for failures
# Green (3066993) for tests/good news
# Blue (3447003) for info
if [[ $EVENT == "Fail" || $EVENT == "Degraded" || $EVENT == "DeviceDisappeared" ]]; then
	COLOR=15158332
elif [[ $EVENT == "TestMessage" ]]; then
	COLOR=3066993
else
	COLOR=3447003
fi

# Construct the JSON payload
PAYLOAD=$(
	cat <<EOF
{
  "username": "RAID Monitor",
  "embeds": [{
    "title": "MDADM Alert: $EVENT",
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

# Send to Discord.
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1

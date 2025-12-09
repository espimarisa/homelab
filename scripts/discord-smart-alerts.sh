#!/bin/bash

# /etc/mdadm.conf
# MAILADDR bla@bla.com
# MAILFROM blabla@bla.com
# PROGRAM /usr/local/bin/discord-mdadm.sh

WEBHOOK_URL="https://bla"
SYSTEM_NAME="asdf"

# SMARTD sets these variables automatically
DEVICE="$SMARTD_DEVICE"
MESSAGE="$SMARTD_MESSAGE"
FAILTYPE="$SMARTD_FAILTYPE"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Orange
COLOR=16753920

PAYLOAD=$(
	cat <<EOF
{
  "username": "SMART Monitor",
  "embeds": [{
    "title": "Drive Health Alert: $FAILTYPE",
    "description": "SMART error detected on **$SYSTEM_NAME**.",
    "color": $COLOR,
    "fields": [
      { "name": "Device", "value": "\`$DEVICE\`", "inline": true },
      { "name": "Time", "value": "$TIMESTAMP", "inline": true },
      { "name": "Message", "value": "$MESSAGE", "inline": false }
    ]
  }]
}
EOF
)

# Send to Discord
curl -H "Content-Type: application/json" -X POST -d "$PAYLOAD" "$WEBHOOK_URL" >/dev/null 2>&1

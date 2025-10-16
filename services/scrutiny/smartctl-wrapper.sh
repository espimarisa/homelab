#!/bin/sh

for device_path; do true; done

if [ "$device_path" = "/dev/sda" ]; then
	exec /usr/sbin/smartctl -d scsi "$@"
else
	exec /usr/sbin/smartctl "$@"
fi

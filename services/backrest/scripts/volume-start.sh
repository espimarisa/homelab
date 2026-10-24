#!/bin/bash
if [ -f /tmp/stopped_containers.txt ]; then
	stopped_containers=$(cat /tmp/stopped_containers.txt)

	if [ -n "$stopped_containers" ]; then
		# shellcheck disable=SC2086
		docker start $stopped_containers
	fi

	rm /tmp/stopped_containers.txt
fi

#!/bin/bash

all_containers=$(docker ps --quiet | sort)

ignore_containers=$(docker ps --quiet \
	--filter "name=backrest" \
	--filter "name=beszel" \
	--filter "name=beszel-agent" \
	--filter "name=caddy" \
	--filter "name=configarr" \
	--filter "name=lrclib" \
	--filter "name=gatus" \
	--filter "name=gatus-db" \
	--filter "name=dozzle" \
	--filter "name=socket-proxy" \
	--filter "name=unpackerr" | sort)

pending_containers=$(comm -23 <(echo "$all_containers") <(echo "$ignore_containers"))

echo "Stopping docker containers..."

if [ -n "$pending_containers" ]; then
	echo "$pending_containers" >/tmp/stopped_containers.txt
	docker stop "$pending_containers"
fi

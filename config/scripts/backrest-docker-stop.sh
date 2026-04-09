#!/bin/bash

# Get all containers
all_containers=$(docker ps --quiet | sort)

# Containers to ignore (Notice the added '|' before sort)
ignore_containers=$(
	docker ps --quiet \
		--filter "name=backrest" \
		--filter "name=beszel" \
		--filter "name=caddy" \
		--filter "name=configarr" \
		--filter "name=gluetun" \
		--filter "name=dozzle" \
		--filter "name=socket-proxy" \
		--filter "name=unpackerr" |
		sort
)

pending_containers=$(comm -23 <(echo "$all_containers") <(echo "$ignore_containers"))

echo "Stopping docker containers..."

# Only run if pending_containers is not empty.
if [[ -n "$pending_containers" ]]; then
	# shellcheck disable=2086
	docker stop $pending_containers
else
	echo "No containers to stop."
fi

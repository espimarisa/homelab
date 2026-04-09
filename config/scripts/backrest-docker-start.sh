#!/bin/bash

stopped_containers=$(
	docker ps --quiet \
		--filter "status=exited" |
		sort
)

echo "Starting docker containers..."

# Only run if stopped_containers is not empty.
if [[ -n "$stopped_containers" ]]; then
	# shellcheck disable=2086
	docker start $stopped_containers
else
	echo "No containers to start."
fi

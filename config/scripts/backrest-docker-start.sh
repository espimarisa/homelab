#!/bin/bash

stopped_containers=$(
	docker ps --quiet \
		--filter "status=exited" |
		sort
)

echo "Starting docker containers..."

# shellcheck disable=2086
[[ -z $stopped_containers ]] ||
	docker start $stopped_containers

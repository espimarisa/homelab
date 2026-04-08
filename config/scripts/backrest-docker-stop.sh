#!/bin/bash

all_containers=$(
	docker ps --quiet |
		sort
)

# Containers to ignore.
ignore_containers=$(
	docker ps --quiet \
		--filter "name=backrest" \
		--filter "name=beszel" \
		--filter "name=caddy" \
		--filter "name=configarr" \
		--filter "name=dozzle" \
		--filter "name=socket-proxy" \
		--filter "name=unpackerr"

	sort
)

pending_containers=$(comm -23 <(echo "$all_containers") <(echo "$ignore_containers"))

# echo -e "\nall_containers:\n$(tput setaf 2)$all_containers\n$(tput sgr 0)"
# echo -e "\nignore_containers:\n$(tput setaf 2)$ignore_containers\n$(tput sgr 0)"
# echo -e "\npending_containers:\n$(tput setaf 4)$pending_containers\n$(tput sgr 0)"

echo "Stopping docker containers..."

docker stop "$pending_containers"

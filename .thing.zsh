#!/bin/env zsh
# vi: ts=4 sw=4 :

source ~/.config/hetzner.txt

req() {
	req="${1/\//}"; shift
	>&2 echo curl -Ss -H "Authorization: Bearer \$HETZNER_CLOUD" "https://api.hetzner.cloud/v1/$req" "$@"
	curl -Ss -H "Authorization: Bearer $HETZNER_CLOUD" "https://api.hetzner.cloud/v1/$req" "$@"
}

req.post() {
	req "$1" -H 'Content-Type: application/json' -X POST -d "`cat`" "$@[2,-1]"
}

req.get() {
	# json probably works too
	req="$1"
	args=()
	for arg in $@[2,-1]; do
		args+=(-d $arg)
	done
	# is '[@]' necessary?
	req "$req" -G "$args[@]"
}

server_name=create.zshlolol

await() {
	[ -z "$server" ] && \
		req.get /servers name=$server_name | jq '.servers[0].id' | read server
	while true; do
		req.get /servers/${server}/actions status=running | jq -e '.actions == []' >/dev/null && break
		#req.get /servers/${server} | { jq -e '.server.locked' || break }
		>&2 echo "SLEEP 1"
		sleep 1
	done
}

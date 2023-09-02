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

paginate() {
	>&2 echo "PAGINATE"
	content=( "`req.get "$@" per_page=100 page=1`" )
	#>&2 echo "$content" # temp

	jq -r '.meta.pagination | "\(.total_entries) \(.per_page)"' <<<$content[1] | read n per_page
	#>&2 echo "\$(( ( ( $n - 1 ) / $per_page ) ))"
	#>&2 echo $(( ( ( $n - 1 ) / $per_page ) ))
	for page in `seq $(( ( ( $n - 1 ) / $per_page ) ))`; do
		# when the arithmetic substitution returns 0
		[ $page -eq 0 ] && break
		let page+=1
		content+="`req.get "$@" per_page=$per_page page=$page`"
	done

	for json in $content[@]; do jq ".${1#/}[]" <<<$json; done | jq -s "{\"${1#/}\": .}"
	#jq ".${1#/}[]"<<<$content  | jq -s "{\"${1#/}\": .}" # this works too apparently
}

server_name=create.zshlolol

await() {
	if [ -z "$server" ]; then
		req.get /servers name=$server_name | jq '.servers[0].id' | read server
		[ "$server" = null ] && \
			{ >&2 echo "SERVER DOESNT EXIST. RETURN 2"; return 2 }
	fi
	while true; do
		req.get /servers/${server}/actions status=running | jq -e '.actions == []' >/dev/null && break
		#req.get /servers/${server} | { jq -e '.server.locked' || break }
		>&2 echo "SLEEP 1"
		sleep 1
	done
}

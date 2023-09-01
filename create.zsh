#!/bin/env zsh
set -e
# vi: ts=4 sw=4 :


source ./.thing.zsh


if req.get /servers name=$server_name | jq -e '.servers == []' >/dev/null; then
	>&2 echo "CREATING SERVER"
	#cat <<EOF
	req.post /servers <<EOF
	{
		"name": "$server_name", "server_type": "cax11", "location": "fsn1",
		"public_net": { "enable_ipv4": false,
		"ipv6": `req.get /primary_ips | jq '.primary_ips[] | select(.assignee_id == null) | select(.name | endswith("_private")) | .id'` },
		"networks": `req.get /networks name=yeaa | jq '.networks[].id' | jq -cs .`,
		"ssh_keys": `req.get /ssh_keys | jq '.ssh_keys[] | .id' | jq -cs .`,
		"image": `req.get /images status=available type=system architecture=arm | jq -c '.images[0].name'`
	}
EOF
fi

await

if req.get /servers name=$server_name | jq -e '.servers[0].iso == null' >/dev/null; then
	>&2 echo "ATTACHING ISO"
	await
	req.post /servers/${server}/actions/reboot <<<'' # zuvor stand diese zeile erst nach attach_iso
	await
	req.post /servers/${server}/actions/attach_iso <<EOF
	{ "iso": `req.get /isos architecture=arm | jq '.isos[] | select(.name | startswith("nixos")).id'` }
EOF
else
	>&2 echo "DETTACHING ISO"
	await
	req.post /servers/${server}/actions/reboot <<<''
	await
	req.post /servers/${server}/actions/detach_iso <<<''
fi

#POST /servers/{id}/actions/attach_iso

#TODO: add await for detecting when server is up, then add iso, await iso mount, force reboot, tell user to set root password and tell to run ./lol.zsh


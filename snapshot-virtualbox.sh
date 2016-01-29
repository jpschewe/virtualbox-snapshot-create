#!/bin/sh

debug() { ! "${log_debug-false}" || log "DEBUG: $*" >&2; }
log() { printf '%s\n' "$*"; }
warn() { log "WARNING: $*" >&2; }
error() { log "ERROR: $*" >&2; }
fatal() { error "$*"; exit 1; }
try() { "$@" || fatal "'$@' failed"; }

mydir=$(cd "$(dirname "$0")" && pwd -L) || fatal "Unable to determine script directory"

cleanup() {
    debug "In cleanup"
}
trap 'cleanup' INT TERM EXIT

# Creates a snapshot of each VM in VirtualBox. The name is the timestamp.

FORMATTED_DATE="$(date +%Y-%m-%d_%H-%M-%S_automatic)" || fatal "Cannot get formatted date"

VM_IDS=$(VBoxManage list vms | awk -F '"' '{print $3}') || fatal "Cannot get list of vms"

for vm in ${VM_IDS}
do

	COMMAND="VBoxManage snapshot ${vm} take ${FORMATTED_DATE} --live"
	debug ${COMMAND}
	try ${COMMAND}

	log "Created VirtualBox Snapshot ${FORMATTED_DATE} for VM ${vm}"
	log
done

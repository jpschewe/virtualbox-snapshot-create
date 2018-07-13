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

debug "Compacting virtualbox vdi images"

if [ "${log_debug}" != "false" ]; then 
    VBoxManage list hdds | grep -E "^UUID:" | awk -F " " '{print $2}' | xargs -L1 VBoxManage modifyhd --compact > /dev/null
else
    VBoxManage list hdds | grep -E "^UUID:" | awk -F " " '{print $2}' | xargs -L1 VBoxManage modifyhd --compact
fi

debug "Done compacting virtualbox vdi images"

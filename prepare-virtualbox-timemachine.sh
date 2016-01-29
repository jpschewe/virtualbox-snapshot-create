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

# Prepares virtualbox for time machine backups

usage ()
{
  fatal "usage: $0 [number of snapshots to keep]"
}

[ -n "$1" ] || usage

log "Preparing virtualbox for time machine backups"

"${mydir}"/snapshot-virtualbox.sh
log

"${mydir}"/delete-old-snapshots.sh $1
log

#"${mydir}"/compact-virtualbox-vdis.sh
#log "\n\n"

log "Done preparing virtualbox for time machine backups"

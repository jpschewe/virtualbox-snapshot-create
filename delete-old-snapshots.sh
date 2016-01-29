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

# Deletes old snapshots

usage ()
{
  fatal "usage: $0 [number of snapshots to keep]"
}

[ -n "$1" ] || usage

num_to_keep=$1
VM_IDS=$(VBoxManage list vms | awk -F '"' '{print $3}') || fatal "Cannot get list of vms"

for vm in ${VM_IDS}
do
	log "Deleting all but latest ${num_to_keep} automatic snapshots from ${vm}"

  snapshots=$(VBoxManage snapshot "${vm}" list | \
    grep "_automatic" | \
    awk -F "UUID: " '{print $2}' | \
    awk -F ")" '{print $1}') || fatal "Cannot get list of snapshots for ${vm}"

  # count how many to delete since we want to delete them from the front of
  # the list, but need to know how many to keep
  num_to_delete=0
  num_kept=0
  for snap in ${snapshots}; do
    if [ ${num_kept} -lt ${num_to_keep} ]; then
      num_kept=$(expr ${num_kept} + 1)
    else
      num_to_delete=$(expr ${num_to_delete} + 1)
    fi
  done

  # actually delete snapshots
  num_deleted=0
  for snap in ${snapshots}; do
    if [ ${num_deleted} -lt ${num_to_delete} ]; then
      num_deleted=$(expr ${num_deleted} + 1)
      debug "Deleting ${snap}"
      try VBoxManage snapshot ${vm} delete ${snap}
    else
      debug "Keeping ${snap}"
    fi
  done

	log "Finished snapshot deletion of ${vm}"
	log
done

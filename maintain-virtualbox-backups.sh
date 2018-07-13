#!/bin/sh

# keep a number of backups of Virtualbox VMs

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

usage ()
{
    fatal "usage: $0 <min snapshots to keep> <max snapshots to keep>"
}

[ -n "$1" ] || usage
[ -n "$2" ] || usage

min_snapshots=$1
max_snapshots=$2

FORMATTED_DATE="$(date +%Y-%m-%d_%H-%M-%S_automatic)" || fatal "Cannot get formatted date"

VM_IDS=$(VBoxManage list vms | awk -F '"' '{print $3}') || fatal "Cannot get list of vms"

compact=0
for vm in ${VM_IDS}
do

    vm_name=$(VBoxManage list vms | grep ${vm} | awk -F '"' '{print $2}') || fatal "Cannot name for vm ${vm}"
    
    COMMAND="VBoxManage snapshot ${vm} take ${FORMATTED_DATE} --live"
    debug ${COMMAND}
    output=$( ${COMMAND} 2>&1) || fatal "Error creating snapshot of ${vm_name}"
    debug ${output}

    debug "Created VirtualBox Snapshot ${FORMATTED_DATE} for VM ${vm_name}"
    debug

    snapshots=$(VBoxManage snapshot "${vm}" list | \
                    grep "_automatic" | \
                    awk -F "UUID: " '{print $2}' | \
                    awk -F ")" '{print $1}') || fatal "Cannot get list of snapshots for ${vm} ${vm_name}"

    # count how many to delete since we want to delete them from the front of
    # the list, but need to know how many to keep
    num_to_delete=0
    num_kept=0
    total_snapshots=0
    for snap in ${snapshots}; do
        total_snapshots=$(expr ${total_snapshots} + 1)
        
        if [ ${num_kept} -lt ${min_snapshots} ]; then
            num_kept=$(expr ${num_kept} + 1)
        else
            num_to_delete=$(expr ${num_to_delete} + 1)
        fi
    done
    debug "Found ${total_snapshots} snapshots for ${vm_name}"

    if [ ${total_snapshots} -gt ${max_snapshots} ]; then
        # actually delete snapshots
        debug "Deleting ${num_to_delete} snapshots from ${vm_name}"
        
        num_deleted=0
        for snap in ${snapshots}; do
            if [ ${num_deleted} -lt ${num_to_delete} ]; then
                num_deleted=$(expr ${num_deleted} + 1)
                debug "Deleting ${snap}"
                delete_output=$(VBoxManage snapshot ${vm} delete ${snap} 2>&1) || fatal "Error deleting ${snap} from ${vm_name}"
                debug ${delete_output}
            else
                debug "Keeping ${snap}"
            fi
        done

        # compact if snapshots were deleted
        compact=1
        debug "Finished snapshot deletion of snapshots for ${vm_name}"

        
    fi
    debug
    
done

if [ ${compact} -gt 0 ]; then
    debug "Compacting virtualbox vdi images"

    compact_output=$(VBoxManage list hdds | grep -E "^UUID:" | awk -F " " '{print $2}' | xargs -L1 VBoxManage modifyhd --compact 2>&1)
    debug ${compact_output}

    debug "Done compacting virtualbox vdi images"
fi    

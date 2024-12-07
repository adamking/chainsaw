#!/usr/bin/env bash

set -e # exit on failure
# set -x # echo commands

# Configurable process and CPU threshold
PROCESS_NAME=${1:-kswapd0}
CPU_THRESHOLD=${2:-90}

# Get CPU usage of the specified process
cpu=$(/usr/bin/printf %.0f $(/bin/ps -o pcpu= -C "$PROCESS_NAME"))

if [[ -n $cpu ]] && (( cpu >= CPU_THRESHOLD )); then
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
    echo "$(date): $$ $0: cache dropped (Process: $PROCESS_NAME CPU=$cpu%)" | sudo tee -a /var/log/drop_caches.log
fi

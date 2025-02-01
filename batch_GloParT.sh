#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "script's dir: $SCRIPT_DIR"

if [ -z $1 ]; then
    echo "Usage: source batch_GloParT.sh <step> [mode:data/mc/both]"
    return
fi

step=$1
# need to specify step
if [ -z $step ]; then
    echo "Please specify step"
    return
fi
mode=${2:-both}

case $mode in
    data|mc|both) ;;
    *)
        echo "Invalid mode: $mode. Using default: both"
        mode="both"
        ;;
esac

process_mode() {
    local current_mode=$1
    local script="${SCRIPT_DIR}/condor_GloParT.sh"
    local eras=("2022" "2022EE" "2023" "2023BPix")

    for era in "${eras[@]}"; do
        echo "Processing $current_mode for era $era, step $step"
        bash $script $era $step $current_mode
    done
}

if [ "$mode" == "both" ]; then
    process_mode "data"
    process_mode "mc"
else
    process_mode "$mode"
fi
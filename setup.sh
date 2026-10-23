#!/usr/bin/env bash
set -euo pipefail
source common.sh

BASE_PATH=$PWD
BOOTSTRAP_STAGES=4

# Call the function to populate the global dictionary
get_os_version

# Access the dictionary keys directly
prettyprint 0 "Detected OS: ${OS_INFO[NAME]} (${OS_INFO[ID]})"
prettyprint 0 "Version: ${OS_INFO[VERSION_ID]}"

for ((stage=0; stage<=BOOTSTRAP_STAGES; stage++)); do
    completeDir="$BASE_PATH/$(resolve_stage_dir "$stage")"
    currentDir=$(basename "$completeDir")
    prettyprint 0 "Processing stage $currentDir ($completeDir)"
    tree $completeDir
done

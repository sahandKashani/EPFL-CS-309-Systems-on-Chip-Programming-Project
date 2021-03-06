#!/bin/bash -x

# make sure to be in the same directory as this script
script_dir_abs=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${script_dir_abs}"

rm -rf sw/hps/application/hw_headers

# create target directory if not present
mkdir -p sw/hps/application/hw_headers

sopc-create-header-files \
hw/quartus/soc_system.sopcinfo \
--output-dir sw/hps/application/hw_headers

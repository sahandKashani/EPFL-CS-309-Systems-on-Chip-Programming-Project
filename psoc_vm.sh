#!/bin/bash -x

## Automatic
if [ "$#" -ne 1 ]; then
    echo "Usage: ./psoc_vm.sh <gaspar>"
    exit 1
fi
gaspar="$1"
cd "/mnt/xubuntu/Xubuntu 16.04/"
cp "Xubuntu 16.04.vbox" "${gaspar}.vbox"
virtualbox "/mnt/xubuntu/Xubuntu 16.04/${gaspar}.vbox"
exit 0

## Manual
# 1) Copy "/mnt/xubuntu/Xubuntu 16.04/Xubuntu 16.04.vbox" to "/mnt/xubuntu/Xubuntu 16.04/<gaspar>.vbox". For example, user "skashani" would rename the file to "/mnt/xubuntu/Xubuntu 16.04/skashani.vbox"
# 2) Open VirtualBox
# 3) In the menu bar, go to "Machine > Add"
# 4) Choose "/mnt/xubuntu/Xubuntu 16.04/<gaspar>.vbox"
# 5) Launch the virtual machine
#      user          = psoc
#      password      = 1234
#      root user     = root
#      root password = 1234


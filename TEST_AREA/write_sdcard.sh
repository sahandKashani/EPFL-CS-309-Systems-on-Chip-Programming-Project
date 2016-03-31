#!/bin/bash

# make sure to be in the same directory as this script
script_dir_abs=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${script_dir_abs}"

# partitioning the sdcard
    # sudo fdisk /dev/sdx
    # use the following commands
        # n p 3 <default> 4095  t 3 a2 (2048 is default first sector)
        # n p 1 <default> +32M  t 1  b (4096 is default first sector)
        # n p 2 <default> +512M t 2 83 (69632 is default first sector)
        # w
    # filesystem
        # sudo mkfs.msdos /dev/sdx1
        # sudo mkfs.ext3 /dev/sdx2
    # result
        # custom
            # Device     Boot Start     End Sectors  Size Id Type
            # /dev/sdb1        4096   69631   65536   32M  b W95 FAT32
            # /dev/sdb2       69632 1118207 1048576  512M 83 Linux
            # /dev/sdb3        2048    4095    2048    1M a2 unknown

# writing the sdcard
    # write the preloader and u-boot in the BINARY partition
        # dd if=preloader_with_header.img of=/dev/sdx3 bs=64k seek=0
        # sudo dd if=u-boot.img of=/dev/sdx3 bs=64K seek=4

    # write the linux kernel, device tree, and FPGA rbf to the FAT32 partition
        # sudo mount /dev/sdx1 /media/sdcard
        # sudo cp zImage /media/sdcard
        # sudo cp soc_system.dtb /media/sdcard
        # sudo cp soc_system.rbf /media/sdcard
        # sudo unmount /media/sdcard
        # sudo sync

    # write the rootfs to the LINUX partition
        # sudo mount /dev/sdx2 /media/sdcard
        # sudo cp rootfs /media/sdcard
        # sudo umount /media/sdcard
        # sudo sync

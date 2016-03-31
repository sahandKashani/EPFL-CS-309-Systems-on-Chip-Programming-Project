#!/bin/bash

usage() {
    cat <<EOF
===================================================================
usage: compile.sh [sdcard_device]

positional arguments:
    sdcard_device    path to sdcard device file    [ex: "/dev/sdb"]
===================================================================
EOF
}

# make sure to be in the same directory as this script
script_dir_abs=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${script_dir_abs}"

# constants
sdcard_dev_abs="$(readlink -e "${1}")"

quartus_dir="$(readlink -m "hw/quartus")"
quartus_project_name="$(basename "$(find "${quartus_dir}" -name "*.qpf")" .qpf)"
quartus_sof_file="$(readlink -m "${quartus_dir}/output_files/${quartus_project_name}.sof")"

preloader_dir="$(readlink -m "sw/hps/preloader")"
preloader_settings_dir="$(readlink -m "${quartus_dir}/hps_isw_handoff/soc_system_hps_0")"
preloader_settings_file="$(readlink -m "${preloader_dir}/settings.bsp")"
preloader_source_tgz_file="$(readlink -m "${SOCEDS_DEST_ROOT}/host_tools/altera/preloader/uboot-socfpga.tar.gz")"

uboot_dir="$(readlink -m "${preloader_dir}/uboot-socfpga")"
uboot_script_file="$(readlink -m "${uboot_dir}/u-boot.script")"
uboot_img_file="$(readlink -m "${uboot_dir}/u-boot.img")"

linux_src_dir="$(readlink -m "sw/hps/linux")"
linux_zImage_file="$(readlink -m "${linux_src_dir}/arch/arm/boot/zImage")"
linux_dtb_file="$(readlink -m "${linux_src_dir}/arch/arm/boot/dts/socfpga_cyclone5_de0_sockit.dtb")"

rootfs_dir="$(readlink -m sdcard/rootfs)"
rootfs_src_tgz_file="$(readlink -m "sdcard/ubuntu-core-14.04.4-core-armhf.tar.gz")"

sdcard_fat32_dir="$(readlink -m "sdcard/fat32")"
sdcard_fat32_rbf_file="$(readlink -m "${sdcard_fat32_dir}/socfpga.rbf")"
sdcard_fat32_uboot_scr_file="$(readlink -m "${sdcard_fat32_dir}/u-boot.scr")"
sdcard_fat32_uboot_img_file="$(readlink -m "${sdcard_fat32_dir}/u-boot.img")"
sdcard_fat32_zImage_file="$(readlink -m "${sdcard_fat32_dir}/zImage")"
sdcard_fat32_dtb_file="$(readlink -m "${sdcard_fat32_dir}/socfpga.dtb")"

sdcard_ext4_rootfs_tgz_file="$(readlink -m "sdcard/rootfs.tar.gz")"

compile_quartus_project() {
    pushd "${quartus_dir}"

    # Analysis and synthesis
    quartus_map "${quartus_project_name}"

    # Execute HPS DDR3 pin assignment TCL script
    # it is normal for the following script to report an error, but it was sucessfully executed
    ddr3_pin_assignment_script="$(find . -name "hps_sdram_p0_pin_assignments.tcl")"
    quartus_sta -t "${ddr3_pin_assignment_script}" "${quartus_project_name}"

    # Fitter
    quartus_fit "${quartus_project_name}"

    # Assembler
    quartus_asm "${quartus_project_name}"

    popd

    quartus_cpf -c "${quartus_sof_file}" "${sdcard_fat32_rbf_file}"
}

compile_preloader_and_uboot() {
    bsp-create-settings \
    --bsp-dir "${preloader_dir}" \
    --preloader-settings-dir "${preloader_settings_dir}" \
    --settings "${preloader_settings_file}" \
    --type spl \
    --set spl.CROSS_COMPILE "arm-altera-eabi-" \
    --set spl.PRELOADER_TGZ "${preloader_source_tgz_file}" \
    --set spl.boot.BOOTROM_HANDSHAKE_CFGIO "1" \
    --set spl.boot.BOOT_FROM_NAND "0" \
    --set spl.boot.BOOT_FROM_QSPI "0" \
    --set spl.boot.BOOT_FROM_RAM "0" \
    --set spl.boot.BOOT_FROM_SDMMC "1" \
    --set spl.boot.CHECKSUM_NEXT_IMAGE "1" \
    --set spl.boot.EXE_ON_FPGA "0" \
    --set spl.boot.FAT_BOOT_PARTITION "1" \
    --set spl.boot.FAT_LOAD_PAYLOAD_NAME "$(basename "${uboot_img_file}")" \
    --set spl.boot.FAT_SUPPORT "1" \
    --set spl.boot.FPGA_DATA_BASE "0xffff0000" \
    --set spl.boot.FPGA_DATA_MAX_SIZE "0x10000" \
    --set spl.boot.FPGA_MAX_SIZE "0x10000" \
    --set spl.boot.NAND_NEXT_BOOT_IMAGE "0xc0000" \
    --set spl.boot.QSPI_NEXT_BOOT_IMAGE "0x60000" \
    --set spl.boot.RAMBOOT_PLLRESET "1" \
    --set spl.boot.SDMMC_NEXT_BOOT_IMAGE "0x40000" \
    --set spl.boot.SDRAM_SCRUBBING "0" \
    --set spl.boot.SDRAM_SCRUB_BOOT_REGION_END "0x2000000" \
    --set spl.boot.SDRAM_SCRUB_BOOT_REGION_START "0x1000000" \
    --set spl.boot.SDRAM_SCRUB_REMAIN_REGION "1" \
    --set spl.boot.STATE_REG_ENABLE "1" \
    --set spl.boot.WARMRST_SKIP_CFGIO "1" \
    --set spl.boot.WATCHDOG_ENABLE "1" \
    --set spl.debug.DEBUG_MEMORY_ADDR "0xfffffd00" \
    --set spl.debug.DEBUG_MEMORY_SIZE "0x200" \
    --set spl.debug.DEBUG_MEMORY_WRITE "0" \
    --set spl.debug.HARDWARE_DIAGNOSTIC "0" \
    --set spl.debug.SEMIHOSTING "0" \
    --set spl.debug.SKIP_SDRAM "0" \
    --set spl.performance.SERIAL_SUPPORT "1" \
    --set spl.reset_assert.DMA "0" \
    --set spl.reset_assert.GPIO0 "0" \
    --set spl.reset_assert.GPIO1 "0" \
    --set spl.reset_assert.GPIO2 "0" \
    --set spl.reset_assert.L4WD1 "0" \
    --set spl.reset_assert.OSC1TIMER1 "0" \
    --set spl.reset_assert.SDR "0" \
    --set spl.reset_assert.SPTIMER0 "0" \
    --set spl.reset_assert.SPTIMER1 "0" \
    --set spl.warm_reset_handshake.ETR "1" \
    --set spl.warm_reset_handshake.FPGA "1" \
    --set spl.warm_reset_handshake.SDRAM "0"

    bsp-generate-files \
    --bsp-dir "${preloader_dir}" \
    --settings "${preloader_settings_file}"

    make -C "${preloader_dir}"
    make -C "${preloader_dir}" uboot

    cp "${uboot_img_file}" "${sdcard_fat32_uboot_img_file}"

    cat <<EOF > "${uboot_script_file}"
# Load rbf from FAT partition into memory
fatload mmc 0:1 \$fpgadata $(basename ${sdcard_fat32_rbf_file});

# Program FPGA
fpga load 0 \$fpgadata \$filesize;

echo --- Setting Env variables ---

# Set the devicetree image to be used
setenv fdtimage $(basename ${sdcard_fat32_dtb_file});

# Set the kernel image to be used
setenv bootimage $(basename ${sdcard_fat32_zImage_file});

setenv mmcboot 'setenv bootargs mem=768M console=ttyS0,115200 root=\${mmcroot} rw rootwait;bootz \${loadaddr} - \${fdtaddr}'

# enable the FPGA 2 HPS and HPS 2 FPGA bridges
run bridge_enable_handoff;

echo --- Booting Linux ---

# mmcload & mmcboot are scripts included in the default socfpga uboot environment
# it loads the devicetree image and kernel to memory
run mmcload;

# mmcboot sets the bootargs and boots the kernel with the dtb specified above
run mmcboot;
EOF

    # compile uboot script to binary form
    mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "${quartus_project_name}" -d "${uboot_script_file}" "${sdcard_fat32_uboot_scr_file}"
}

compile_linux() {
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-

    make -C "${linux_src_dir}" socfpga_defconfig
    make -C "${linux_src_dir}" zImage
    make -C "${linux_src_dir}" socfpga_cyclone5_de0_sockit.dtb

    cp "${linux_zImage_file}" "${sdcard_fat32_zImage_file}"
    cp "${linux_dtb_file}" "${sdcard_fat32_dtb_file}"
}

create_rootfs() {
    # extract ubuntu core rootfs
    pushd "${rootfs_dir}"
    sudo tar -xzpf "${rootfs_src_tgz_file}"
    popd

    # mount directories needed for chroot environment to work
    sudo mount -o bind "/dev" "${rootfs_dir}/dev"
    sudo mount -t sysfs "/sys" "${rootfs_dir}/sys"
    sudo mount -t proc "/proc" "${rootfs_dir}/proc"

    # chroot environment needs to know what is mounted, so we copy over
    # /proc/mounts from the host for this temporarily
    sudo cp "/proc/mounts" "${rootfs_dir}/etc/mtab"

    # chroot environment needs network connectivity, so we copy /etc/resolv.conf
    # so DNS name resolution can occur
    sudo cp "/etc/resolv.conf" "${rootfs_dir}/etc/resolv.conf"

    # the ubuntu core image is for armhf, not x86, so we need qemu to actually
    # emulate the chroot (x86 cannot execute bash included in the rootfs, since
    # it is for armhf)
    sudo cp "/usr/bin/qemu-arm-static" "${rootfs_dir}/usr/bin/"

    # perform chroot and configure rootfs through script
    sudo chroot "${rootfs_dir}" ./rootfs_config.sh

    # unmount host directories temporarily used for chroot
    sudo umount "${rootfs_dir}/dev"
    sudo umount "${rootfs_dir}/sys"
    sudo umount "${rootfs_dir}/proc"

    # create archive of updated rootfs
    pushd "${rootfs_dir}"
    sudo tar -czpf "${sdcard_ext4_rootfs_tgz_file}" . --exclude="rootfs_config.sh"
    popd
}

write_sdcard() {
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

    if [ -z "${sdcard_dev_abs}" ]; then
        echo "Error: could not find sdcard at \"${sdcard_dev_abs}\""
        exit 1
    fi

    # writing the sdcard
        # write the preloader
            # sudo dd if=sw/hps/preloader-mkpimage.bin of=/dev/sdx3 bs=64k seek=0

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
}

# compile_quartus_project
# compile_preloader_and_uboot
# compile_linux
create_rootfs
# write_sdcard

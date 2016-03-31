#!/bin/bash

# make sure to be in the same directory as this script
script_dir_abs=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "${script_dir_abs}"

# constants
linux_src_dir_abs="$(readlink -m "${1}")"
quartus_project_file="$(basename "$(find . -name "*.qpf")")"
quartus_project_name="${quartus_project_file%.*}"

echoerr() {
    cat <<< "${@}" 1>&2;
}

usage() {
    cat <<EOF
=================================================================
usage: compile.sh linux_src_dir

positional arguments:
    linux_src_dir    path to linux source tree    [ex: "~/linux"]
=================================================================
EOF
}

check_args() {
    if [ ! -d "${linux_src_dir_abs}" ]; then
        usage
        echoerr "Error: could not find \"${linux_src_dir_abs}\""
        exit 1
    fi
}

compile_quartus_project() {
    pushd "hw/quartus"

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

    quartus_cpf -c "hw/quartus/output_files/${quartus_project_name}.sof" "sdcard/fat32/socfpga.rbf"
}

compile_preloader_and_uboot() {
    bsp-create-settings \
    --bsp-dir "sw/hps/preloader" \
    --preloader-settings-dir "hw/quartus/hps_isw_handoff/soc_system_hps_0" \
    --settings "sw/hps/preloader/settings.bsp" \
    --type spl \
    --set spl.CROSS_COMPILE "arm-altera-eabi-" \
    --set spl.PRELOADER_TGZ "${SOCEDS_DEST_ROOT}/host_tools/altera/preloader/uboot-socfpga.tar.gz" \
    --set spl.boot.BOOTROM_HANDSHAKE_CFGIO "1" \
    --set spl.boot.BOOT_FROM_NAND "0" \
    --set spl.boot.BOOT_FROM_QSPI "0" \
    --set spl.boot.BOOT_FROM_RAM "0" \
    --set spl.boot.BOOT_FROM_SDMMC "1" \
    --set spl.boot.CHECKSUM_NEXT_IMAGE "1" \
    --set spl.boot.EXE_ON_FPGA "0" \
    --set spl.boot.FAT_BOOT_PARTITION "1" \
    --set spl.boot.FAT_LOAD_PAYLOAD_NAME "u-boot.img" \
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
    --bsp-dir "sw/hps/preloader" \
    --settings "sw/hps/preloader/settings.bsp"

    make -C "sw/hps/preloader"
    make -C "sw/hps/preloader" uboot

    cat <<EOF > "sw/hps/preloader/uboot-socfpga/u-boot.script"
# Load rbf from FAT partition into memory
fatload mmc 0:1 \$fpgadata socfpga.rbf;

# Program FPGA
fpga load 0 \$fpgadata \$filesize;

echo --- Setting Env variables ---

# Set the devicetree image to be used
setenv fdtimage socfpga.dtb;

# Set the kernel image to be used
setenv bootimage zImage;

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

    mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "${quartus_project_name}" -d "sw/hps/preloader/uboot-socfpga/u-boot.script" "sdcard/fat32/u-boot.scr"
    cp "sw/hps/preloader/uboot-socfpga/u-boot.img" "sdcard/fat32/"
}

compile_linux() {
    export ARCH=arm
    export CROSS_COMPILE=arm-linux-gnueabihf-

    make -C "${linux_src_dir_abs}" socfpga_defconfig
    make -C "${linux_src_dir_abs}" zImage
    make -C "${linux_src_dir_abs}" socfpga_cyclone5_de0_sockit.dtb

    cp "${linux_src_dir_abs}/arch/arm/boot/zImage" "sdcard/fat32/zImage"
    cp "${linux_src_dir_abs}/arch/arm/boot/dts/socfpga_cyclone5_de0_sockit.dtb" "sdcard/fat32/socfpga.dtb"
}

create_rootfs() {
    pushd "sdcard"
        # extract ubuntu core rootfs
        sudo tar -xzvpf ubuntu-core-14.04.4-core-armhf.tar.gz -C ext4

        # mount directories needed for chroot environment to work
        sudo mount -o bind /dev ext4/dev
        sudo mount -o bind /dev/pts ext4/dev/pts
        sudo mount -t sysfs /sys ext4/sys
        sudo mount -t proc /proc ext4/proc

        # chroot environment needs to know what is mounted, so we copy over
        # /proc/mounts from the host for this temporarily
        sudo cp /proc/mounts ext4/etc/mtab

        # chroot environment needs network connectivity, so we copy /etc/resolv.conf
        # so DNS name resolution can occur
        sudo cp /etc/resolv.conf ext4/etc/resolv.conf

        # the ubuntu core image is for armhf, not x86, so we need qemu to actually
        # emulate the chroot (x86 cannot execute bash included in the rootfs, since
        # it is for armhf)
        sudo cp /usr/bin/qemu-arm-static ext4/usr/bin/

        # perform chroot and configure rootfs through script
        sudo chroot ext4 ./rootfs_config.sh

        # unmount host directories temporarily used for chroot
        sudo umount -lf ext4/dev
        sudo umount -lf ext4/dev/pts
        sudo umount -lf ext4/sys
        sudo umount -lf ext4/proc
    popd
}

check_args
# compile_quartus_project
# compile_preloader_and_uboot
# compile_linux
create_rootfs

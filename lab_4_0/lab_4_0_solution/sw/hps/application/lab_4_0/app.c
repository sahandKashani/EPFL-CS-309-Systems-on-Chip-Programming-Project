#include <errno.h>
#include <fcntl.h>
#include <socal/hps.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

#include "pantilt/pantilt.h"
#include "joysticks/joysticks.h"
#include "lepton/lepton.h"

#include "../hw_headers/hps_0.h"

#define SLEEP_DURATION_NS (1000000)

// Servos
#define PANTILT_PWM_V_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_V_MIN_DUTY_CYCLE_US + PANTILT_PWM_V_MAX_DUTY_CYCLE_US) / 2)
#define PANTILT_PWM_H_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_H_MIN_DUTY_CYCLE_US + PANTILT_PWM_H_MAX_DUTY_CYCLE_US) / 2)

// Right joystick horizontal threshold for triggering lepton capture
#define LEPTON_RIGHT_JOYSTICK_HORIZONTAL_TRIGGER_THRESHOLD ((uint32_t) (0.8 * JOYSTICKS_MAX_VALUE))

size_t h2f_lw_axi_master_span = ALT_LWFPGASLVS_UB_ADDR - ALT_LWFPGASLVS_LB_ADDR + 1;
size_t h2f_lw_axi_master_ofst = ALT_LWFPGASLVS_OFST;

uint32_t interpolate(uint32_t input,
                     uint32_t input_lower_bound,
                     uint32_t input_upper_bound,
                     uint32_t output_lower_bound,
                     uint32_t output_upper_bound) {
    double slope = 1.0 * (output_upper_bound - output_lower_bound) / (input_upper_bound - input_lower_bound);
    return output_lower_bound + (uint32_t) (slope * (input - input_lower_bound));
}

void handle_pantilt(pantilt_dev *pantilt, joysticks_dev *joysticks) {
    // Read LEFT joystick position
    uint32_t left_joystick_v = joysticks_read_left_vertical(joysticks);
    uint32_t left_joystick_h = joysticks_read_left_horizontal(joysticks);

    // Interpolate LEFT joystick position between SERVO_x_MIN_DUTY_CYCLE_US
    // and SERVO_x_MAX_DUTY_CYCLE_US
    uint32_t pantilt_v_duty_us = interpolate(left_joystick_v,
                                            JOYSTICKS_MIN_VALUE,
                                            JOYSTICKS_MAX_VALUE,
                                            PANTILT_PWM_V_MIN_DUTY_CYCLE_US,
                                            PANTILT_PWM_V_MAX_DUTY_CYCLE_US);
    uint32_t pantilt_h_duty_us = interpolate(left_joystick_h,
                                            JOYSTICKS_MIN_VALUE,
                                            JOYSTICKS_MAX_VALUE,
                                            PANTILT_PWM_H_MIN_DUTY_CYCLE_US,
                                            PANTILT_PWM_H_MAX_DUTY_CYCLE_US);

    // Configure servos with interpolated joystick values
    pantilt_configure_vertical(pantilt, pantilt_v_duty_us);
    pantilt_configure_horizontal(pantilt, pantilt_h_duty_us);
}

void handle_lepton(joysticks_dev *joysticks, lepton_dev *lepton) {
    // Read RIGHT joystick position
    uint32_t right_joystick_h = joysticks_read_right_horizontal(joysticks);

    if (right_joystick_h > LEPTON_RIGHT_JOYSTICK_HORIZONTAL_TRIGGER_THRESHOLD) {
        bool capture_error = false;
        do {
            lepton_start_capture(lepton);
            lepton_wait_until_eof(lepton);
            capture_error = lepton_error_check(lepton);
        } while (capture_error);

        printf("Thermal image written to internal memory!\n");

        // Save the adjusted (rescaled) buffer to a file.
        lepton_save_capture(&lepton, true, "/home/output.pgm");

        printf("Thermal image written to host filesystem!\n");
    }
}

int open_physical_memory_device() {
    // We need to access the system's physical memory so we can map it to user
    // space. We will use the /dev/mem file to do this. /dev/mem is a character
    // device file that is an image of the main memory of the computer. Byte
    // addresses in /dev/mem are interpreted as physical memory addresses.
    // Remember that you need to execute this program as ROOT in order to have
    // access to /dev/mem.

    int fd_dev_mem = open("/dev/mem", O_RDWR | O_SYNC);

    if(fd_dev_mem  == -1) {
        printf("ERROR: could not open \"/dev/mem\".\n");
        printf("    errno = %s\n", strerror(errno));
        exit(EXIT_FAILURE);
    }

    return fd_dev_mem;
}

void close_physical_memory_device(int fd_dev_mem) {
    close(fd_dev_mem);
}

void *mmap_h2f_lw_axi_master(int fd_dev_mem) {
    // Use mmap() to map the address space related to the fpga peripherals into
    // user space so we can interact with them.

    // The fpga peripherals are connected to the h2f_lw_axi_master, so their
    // base addresses is calculated from that of the h2f_lw_axi_master.

    // IMPORTANT: If you try to only mmap the fpga peripherals, it is possible
    // for the operation to fail, and you will get "Invalid argument" as errno.
    // The mmap() manual page says that you can only map a file from an offset
    // which is a multiple of the system's page size. Thankfully, the
    // h2f_lw_axi_master bus can be found at address 0xFF200000 which is a
    // multiple of the system's page size (0x1000). Additionally, we will map
    // the complete address range of the h2f_lw_axi_master into user space, as
    // it is only 2MB in size, so it is reasonable.

    void *h2f_lw_axi_master = mmap(NULL, h2f_lw_axi_master_span, PROT_READ | PROT_WRITE, MAP_SHARED, fd_dev_mem, h2f_lw_axi_master_ofst);

    if (h2f_lw_axi_master == MAP_FAILED) {
        printf("Error: h2f_lw_axi_master mmap() failed.\n");
        printf("    errno = %s\n", strerror(errno));
        close(fd_dev_mem);
        exit(EXIT_FAILURE);
    }

    return h2f_lw_axi_master;
}

void munmap_h2f_lw_axi_master(int fd_dev_mem, void *h2f_lw_axi_master) {
    if (munmap(h2f_lw_axi_master, h2f_lw_axi_master_span) != 0) {
        printf("Error: h2f_lw_axi_master munmap() failed\n");
        printf("    errno = %s\n", strerror(errno));
        close(fd_dev_mem);
        exit(EXIT_FAILURE);
    }
}

int main(void) {
    // physical memory file descriptor
    int fd_dev_mem = open_physical_memory_device();

    // lightweight HPS-to-FPGA bus base address (after mmap-ing to user space)
    void *h2f_lw_axi_master = mmap_h2f_lw_axi_master(fd_dev_mem);

    // FPGA peripheral base addresses (after mmap-ing to user space).
    void *pwm_0_base = (void *) ((uintptr_t) h2f_lw_axi_master + PWM_0_BASE);
    void *pwm_1_base = (void *) ((uintptr_t) h2f_lw_axi_master + PWM_1_BASE);
    void *mcp3204_base = (void *) ((uintptr_t) h2f_lw_axi_master + MCP3204_0_BASE);
    void *lepton_base = (void *) ((uintptr_t) h2f_lw_axi_master + LEPTON_0_BASE);

    // Hardware control structures
    pantilt_dev pantilt = pantilt_inst(pwm_0_base, pwm_1_base);
    joysticks_dev joysticks = joysticks_inst(mcp3204_base);
    lepton_dev lepton = lepton_inst(lepton_base);

    // Initialize hardware
    pantilt_init(&pantilt);
    joysticks_init(&joysticks);
    lepton_init(&lepton);

    // Center servos.
    pantilt_configure_vertical(&pantilt, PANTILT_PWM_V_CENTER_DUTY_CYCLE_US);
    pantilt_configure_horizontal(&pantilt, PANTILT_PWM_H_CENTER_DUTY_CYCLE_US);
    pantilt_start_vertical(&pantilt);
    pantilt_start_horizontal(&pantilt);

    // Control servos with LEFT joystick, capture thermal image with RIGHT joystick.
    while (true) {
        handle_pantilt(&pantilt, &joysticks);
        handle_lepton(&joysticks, &lepton);

        // Sleep for a while to avoid excessive sensitivity
        struct timespec requested_time;
        struct timespec remaining_time;
        requested_time.tv_sec = 0;
        requested_time.tv_nsec = SLEEP_DURATION_NS;
        nanosleep(&requested_time, &remaining_time);
    }

    munmap_h2f_lw_axi_master(fd_dev_mem, h2f_lw_axi_master);
    close_physical_memory_device(fd_dev_mem);

    return EXIT_SUCCESS;
}

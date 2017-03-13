#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "pantilt/pantilt.h"
#include "joysticks/joysticks.h"
#include "system.h"

#define SLEEP_DURATION_US            (100000)   // 100  ms

// Servos
#define PANTILT_PWM_V_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_V_MIN_DUTY_CYCLE_US + PANTILT_PWM_V_MAX_DUTY_CYCLE_US) / 2)
#define PANTILT_PWM_H_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_H_MIN_DUTY_CYCLE_US + PANTILT_PWM_H_MAX_DUTY_CYCLE_US) / 2)

uint32_t interpolate(uint32_t input,
                     uint32_t input_lower_bound,
                     uint32_t input_upper_bound,
                     uint32_t output_lower_bound,
                     uint32_t output_upper_bound) {
    /* TODO : complete this function */
}

int main(void) {
    // Hardware control structures
    pantilt_dev pantilt = pantilt_inst((void *) PWM_0_BASE, (void *) PWM_1_BASE);
    joysticks_dev joysticks = joysticks_inst((void *) MCP3204_0_BASE);

    // Initialize hardware
    pantilt_init(&pantilt);
    joysticks_init(&joysticks);

    // Center servos.
    pantilt_configure_vertical(&pantilt, PANTILT_PWM_V_CENTER_DUTY_CYCLE_US);
    pantilt_configure_horizontal(&pantilt, PANTILT_PWM_H_CENTER_DUTY_CYCLE_US);
    pantilt_start_vertical(&pantilt);
    pantilt_start_horizontal(&pantilt);

    // Control servos with joystick.
    while (true) {
        // Read LEFT joystick position
        uint32_t left_joystick_v = joysticks_read_left_vertical(&joysticks);
        uint32_t left_joystick_h = joysticks_read_left_horizontal(&joysticks);

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
        pantilt_configure_vertical(&pantilt, pantilt_v_duty_us);
        pantilt_configure_horizontal(&pantilt, pantilt_h_duty_us);

        // Sleep for a while to avoid excessive sensitivity
        usleep(SLEEP_DURATION_US);
    }

    return EXIT_SUCCESS;
}

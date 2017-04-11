#include <socal/hps.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "pantilt/pantilt.h"
#include "joysticks/joysticks.h"
#include "lepton/lepton.h"

/* TODO : include suitable header files to have access to peripheral addresses. */
#include ...

#define SLEEP_DURATION (1000)

// Servos
#define PANTILT_PWM_V_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_V_MIN_DUTY_CYCLE_US + PANTILT_PWM_V_MAX_DUTY_CYCLE_US) / 2)
#define PANTILT_PWM_H_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_H_MIN_DUTY_CYCLE_US + PANTILT_PWM_H_MAX_DUTY_CYCLE_US) / 2)

// Right joystick horizontal threshold for triggering lepton capture
#define LEPTON_RIGHT_JOYSTICK_HORIZONTAL_TRIGGER_THRESHOLD ((uint32_t) (0.8 * JOYSTICKS_MAX_VALUE))

uint32_t interpolate(uint32_t input,
                     uint32_t input_lower_bound,
                     uint32_t input_upper_bound,
                     uint32_t output_lower_bound,
                     uint32_t output_upper_bound) {
    /* TODO : complete this function */
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
    /* TODO : complete this function */

    // Read RIGHT joystick position, and if it is greater than a certain
    // threshold, then launch a capture with the lepton controller and print the
    // output to STDOUT.
}

int main(void) {
    // Hardware control structures
    pantilt_dev pantilt = pantilt_inst(...); /* TODO */
    joysticks_dev joysticks = joysticks_inst(...); /* TODO */
    lepton_dev lepton = lepton_inst(...); /* TODO */

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
        for (uint32_t i = 0; i < SLEEP_DURATION; i++);
    }

    return EXIT_SUCCESS;
}

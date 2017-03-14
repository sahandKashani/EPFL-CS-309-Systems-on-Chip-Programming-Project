#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "pantilt/pantilt.h"
#include "system.h"

#define SLEEP_DURATION_US (25000) //  25  ms
#define PANTILT_STEP_US   (25)    //  25  us

#define PANTILT_PWM_V_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_V_MIN_DUTY_CYCLE_US + PANTILT_PWM_V_MAX_DUTY_CYCLE_US) / 2)
#define PANTILT_PWM_H_CENTER_DUTY_CYCLE_US ((PANTILT_PWM_H_MIN_DUTY_CYCLE_US + PANTILT_PWM_H_MAX_DUTY_CYCLE_US) / 2)

int main(void) {
    // Hardware control structures
    pantilt_dev pantilt = pantilt_inst((void *) PWM_0_BASE, (void *) PWM_1_BASE);

    // Initialize hardware
    pantilt_init(&pantilt);

    // Center servos.
    pantilt_configure_vertical(&pantilt, PANTILT_PWM_V_MIN_DUTY_CYCLE_US);
    pantilt_configure_horizontal(&pantilt, PANTILT_PWM_H_MIN_DUTY_CYCLE_US);
    pantilt_start_vertical(&pantilt);
    pantilt_start_horizontal(&pantilt);

    // Rotate servos in "square" motion
    while (true) {
        uint32_t v_duty_us = 0;
        uint32_t h_duty_us = 0;

        // bottom to top
        v_duty_us = PANTILT_PWM_V_MIN_DUTY_CYCLE_US;
        do {
            pantilt_configure_vertical(&pantilt, v_duty_us);
            v_duty_us += PANTILT_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (v_duty_us <= PANTILT_PWM_V_MAX_DUTY_CYCLE_US);

        // left to right
        h_duty_us = PANTILT_PWM_H_MIN_DUTY_CYCLE_US;
        do {
            pantilt_configure_horizontal(&pantilt, h_duty_us);
            h_duty_us += PANTILT_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (h_duty_us <= PANTILT_PWM_H_MAX_DUTY_CYCLE_US);

        // top to bottom
        v_duty_us = PANTILT_PWM_V_MAX_DUTY_CYCLE_US;
        do {
            pantilt_configure_vertical(&pantilt, v_duty_us);
            v_duty_us -= PANTILT_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (PANTILT_PWM_V_MIN_DUTY_CYCLE_US <= v_duty_us);

        // left to right
        h_duty_us = PANTILT_PWM_H_MAX_DUTY_CYCLE_US;
        do {
            pantilt_configure_horizontal(&pantilt, h_duty_us);
            h_duty_us -= PANTILT_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (PANTILT_PWM_H_MIN_DUTY_CYCLE_US <= h_duty_us);
    }

    return EXIT_SUCCESS;
}

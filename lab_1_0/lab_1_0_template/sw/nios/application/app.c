#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "pwm/pwm.h"
#include "system.h"

#define PWM_CLOCK_FREQ               (50000000)
#define PWM_PERIOD                   (25000)
#define PWM_STEP_US                  (200)

// Vertical servo
#define V_SERVO_MIN_DUTY_CYCLE_US    (9000)
#define V_SERVO_MAX_DUTY_CYCLE_US    (23000)

// Horizontal servo
#define H_SERVO_MIN_DUTY_CYCLE_US    (10000)
#define H_SERVO_MAX_DUTY_CYCLE_US    (19500)

#define SLEEP_DURATION_US            (25000)

int main(void) {
    pwm_dev v_pwm = pwm_inst((void *) PWM_1_BASE);
    pwm_dev h_pwm = pwm_inst((void *) PWM_0_BASE);
    pwm_init(&v_pwm);
    pwm_init(&h_pwm);

    pwm_configure(&v_pwm, V_SERVO_MIN_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);
    pwm_configure(&h_pwm, H_SERVO_MIN_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);
    pwm_start(&v_pwm);
    pwm_start(&h_pwm);

    while (true) {

        // top to bottom
        uint32_t v_duty_us = V_SERVO_MIN_DUTY_CYCLE_US;
        do {
            pwm_configure(&v_pwm, v_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            v_duty_us += PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (v_duty_us < V_SERVO_MAX_DUTY_CYCLE_US);

        // right to left
        uint32_t h_duty_us = H_SERVO_MIN_DUTY_CYCLE_US;
        do {
            pwm_configure(&h_pwm, h_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            h_duty_us += PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (h_duty_us < H_SERVO_MAX_DUTY_CYCLE_US);

        // reset to top
        pwm_configure(&v_pwm, V_SERVO_MIN_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);

        // reset to right
        pwm_configure(&h_pwm, H_SERVO_MIN_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);
    }

    return EXIT_SUCCESS;
}

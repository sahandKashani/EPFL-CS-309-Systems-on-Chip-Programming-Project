#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "pwm/pwm.h"
#include "mcp3204/mcp3204.h"
#include "system.h"

#define PWM_CLOCK_FREQ               (50000000)
#define PWM_PERIOD                   (25000) // 25   ms
#define PWM_STEP_US                  (10)

// Vertical servo
#define V_SERVO_MIN_DUTY_CYCLE_US    (900)   // 0.9  ms
#define V_SERVO_MAX_DUTY_CYCLE_US    (2300)  // 2.3  ms

// Horizontal servo
#define H_SERVO_MIN_DUTY_CYCLE_US    (1000)  // 1    ms
#define H_SERVO_MAX_DUTY_CYCLE_US    (1950)  // 1.95 ms

#define SLEEP_DURATION_US            (7500)  // 7.5  ms

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
        uint32_t v_duty_us = 0;
        uint32_t h_duty_us = 0;

        // top to bottom
        v_duty_us = V_SERVO_MIN_DUTY_CYCLE_US;
        do {
            pwm_configure(&v_pwm, v_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            v_duty_us += PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (v_duty_us <= V_SERVO_MAX_DUTY_CYCLE_US);

        // right to left
        h_duty_us = H_SERVO_MIN_DUTY_CYCLE_US;
        do {
            pwm_configure(&h_pwm, h_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            h_duty_us += PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (h_duty_us <= H_SERVO_MAX_DUTY_CYCLE_US);

        // bottom to top
        v_duty_us = V_SERVO_MAX_DUTY_CYCLE_US;
        do {
            pwm_configure(&v_pwm, v_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            v_duty_us -= PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (V_SERVO_MIN_DUTY_CYCLE_US <= v_duty_us);

        // left to right
        h_duty_us = H_SERVO_MAX_DUTY_CYCLE_US;
        do {
            pwm_configure(&h_pwm, h_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
            h_duty_us -= PWM_STEP_US;
            usleep(SLEEP_DURATION_US);
        } while (H_SERVO_MIN_DUTY_CYCLE_US <= h_duty_us);
    }

    return EXIT_SUCCESS;
}

#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "pwm/pwm.h"
#include "mcp3204/mcp3204.h"
#include "system.h"

#define SLEEP_DURATION_US            (7500)  // 7.5  ms

// PWM
#define PWM_CLOCK_FREQ               (50000000)
#define PWM_PERIOD                   (25000) // 25   ms

// Vertical servo
#define SERVO_V_MIN_DUTY_CYCLE_US    (900)   // 0.9  ms
#define SERVO_V_MAX_DUTY_CYCLE_US    (2300)  // 2.3  ms
#define SERVO_V_CENTER_DUTY_CYCLE_US ((SERVO_V_MIN_DUTY_CYCLE_US + SERVO_V_MAX_DUTY_CYCLE_US) / 2)

// Horizontal servo
#define SERVO_H_MIN_DUTY_CYCLE_US    (1000)  // 1    ms
#define SERVO_H_MAX_DUTY_CYCLE_US    (1950)  // 1.95 ms
#define SERVO_H_CENTER_DUTY_CYCLE_US ((SERVO_H_MIN_DUTY_CYCLE_US + SERVO_H_MAX_DUTY_CYCLE_US) / 2)

// Joysticks
#define JOYSTICK_LEFT_H_CHANNEL  (1)
#define JOYSTICK_LEFT_V_CHANNEL  (0)
#define JOYSTICK_RIGHT_H_CHANNEL (3)
#define JOYSTICK_RIGHT_V_CHANNEL (2)

uint32_t interpolate(uint32_t input,
                     uint32_t input_lower_bound, uint32_t input_upper_bound,
                     uint32_t output_lower_bound, uint32_t output_upper_bound) {
    uint32_t slope = (output_upper_bound - output_lower_bound) / (input_upper_bound - input_lower_bound);
    return output_lower_bound + slope * (input - input_lower_bound);
}

int main(void) {
    // Hardware control structures
    pwm_dev pwm_v = pwm_inst((void *) PWM_1_BASE);
    pwm_dev pwm_h = pwm_inst((void *) PWM_0_BASE);
    mcp3204_dev mcp3204 = mcp3204_inst((void *) MCP3204_0_BASE);

    // Initialize hardware
    pwm_init(&pwm_v);
    pwm_init(&pwm_h);
    mcp3204_init(&mcp3204);

    // Center servos.
    pwm_configure(&pwm_v, SERVO_V_CENTER_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);
    pwm_configure(&pwm_h, SERVO_H_CENTER_DUTY_CYCLE_US, PWM_PERIOD, PWM_CLOCK_FREQ);
    pwm_start(&pwm_v);
    pwm_start(&pwm_h);

    // Control servos with joystick.
    while (true) {
        // Read LEFT joystick VERTICAL axis and interpolate between
        // SERVO_V_MIN_DUTY_CYCLE_US and SERVO_V_MAX_DUTY_CYCLE_US
        uint32_t left_joystick_v = mcp3204_read(&mcp3204, JOYSTICK_LEFT_V_CHANNEL);
        uint32_t servo_v_duty_us = interpolate(left_joystick_v,
                                          MCP3204_MIN_VALUE, MCP3204_MAX_VALUE,
                                          SERVO_V_MIN_DUTY_CYCLE_US, SERVO_V_MAX_DUTY_CYCLE_US);

        // Read LEFT joystick HORIZONTAL axis and interpolate between
        // SERVO_H_MIN_DUTY_CYCLE_US and SERVO_H_MAX_DUTY_CYCLE_US
        uint32_t left_joystick_h = mcp3204_read(&mcp3204, JOYSTICK_LEFT_H_CHANNEL);
        uint32_t servo_h_duty_us = interpolate(left_joystick_h,
                                               MCP3204_MIN_VALUE, MCP3204_MAX_VALUE,
                                               SERVO_H_MIN_DUTY_CYCLE_US, SERVO_H_MAX_DUTY_CYCLE_US);

        // Configure servos with interpolated joystick values
        pwm_configure(&pwm_v, servo_v_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);
        pwm_configure(&pwm_h, servo_h_duty_us, PWM_PERIOD, PWM_CLOCK_FREQ);

        // Sleep for a while to avoid excessive sensitivity
        usleep(SLEEP_DURATION_US);
    }

    return EXIT_SUCCESS;
}

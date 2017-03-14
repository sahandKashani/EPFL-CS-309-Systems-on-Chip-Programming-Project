#include "pantilt.h"

/**
 * pantilt_inst
 *
 * Instantiate a pantilt device structure.
 *
 * @param pwm_v_base Base address of the vertical PWM component.
 * @param pwm_h_base Base address of the horizontal PWM component.
 */
pantilt_dev pantilt_inst(void *pwm_v_base, void *pwm_h_base) {
    pantilt_dev dev;
    dev.pwm_v = pwm_inst(pwm_v_base);
    dev.pwm_h = pwm_inst(pwm_h_base);

    return dev;
}

/**
 * pantilt_init
 *
 * Initializes the pantilt device.
 *
 * @param dev pantilt device structure.
 */
void pantilt_init(pantilt_dev *dev) {
    pwm_init(&(dev->pwm_v));
    pwm_init(&(dev->pwm_h));
}

/**
 * pantilt_configure_vertical
 *
 * Configure the vertical PWM component.
 *
 * @param dev pantilt device structure.
 * @param duty_cycle pwm duty cycle in us.
 */
void pantilt_configure_vertical(pantilt_dev *dev, uint32_t duty_cycle) {
    // Need to compensate for inverted servo rotation.
    duty_cycle = PANTILT_PWM_V_MAX_DUTY_CYCLE_US - duty_cycle + PANTILT_PWM_V_MIN_DUTY_CYCLE_US;

    pwm_configure(&(dev->pwm_v),
                  duty_cycle,
                  PANTILT_PWM_PERIOD_US,
                  PANTILT_PWM_CLOCK_FREQ_HZ);
}

/**
 * pantilt_configure_horizontal
 *
 * Configure the horizontal PWM component.
 *
 * @param dev pantilt device structure.
 * @param duty_cycle pwm duty cycle in us.
 */
void pantilt_configure_horizontal(pantilt_dev *dev, uint32_t duty_cycle) {
    // Need to compensate for inverted servo rotation.
    duty_cycle = PANTILT_PWM_H_MAX_DUTY_CYCLE_US - duty_cycle + PANTILT_PWM_H_MIN_DUTY_CYCLE_US;

    pwm_configure(&(dev->pwm_h),
                  duty_cycle,
                  PANTILT_PWM_PERIOD_US,
                  PANTILT_PWM_CLOCK_FREQ_HZ);
}

/**
 * pantilt_start_vertical
 *
 * Starts the vertical pwm controller.
 *
 * @param dev pantilt device structure.
 */
void pantilt_start_vertical(pantilt_dev *dev) {
    pwm_start(&(dev->pwm_v));
}

/**
 * pantilt_start_horizontal
 *
 * Starts the horizontal pwm controller.
 *
 * @param dev pantilt device structure.
 */
void pantilt_start_horizontal(pantilt_dev *dev) {
    pwm_start(&(dev->pwm_h));
}

/**
 * pantilt_stop_vertical
 *
 * Stops the vertical pwm controller.
 *
 * @param dev pantilt device structure.
 */
void pantilt_stop_vertical(pantilt_dev *dev) {
    pwm_stop(&(dev->pwm_v));
}

/**
 * pantilt_stop_horizontal
 *
 * Stops the horizontal pwm controller.
 *
 * @param dev pantilt device structure.
 */
void pantilt_stop_horizontal(pantilt_dev *dev) {
    pwm_stop(&(dev->pwm_h));
}

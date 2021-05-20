#include <io.h>

#include "pwm.h"
#include "pwm_regs.h"

/**
 * pwm_inst
 *
 * Instantiate a pwm device structure.
 *
 * @param base Base address of the component.
 */
pwm_dev pwm_inst(void *base) {
    pwm_dev dev;

    dev.base = base;

    return dev;
}

/**
 * pwm_init
 *
 * Initializes the pwm device. This function stops the controller.
 *
 * @param dev pwm device structure.
 */
void pwm_init(pwm_dev *dev) {
    pwm_stop(dev);
}

/**
 * pwm_configure
 *
 * Configure pwm component.
 *
 * @param dev pwm device structure.
 * @param duty_cycle pwm duty cycle in us.
 * @param period pwm period in us.
 * @param module_frequency frequency at which the component is clocked.
 */
void pwm_configure(pwm_dev *dev, uint32_t duty_cycle, uint32_t period, uint32_t module_frequency) {
    /* TODO : complete this function */
}

/**
 * pwm_start
 *
 * Starts the pwm controller.
 *
 * @param dev pwm device structure.
 */
void pwm_start(pwm_dev *dev) {
    /* TODO : complete this function */
}

/**
 * pwm_stop
 *
 * Stops the pwm controller.
 *
 * @param dev pwm device structure.
 */
void pwm_stop(pwm_dev *dev) {
    /* TODO : complete this function */
}

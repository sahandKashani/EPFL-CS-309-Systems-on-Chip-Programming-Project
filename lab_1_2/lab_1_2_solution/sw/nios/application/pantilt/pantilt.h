#ifndef __PANTILT_H__
#define __PANTILT_H__

#include "pwm/pwm.h"

/* joysticks device structure */
typedef struct pantilt_dev {
    pwm_dev pwm_v; /* Vertical PWM device handle */
    pwm_dev pwm_h; /* Horizontal PWM device handle */
} pantilt_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/

#define PANTILT_PWM_CLOCK_FREQ_HZ       (50000000) // 50   MHz

#define PANTILT_PWM_PERIOD_US           (25000)    // 25   ms

/* Horizontal servo */
#define PANTILT_PWM_V_MIN_DUTY_CYCLE_US (900)      // 0.9  ms
#define PANTILT_PWM_V_MAX_DUTY_CYCLE_US (2300)     // 2.3  ms

/* Vertical servo */
#define PANTILT_PWM_H_MIN_DUTY_CYCLE_US (1000)     // 1    ms
#define PANTILT_PWM_H_MAX_DUTY_CYCLE_US (1950)     // 1.95 ms

pantilt_dev pantilt_inst(void *pwm_v_base, void *pwm_h_base);

void pantilt_init(pantilt_dev *dev);

void pantilt_configure_vertical(pantilt_dev *dev, uint32_t duty_cycle);
void pantilt_configure_horizontal(pantilt_dev *dev, uint32_t duty_cycle);
void pantilt_start_vertical(pantilt_dev *dev);
void pantilt_start_horizontal(pantilt_dev *dev);
void pantilt_stop_vertical(pantilt_dev *dev);
void pantilt_stop_horizontal(pantilt_dev *dev);

#endif /* __PANTILT_H__ */

#ifndef __PWM_H__
#define __PWM_H__

#include <stdint.h>

/* pwm device structure */
typedef struct pwm_dev {
    void *base; /* Base address of component */
} pwm_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
pwm_dev pwm_inst(void *base);

void pwm_init(pwm_dev *dev);
void pwm_configure(pwm_dev *dev, uint32_t duty_cycle, uint32_t period, uint32_t module_frequency);
void pwm_start(pwm_dev *dev);
void pwm_stop(pwm_dev *dev);

#endif /* __PWM_H__ */

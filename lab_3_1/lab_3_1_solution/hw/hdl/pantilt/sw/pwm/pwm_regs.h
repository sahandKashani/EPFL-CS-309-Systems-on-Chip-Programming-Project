#ifndef __PWM_REGS_H__
#define __PWM_REGS_H__

#define PWM_PERIOD_OFST     (0 * 4) /* RW */
#define PWM_DUTY_CYCLE_OFST (1 * 4) /* RW */
#define PWM_CTRL_OFST       (2 * 4) /* WO */

#define PWM_CTRL_STOP_MASK  (0)
#define PWM_CTRL_START_MASK (1)

#endif /* __PWM_REGS_H__ */

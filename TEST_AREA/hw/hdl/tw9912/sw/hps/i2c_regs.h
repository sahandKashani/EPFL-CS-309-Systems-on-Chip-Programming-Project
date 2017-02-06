#ifndef __I2C_REGS_H__
#define __I2C_REGS_H__

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#endif

#include "i2c_io.h"

#define I2C_DATA_OFST                                 (0) /* RW */
#define I2C_CONTROL_OFST                              (1) /* RW */
#define I2C_STATUS_OFST                               (2) /* RO */
#define I2C_CLOCK_DIVISOR_OFST                        (3) /* RW */

#define I2C_DATA_ADDR(base)                           ((void *) ((uint8_t *) (base) + I2C_DATA_OFST))
#define I2C_CONTROL_ADDR(base)                        ((void *) ((uint8_t *) (base) + I2C_CONTROL_OFST))
#define I2C_STATUS_ADDR(base)                         ((void *) ((uint8_t *) (base) + I2C_STATUS_OFST))
#define I2C_CLOCK_DIVISOR_ADDR(base)                  ((void *) ((uint8_t *) (base) + I2C_CLOCK_DIVISOR_OFST))

#define I2C_CONTROL_ACKNOWLEDGE_READ_BIT_OFST         (0)
#define I2C_CONTROL_GENERATE_STOP_SEQUENCE_BIT_OFST   (1)
#define I2C_CONTROL_GENERATE_START_SEQUENCE_BIT_OFST  (2)
#define I2C_CONTROL_READ_COMMAND_BIT_OFST             (3)
#define I2C_CONTROL_WRITE_COMMAND_BIT_OFST            (4)
#define I2C_CONTROL_INTERRUPT_ENABLE_BIT_OFST         (5)
#define I2C_CONTROL_ACKNOWLEDGE_READ_MSK              (1 << I2C_CONTROL_ACKNOWLEDGE_READ_BIT_OFST)
#define I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK        (1 << I2C_CONTROL_GENERATE_STOP_SEQUENCE_BIT_OFST)
#define I2C_CONTROL_GENERATE_START_SEQUENCE_MSK       (1 << I2C_CONTROL_GENERATE_START_SEQUENCE_BIT_OFST)
#define I2C_CONTROL_READ_COMMAND_MSK                  (1 << I2C_CONTROL_READ_COMMAND_BIT_OFST)
#define I2C_CONTROL_WRITE_COMMAND_MSK                 (1 << I2C_CONTROL_WRITE_COMMAND_BIT_OFST)
#define I2C_CONTROL_INTERRUPT_ENABLE_MSK              (1 << I2C_CONTROL_INTERRUPT_ENABLE_BIT_OFST)

#define I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_BIT_OFST (0)
#define I2C_STATUS_BUS_BUSY_BIT_OFST                  (1)
#define I2C_STATUS_INTERRUPT_PENDING_BIT_OFST         (2)
#define I2C_STATUS_TRANSFER_IN_PROGRESS_BIT_OFST      (3)
#define I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK      (1 << I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_BIT_OFST)
#define I2C_STATUS_BUS_BUSY_MSK                       (1 << I2C_STATUS_BUS_BUSY_BIT_OFST)
#define I2C_STATUS_INTERRUPT_PENDING_MSK              (1 << I2C_STATUS_INTERRUPT_PENDING_BIT_OFST)
#define I2C_STATUS_TRANSFER_IN_PROGRESS_MSK           (1 << I2C_STATUS_TRANSFER_IN_PROGRESS_BIT_OFST)

#define I2C_WR_DATA(base, data)                       i2c_write_byte(I2C_DATA_ADDR((base)), (data))
#define I2C_WR_CONTROL(base, data)                    i2c_write_byte(I2C_CONTROL_ADDR((base)), (data))
#define I2C_WR_CLOCK_DIVISOR(base, data)              i2c_write_byte(I2C_CLOCK_DIVISOR_ADDR((base)), (data))
#define I2C_RD_DATA(base)                             i2c_read_byte(I2C_DATA_ADDR((base)))
#define I2C_RD_CONTROL(base)                          i2c_read_byte(I2C_CONTROL_ADDR((base)))
#define I2C_RD_STATUS(base)                           i2c_read_byte(I2C_STATUS_ADDR((base)))
#define I2C_RD_CLOCK_DIVISOR(base)                    i2c_read_byte(I2C_CLOCK_DIVISOR_ADDR((base)))

#endif /* __I2C_REGS_H__ */

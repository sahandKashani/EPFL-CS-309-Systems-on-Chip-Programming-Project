#ifndef __I2C_H__
#define __I2C_H__

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#include <stdbool.h>
#endif

/* i2c device structure */
typedef struct i2c_dev {
    void *base; /* Base address of component */
} i2c_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
#define I2C_SUCCESS (0) /* success */
#define I2C_ENODEV  (1) /* no such device */
#define I2C_EBADACK (2) /* bad acknowledge */

i2c_dev i2c_inst(void *base);

void i2c_init(i2c_dev *dev, uint32_t i2c_frequency);

void i2c_configure(i2c_dev *dev, bool irq);
int i2c_write(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t value);
int i2c_read(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value);
int i2c_simple_read(i2c_dev *dev, uint8_t device, uint8_t *values, int n);
int i2c_write_array(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value, unsigned int size);
int i2c_read_array(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value, unsigned int size);

#endif /* __I2C_H__ */

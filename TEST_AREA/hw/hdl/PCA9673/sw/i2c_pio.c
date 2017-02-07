/*
 * i2c_pio.c
 *
 *  Created on: Feb 5, 2017
 *      Author: Florian Depraz
 */

#include "io.h"

#include "i2c_pio.h"
#include "system.h"

#include <stdint.h>

/**
 * i2c_pio_inst
 *
 * Instantiate a i2c_pio device structure.
 *
 * @param base Base address of the component.
 */
i2c_pio_dev i2c_pio_inst(void *base)
{
    i2c_pio_dev dev;

    dev.base = base;

    return dev;
}

static const uint32_t I2C_PIO_STATUS_REG_OFST = 0x10 * 4;
static const uint32_t I2C_PIO_ERROR_MASK = 2;
static const uint32_t I2C_PIO_BUSY_MASK = 1;
/**
 * i2c_pio_write
 *
 * Write the i2c_pio device.
 *
 * @param dev i2c_pio device structure.
 * @retval 0 failure
 * @retval 1 success
 */
void i2c_pio_write(i2c_pio_dev *dev, uint16_t data)
{
    uint8_t bit = 0;
    for(bit = 0; bit < 16; bit++)
    {
    	i2c_pio_writebit(dev, bit, data >> bit);
    }
}

void i2c_pio_writebit(i2c_pio_dev *dev, uint8_t bit, uint8_t data)
{
    IOWR_32DIRECT(dev->base, bit * 4, data);
}
/**
 * i2c_pio_read
 *
 * Read the i2c_pio device.
 *
 * @param dev i2c_pio device structure.
 */
uint16_t i2c_pio_read(i2c_pio_dev *dev)
{
    uint8_t bit = 0;
    uint16_t out = 0;

    for(bit = 0; bit < 16; bit++)
    {
        out |= i2c_pio_readbit(dev, bit) << bit;
    }

    return out;
}

uint16_t i2c_pio_readbit(i2c_pio_dev *dev, uint8_t bit)
{
    return IORD_32DIRECT(dev->base, bit*4);
}


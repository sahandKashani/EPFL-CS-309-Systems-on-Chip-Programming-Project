/*
 * i2c_pio.c
 *
 *  Created on: Feb 5, 2017
 *      Author: Florian Depraz
 */

#include "io_custom.h"

#include "i2c_pio.h"
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
    ioc_write_word(dev->base, bit * 4, data);
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
    return ioc_read_word(dev->base, bit*4);
}


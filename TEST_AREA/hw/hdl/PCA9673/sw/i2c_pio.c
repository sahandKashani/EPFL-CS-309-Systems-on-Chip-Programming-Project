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
i2c_pio_dev i2c_pio_inst(void *base) {
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
 */
void i2c_pio_write(i2c_pio_dev *dev, uint16_t data) {
    uint8_t bit = 0;
    for(bit = 0; bit < 16; bit++){
        IOWR_32DIRECT(dev->base, bit*4, data >> bit);
    }
}

void i2c_pio_writebit(i2c_pio_dev *dev, uint8_t bit, uint16_t addr) {
    IOWR_32DIRECT(dev->base, addr, bit);
}
/**
 * i2c_pio_read
 *
 * Read the i2c_pio device.
 *
 * @param dev i2c_pio device structure.
 */
uint16_t i2c_pio_read(i2c_pio_dev *dev) {
    uint8_t bit = 0;
    uint16_t out = 0;

    for(bit = 0; bit < 16; bit++){
        out |= IORD_32DIRECT(dev->base, bit*4) << bit;
    }

    return out;
}

uint16_t i2c_pio_readbit(i2c_pio_dev *dev, uint8_t bit) {
    uint16_t out = 0;

    out = IORD_32DIRECT(dev->base, bit*4);


    return out;
}


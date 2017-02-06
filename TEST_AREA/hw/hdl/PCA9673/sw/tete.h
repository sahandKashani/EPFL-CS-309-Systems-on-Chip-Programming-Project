/*
 * tete.h
 *
 *  Created on: Feb 5, 2017
 *      Author: psoc
 */

#ifndef TETE_H_
#define TETE_H_



#include <stdint.h>

/* pwm device structure */
typedef struct i2c_pio_dev2 {
    void *base; /* Base address of component */
} i2c_pio_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
i2c_pio_dev i2c_pio_inst(void *base);

void i2c_pio_write(i2c_pio_dev *dev, uint16_t data);
void i2c_pio_writebit(i2c_pio_dev *dev, uint8_t bit, uint16_t addr);

uint16_t i2c_pio_read(i2c_pio_dev *dev);
uint16_t i2c_pio_readbit(i2c_pio_dev *dev, uint8_t bit);


#endif /* TETE_H_ */

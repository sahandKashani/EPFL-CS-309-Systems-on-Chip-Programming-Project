/*
 * i2c_pio.h
 *
 *  Created on: Feb 5, 2017
 *      Author: Florian Depraz
 */

#ifndef I2C_PIO_H_
#define I2C_PIO_H_

#define BIT_BLON 		0
#define BIT_WIFI_PWR 	1
#define BIT_BLT_PWR		2
#define BIT_BLT_ATSel	3
#define BIT_WIFI_RESETn 4
#define BIT_WIFI_PD_CH	5
#define BIT_BLT_STATE	6
#define BIT_BLT_EN		7
#define BIT_J0SWRn		8
#define BIT_J1SWRn 		9
#define BIT_DIODE12 	10
#define BIT_DIODE13		11
#define BIT_CAM_EXPO	12
#define BIT_CAM_LED_OUT 13
#define BIT_PAL_PWR 	14
#define BIT_CAM_PWR		15


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
void i2c_pio_writebit(i2c_pio_dev *dev, uint8_t bit, uint8_t data);

uint16_t i2c_pio_read(i2c_pio_dev *dev);
uint16_t i2c_pio_readbit(i2c_pio_dev *dev, uint8_t bit);


#endif /* I2C_PIO_H_ */

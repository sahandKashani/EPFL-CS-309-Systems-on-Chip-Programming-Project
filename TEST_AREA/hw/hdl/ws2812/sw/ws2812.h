/*
 * i2c_pio.h
 *
 *  Created on: Feb 5, 2017
 *      Author: Florian Depraz
 */

#ifndef WS2812_H_
#define WS2812_H_


#include <stdint.h>

//------------------------------------
#define WS2812_DEFAULT_LOW_PULSE 		21
#define WS2812_DEFAULT_HIGH_PULSE 		36
#define WS2812_DEFAULT_BREAK_PULSE 		50
#define WS2812_DEFAULT_CLOCK_DIVIDER	64

#define WS2812_REGS_INTENSITY_OFSET (4*0)
#define WS2812_REGS_CONFIG_OFST     (4*1)
#define WS2812_REGS_LEDS_OFST       (4*2)

/* pwm device structure */
typedef struct ws2812_dev2 {
    void *base; /* Base address of component */
} ws2812_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
ws2812_dev ws2812_inst(void *base);

void ws2812_writePixel(ws2812_dev *dev, uint8_t led, uint8_t red, uint8_t green, uint8_t blue);
void ws2812_setIntensity(ws2812_dev *dev, uint8_t intensity);
void ws2812_setConfig(ws2812_dev *dev, uint8_t low_pulse, uint8_t high_pulse, uint8_t break_pulse, uint8_t clock_divider);
void ws2812_setPower(ws2812_dev *dev, uint8_t power);

uint32_t ws2812_readPixel(ws2812_dev *dev, uint8_t led);
uint32_t ws2812_readConfig(ws2812_dev *dev);
uint32_t ws2812_readIntensity(ws2812_dev *dev);


#endif /* WS2812_H_ */

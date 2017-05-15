/*
 * i2c_pio.c
 *
 *  Created on: Feb 5, 2017
 *      Author: Florian Depraz
 */

#include "io_custom.h"

#include "ws2812.h"
#include <stdint.h>

/**
 * ws2812_inst
 *
 * Instantiate a ws2812_dev device structure.
 *
 * @param base Base address of the component.
 */
ws2812_dev ws2812_inst(void *base)
{
    ws2812_dev dev;
    dev.base = base;

    return dev;
}

void ws2812_writePixel(ws2812_dev *dev, uint8_t led, uint8_t red, uint8_t green, uint8_t blue){
    uint32_t pixel_value = (green<<16) | (red << 8) | blue;
    ioc_write_word(dev->base, WS2812_REGS_LEDS_OFST + 4*led, pixel_value);
}

void ws2812_setIntensity(ws2812_dev *dev, uint8_t intensity){
    uint32_t intensity_reg = ws2812_readIntensity(dev);
    intensity_reg = intensity_reg & ~(0xFF);
    intensity_reg = intensity_reg | intensity;

    ioc_write_word(dev->base, WS2812_REGS_INTENSITY_OFSET, intensity_reg);
}

void ws2812_setConfig(ws2812_dev *dev, uint8_t low_pulse, uint8_t high_pulse, uint8_t break_pulse, uint8_t clock_divider){
    uint32_t register_config = (clock_divider << 24) | (break_pulse << 16) | (high_pulse <<8) | low_pulse;
    ioc_write_word(dev->base, WS2812_REGS_CONFIG_OFST, register_config);
}

void ws2812_setPower(ws2812_dev *dev, uint8_t power){
    uint32_t intensity_reg = ws2812_readIntensity(dev);
    uint32_t power_extended = (power & 0x1);

    intensity_reg = intensity_reg & ~(power_extended << 8);
    intensity_reg = intensity_reg | (power_extended << 8);

    ioc_write_word(dev->base, WS2812_REGS_INTENSITY_OFSET, intensity_reg);
}


uint32_t ws2812_readPixel(ws2812_dev *dev, uint8_t led){
    uint32_t pixel = ioc_read_word(dev->base, WS2812_REGS_LEDS_OFST + 4*led);    
    return pixel;

}

uint32_t ws2812_readConfig(ws2812_dev *dev){
   uint32_t config = ioc_read_word(dev->base, WS2812_REGS_CONFIG_OFST);
   return config;
}

uint32_t ws2812_readIntensity(ws2812_dev *dev){
    uint32_t intensity = ioc_read_word(dev->base, WS2812_REGS_INTENSITY_OFSET);
    return intensity;

}

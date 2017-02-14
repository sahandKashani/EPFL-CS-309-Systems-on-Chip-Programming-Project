#pragma once

#include <stdint.h>

/* mcp3204 device structure */
typedef struct mcp3204_dev {
    void *base; /* Base address of component */
} mcp3204_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
mcp3204_dev mcp3204_inst(void *base);

void mcp3204_init(mcp3204_dev *dev);
uint32_t mcp3204_read(mcp3204_dev *dev, uint32_t channel);

#ifndef __JOYSTICKS_H__
#define __JOYSTICKS_H__

#include "mcp3204/mcp3204.h"

/* joysticks device structure */
typedef struct joysticks_dev {
    mcp3204_dev mcp3204; /* MCP3204 device handle */
} joysticks_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/

#define JOYSTICKS_MIN_VALUE (MCP3204_MIN_VALUE)
#define JOYSTICKS_MAX_VALUE (MCP3204_MAX_VALUE)

joysticks_dev joysticks_inst(void *mcp3204_base);

void joysticks_init(joysticks_dev *dev);

uint32_t joysticks_read_left_vertical(joysticks_dev *dev);
uint32_t joysticks_read_left_horizontal(joysticks_dev *dev);
uint32_t joysticks_read_right_vertical(joysticks_dev *dev);
uint32_t joysticks_read_right_horizontal(joysticks_dev *dev);

#endif /* __JOYSTICKS_H__ */

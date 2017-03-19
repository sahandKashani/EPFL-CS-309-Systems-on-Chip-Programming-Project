#ifndef __MCP3204_H__
#define __MCP3204_H__

#include <stdint.h>

/* mcp3204 device structure */
typedef struct mcp3204_dev {
    void *base; /* Base address of component */
} mcp3204_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/

#define MCP3204_MIN_VALUE (0)
#define MCP3204_MAX_VALUE (4095)

mcp3204_dev mcp3204_inst(void *base);

void mcp3204_init(mcp3204_dev *dev);
uint32_t mcp3204_read(mcp3204_dev *dev, uint32_t channel);

#endif /* __MCP3204_H__ */

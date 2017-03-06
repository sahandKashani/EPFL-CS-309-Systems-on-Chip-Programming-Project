#include <assert.h>
#include <io.h>

#include "mcp3204.h"

#define MCP3204_NUM_CHANNELS (4)

/**
 * mcp3204_inst
 *
 * Instantiate a mcp3204 device structure.
 *
 * @param base Base address of the component.
 */
mcp3204_dev mcp3204_inst(void *base) {
    mcp3204_dev dev;
    dev.base = base;

    return dev;
}

/**
 * mcp3204_init
 *
 * Initializes the mcp3204 device.
 *
 * @param dev mcp3204 device structure.
 */
void mcp3204_init(mcp3204_dev *dev) {
    return;
}

/**
 * mcp3204_read
 *
 * Reads the register corresponding to the supplied channel parameter.
 *
 * @param dev mcp3204 device structure.
 * @param channel channel to be read
 */
uint32_t mcp3204_read(mcp3204_dev *dev, uint32_t channel) {
    assert(channel < MCP3204_NUM_CHANNELS);
    return IORD_32DIRECT(dev->base, 4 * channel);
}

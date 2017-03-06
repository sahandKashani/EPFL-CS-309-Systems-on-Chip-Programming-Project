#include "joysticks.h"

#define JOYSTICK_RIGHT_H_MCP3204_CHANNEL (0)
#define JOYSTICK_RIGHT_V_MCP3204_CHANNEL (1)
#define JOYSTICK_LEFT_H_MCP3204_CHANNEL  (2)
#define JOYSTICK_LEFT_V_MCP3204_CHANNEL  (3)

/**
 * joysticks_inst
 *
 * Instantiate a joysticks device structure.
 *
 * @param base Base address of the MCP3204 component connected to the joysticks.
 */
joysticks_dev joysticks_inst(void *mcp3204_base) {
    joysticks_dev dev;
    dev.mcp3204 = mcp3204_inst((void *) mcp3204_base);

    return dev;
}

/**
 * joysticks_init
 *
 * Initializes the joysticks device.
 *
 * @param dev joysticks device structure.
 */
void joysticks_init(joysticks_dev *dev) {
    mcp3204_init(&(dev->mcp3204));
}

/**
 * joysticks_read_left_vertical
 *
 * Returns the vertical position of the left joystick. Return value ranges
 * between JOYSTICKS_MIN_VALUE and JOYSTICKS_MAX_VALUE.
 *
 * @param dev joysticks device structure.
 */
uint32_t joysticks_read_left_vertical(joysticks_dev *dev) {
    // Since the joysticks are rotated clockwise by 90 degress, we must read
    // the HORIZONTAL axis to get a VERTICAL reading we want.
    uint32_t value = mcp3204_read(&(dev->mcp3204), JOYSTICK_LEFT_H_MCP3204_CHANNEL);

    // Need to compensate for 90 degree rotation.
    return JOYSTICKS_MAX_VALUE - value;
}

/**
 * joysticks_read_left_horizontal
 *
 * Returns the horizontal position of the left joystick. Return value ranges
 * between JOYSTICKS_MIN_VALUE and JOYSTICKS_MAX_VALUE.
 *
 * @param dev joysticks device structure.
 */
uint32_t joysticks_read_left_horizontal(joysticks_dev *dev) {
    // Since the joysticks are rotated clockwise by 90 degress, we must read
    // the VERTICAL axis to get a HORIZONTAL reading we want.
    uint32_t value = mcp3204_read(&(dev->mcp3204), JOYSTICK_LEFT_V_MCP3204_CHANNEL);
    return value;
}

/**
 * joysticks_read_right_vertical
 *
 * Returns the vertical position of the right joystick. Return value ranges
 * between JOYSTICKS_MIN_VALUE and JOYSTICKS_MAX_VALUE.
 *
 * @param dev joysticks device structure.
 */
uint32_t joysticks_read_right_vertical(joysticks_dev *dev) {
    // Since the joysticks are rotated clockwise by 90 degress, we must read
    // the HORIZONTAL axis to get a VERTICAL reading we want.
    uint32_t value = mcp3204_read(&(dev->mcp3204), JOYSTICK_RIGHT_H_MCP3204_CHANNEL);

    // Need to compensate for 90 degree rotation.
    return JOYSTICKS_MAX_VALUE - value;
}

/**
 * joysticks_read_right_horizontal
 *
 * Returns the horizontal position of the left joystick. Return value ranges
 * between JOYSTICKS_MIN_VALUE and JOYSTICKS_MAX_VALUE.
 *
 * @param dev joysticks device structure.
 */
uint32_t joysticks_read_right_horizontal(joysticks_dev *dev) {
    // Since the joysticks are rotated clockwise by 90 degress, we must read
    // the VERTICAL axis to get a HORIZONTAL reading we want.
    uint32_t value = mcp3204_read(&(dev->mcp3204), JOYSTICK_RIGHT_V_MCP3204_CHANNEL);
    return value;
}

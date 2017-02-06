#if defined(__KERNEL__) || defined(MODULE)
#include <linux/delay.h>
#include <linux/types.h>
#else
#include <stdint.h>
#include <stdbool.h>
#include <unistd.h>
#endif

#include "i2c.h"
#include "i2c_regs.h"

#define I2C_SLEEP_US (5000)

/*******************************************************************************
 *  Private API
 ******************************************************************************/
static void i2c_usleep(unsigned int useconds);
static void i2c_wait_end_of_transfer(i2c_dev *dev);
static void i2c_set_data_control(i2c_dev *dev, uint8_t data, uint8_t control);
static uint8_t i2c_get_data_set_control(i2c_dev *dev, uint8_t control);

/* Function to put the host processor to sleep for microseconds */
static void i2c_usleep(unsigned int useconds) {
#if defined(__KERNEL__) || defined(MODULE)
    udelay(useconds);
#else
    usleep(useconds);
#endif
}

/*
 * Waits until the current i2c transfer is finished.
 */
static void i2c_wait_end_of_transfer(i2c_dev *dev) {
    while (I2C_RD_STATUS(dev->base) & I2C_STATUS_TRANSFER_IN_PROGRESS_MSK);
}

/*
 * Writes the supplied "data" argument to SDA while using the control sequences
 * provided in argument "control".
 */
static void i2c_set_data_control(i2c_dev *dev, uint8_t data, uint8_t control) {
    i2c_wait_end_of_transfer(dev);
    I2C_WR_DATA(dev->base, data);
    I2C_WR_CONTROL(dev->base, control);
    i2c_wait_end_of_transfer(dev);
}

/*
 * Reads data from SDA while using the control sequences provided in argument
 * "control".
 */
static uint8_t i2c_get_data_set_control(i2c_dev *dev, uint8_t control) {
    i2c_wait_end_of_transfer(dev);
    I2C_WR_CONTROL(dev->base, control);
    i2c_wait_end_of_transfer(dev);
    return I2C_RD_DATA(dev->base);
}

/*******************************************************************************
 *  Public API
 ******************************************************************************/
/*
 * i2c_inst
 *
 * Constructs a device structure.
 */
i2c_dev i2c_inst(void *base) {
    i2c_dev dev;

    dev.base = base;

    return dev;
}

/*
 * i2c_init
 *
 * Initializes the i2c interface by setting its clock divisor register. The
 * standard data rate for an I2C transfer is 100 kbits/s. However, in order to
 * meet the timing constraints of the protocol, the I2C controller needs to
 * operate 4 times faster. Therefore, one must set the clock divisor register to
 * i2c_frequency / (4 * 100 KHz).
 */
void i2c_init(i2c_dev *dev, uint32_t i2c_frequency) {
    I2C_WR_CLOCK_DIVISOR(dev->base, i2c_frequency / (4 * 100000));
    i2c_usleep(I2C_SLEEP_US);
}

/*
 * i2c_configure
 *
 * Configure the controller.
 *
 * Setting the irq paramater to true enables interrupt generation at the end of
 * a read/write transfer, and false disables interrupt generation.
 */
void i2c_configure(i2c_dev *dev, bool irq) {
    uint32_t config = 0;

    if (irq) {
        config |= I2C_CONTROL_INTERRUPT_ENABLE_MSK;
    } else {
        config &= ~I2C_CONTROL_INTERRUPT_ENABLE_MSK;
    }

    I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
    I2C_WR_CONTROL(dev->base, config);
}

/*
 * i2c_write
 *
 * Write an 8-bit value to the device's register through the i2c protocol.
 *
 * Returns: I2C_SUCCESS -> success
 *          I2C_ENODEV  -> device does not answer
 *          I2C_EBADACK -> bad acknowledge received
 */
int i2c_write(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t value) {
    /* write to the device with the R/W bit set to 0 (write mode) */
    i2c_set_data_control(dev, device & 0xFE, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    /* write register index to device */
    i2c_set_data_control(dev, index, I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: bad acknowledge */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_EBADACK;
    }

    /* write register data to device */
    i2c_set_data_control(dev, value, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: bad acknowledge */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_EBADACK;
    }

    return I2C_SUCCESS;
}

/*
 * i2c_simple_read
 *
 * Read an 8-bit value from the device's register through the raw i2c protocol.
 *
 * Returns: I2C_SUCCESS -> success
 *          I2C_ENODEV  -> device does not answer
 *          I2C_EBADACK -> bad acknowledge received
 */
int i2c_simple_read(i2c_dev *dev, uint8_t device, uint8_t *values, int n)
{
	int i;
    i2c_set_data_control(dev, device | 0x01, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    for (i = 0; i < n; ++i) {
		/* error: device does not answer */
		if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
			I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
			return I2C_ENODEV;
		}

		/* Read the data. Attention: write I2C_CONTROL_ACKNOWLEDGE_READ_MSK to control register to send a N0_ACK */
		values[i] = i2c_get_data_set_control(dev, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK | I2C_CONTROL_READ_COMMAND_MSK | I2C_CONTROL_ACKNOWLEDGE_READ_MSK);
    }
    return I2C_SUCCESS;
}
/*
 * i2c_read
 *
 * Read an 8-bit value from the device's register through the classical indexed i2c protocol.
 *
 * Returns: I2C_SUCCESS -> success
 *          I2C_ENODEV  -> device does not answer
 *          I2C_EBADACK -> bad acknowledge received
 */
int i2c_read(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value) {
    /* write to the device with the R/W bit set to 0 (write mode) */
    i2c_set_data_control(dev, device & 0xFE, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    /* write register index to device */
    i2c_set_data_control(dev, index, I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: bad acknowledge */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_EBADACK;
    }

    /* write to the device with the R/W bit set to 1 (read mode) */
    i2c_set_data_control(dev, device | 0x01, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    /* Read the data. Attention: write I2C_CONTROL_ACKNOWLEDGE_READ_MSK to control register to send a N0_ACK */
    *value = i2c_get_data_set_control(dev, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK | I2C_CONTROL_READ_COMMAND_MSK | I2C_CONTROL_ACKNOWLEDGE_READ_MSK);

    return I2C_SUCCESS;
}

/*
 * i2c_write_array
 *
 * Write an array of 8-bit values to the device's register through the i2c
 * protocol.
 *
 * Returns: I2C_SUCCESS -> success
 *          I2C_ENODEV  -> device does not answer
 *          I2C_EBADACK -> bad acknowledge received
 */
int i2c_write_array(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value, unsigned int size) {
    /* write to the device with the R/W bit set to 0 (write mode) */
    i2c_set_data_control(dev, device & 0xFE, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    /* write register index to device */
    i2c_set_data_control(dev, index, I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: bad acknowledge */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_EBADACK;
    }

    unsigned int i = 0;
    for (i = 0; i < size; i++) {
        /* write register data to device */
        if (i < size - 1) {
            i2c_set_data_control(dev, value[i], I2C_CONTROL_WRITE_COMMAND_MSK);
        } else {
            i2c_set_data_control(dev, value[i], I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

        }

        /* error: bad acknowledge */
        if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
            I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
            return I2C_EBADACK;
        }
    }

    return I2C_SUCCESS;
}

/*
 * i2c_read_array
 *
 * Reads an array of 8-bit values from the device's register through the i2c
 * protocol.
 *
 * Returns: I2C_SUCCESS -> success
 *          I2C_ENODEV  -> device does not answer
 *          I2C_EBADACK -> bad acknowledge received
 */
int i2c_read_array(i2c_dev *dev, uint8_t device, uint8_t index, uint8_t *value, unsigned int size) {
    /* write to the device with the R/W bit set to 0 (write mode) */
    i2c_set_data_control(dev, device & 0xFE, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    /* write register index to device */
    i2c_set_data_control(dev, index, I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: bad acknowledge */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_EBADACK;
    }

    /* write to the device with the R/W bit set to 1 (read mode) */
    i2c_set_data_control(dev, device | 0x01, I2C_CONTROL_GENERATE_START_SEQUENCE_MSK | I2C_CONTROL_WRITE_COMMAND_MSK);

    /* error: device does not answer */
    if (I2C_RD_STATUS(dev->base) & I2C_STATUS_LAST_ACKNOWLEDGE_RECEIVED_MSK) {
        I2C_WR_CONTROL(dev->base, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK);
        return I2C_ENODEV;
    }

    unsigned int i = 0;
    for (i = 0; i < size; i++) {
        if (i < size - 1) {
            value[i] = i2c_get_data_set_control(dev, I2C_CONTROL_READ_COMMAND_MSK);
        } else {
            /* Read the data. Attention: write I2C_CONTROL_ACKNOWLEDGE_READ_MSK to control register to send a N0_ACK */
            value[i] = i2c_get_data_set_control(dev, I2C_CONTROL_GENERATE_STOP_SEQUENCE_MSK | I2C_CONTROL_READ_COMMAND_MSK | I2C_CONTROL_ACKNOWLEDGE_READ_MSK);
        }
    }

    return I2C_SUCCESS;
}

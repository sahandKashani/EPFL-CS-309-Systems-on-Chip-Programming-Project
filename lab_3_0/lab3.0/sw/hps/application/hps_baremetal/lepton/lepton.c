#include <assert.h>
#include <stdio.h>
#include <inttypes.h>
#include <unistd.h>

#include "lepton_regs.h"
#include "lepton.h"

/**
 * lepton_inst
 *
 * Instantiate a lepton device structure.
 *
 * @param base Base address of the component.
 */
lepton_dev lepton_inst(void *base) {
    lepton_dev dev;

    dev.base = base;

    return dev;
}

/**
 * lepton_init
 *
 * Initializes the lepton device.
 *
 * @param dev lepton device structure.
 */
void lepton_init(lepton_dev *dev) {
    return;
}

/**
 * lepton_start_capture
 *
 * Instructs the device to start the frame capture process.
 *
 * @param dev lepton device structure.
 */
void lepton_start_capture(lepton_dev *dev) {
    /* TODO : complete this function */
}

/**
 * lepton_error_check
 *
 * @abstract Check for errors at the device level.
 * @param dev lepton device structure.
 * @return true if there was an error, and false otherwise.
 */
bool lepton_error_check(lepton_dev *dev) {
    /* TODO : complete this function */
}

/**
 * lepton_wait_until_eof
 *
 * Waits until the frame being captured has been fully received and saved in the
 * internal memory.
 *
 * @param dev lepton device structure.
 */
void lepton_wait_until_eof(lepton_dev *dev) {
    /* TODO : complete this function */
}

/**
 * lepton_print_capture
 *
 * Prints the captured frame to the serial console. The frame will be outputted
 * in a PGM format.
 *
 * @param dev lepton device structure.
 * @param adjusted Setting this parameter to false will cause RAW sensor data to
 *                 be written to the file.
 *                 Setting this parameter to true will cause a preprocessed image
 *                 (with a stretched dynamic range) to be saved to the file.
 */
void lepton_print_capture(lepton_dev *dev, bool adjusted) {
    /* TODO : complete this function */
}

#include <assert.h>
#include <stdio.h>
#include <inttypes.h>
#include <unistd.h>

#include "lepton_regs.h"
#include "lepton.h"
#include "io_custom.h"

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
	ioc_write_hword(dev->base, LEPTON_REGS_COMMAND_OFST, 1);
}

/**
 * lepton_error_check
 *
 * @abstract Check for errors at the device level.
 * @param dev lepton device structure.
 * @return true if there was an error, and false otherwise.
 */
bool lepton_error_check(lepton_dev *dev) {
    uint16_t error_flag = ioc_read_hword(dev->base, LEPTON_REGS_STATUS_OFST);
    return ((error_flag & 0x2) != 0);
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
    while ((ioc_read_hword(dev->base, LEPTON_REGS_STATUS_OFST) & 0x1) != 0);
}

/**
 * lepton_save_capture
 *
 * Saves the captured frame on the host filesystem under the supplied filename.
 * The frame will be saved in a PGM format.
 *
 * @param dev lepton device structure.
 * @param adjusted Setting this parameter to false will cause RAW sensor data to
 *                 be written to the file.
 *                 Setting this parameter to true will cause a preprocessed image
 *                 (with a stretched dynamic range) to be saved to the file.
 *
 * @param fname the output file name.
 */
void lepton_save_capture(lepton_dev *dev, bool adjusted, const char *fname) {
    FILE *fp = fopen(fname, "w");
    assert(fp);

    const uint8_t num_rows = 60;
    const uint8_t num_cols = 80;

    uint16_t offset = LEPTON_REGS_BUFFER_OFST;
    uint16_t max_value = ioc_read_hword(dev->base, LEPTON_REGS_MAX_OFST);
    if (adjusted) {
        offset = LEPTON_REGS_ADJUSTED_BUFFER_OFST;
        max_value = 0x3fff;
    }

    /* Write header */
    fprintf(fp, "P2\n%" PRIu8 " %" PRIu8 "\n%" PRIu16, num_cols, num_rows, max_value);

    /* Write body */
    uint8_t row = 0;
    for (row = 0; row < num_rows; ++row) {
        fputs("\n", fp);

        uint8_t col = 0;
        for (col = 0; col < num_cols; ++col) {
            if (col > 0) {
                fputs(" ", fp);
            }

            uint16_t current_ofst = offset + (row * num_cols + col) * sizeof(uint16_t);
            uint16_t pix_value = ioc_read_hword(dev->base, current_ofst);
            fprintf(fp, "%" PRIu16, pix_value);
        }
    }

    assert(!fclose(fp));
}

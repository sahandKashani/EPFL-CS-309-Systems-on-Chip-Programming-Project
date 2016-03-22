#include "lepton_regs.h"
#include "lepton.h"
#include "io.h"
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

lepton_dev lepton_open(void *base)
{
	lepton_dev dev;

	dev.base = base;

	return dev;
}

void lepton_start_capture(lepton_dev *dev)
{
	IOWR_16DIRECT(dev->base, LEPTON_REGS_COMMAND_OFFSET, 1);
}

void lepton_wait_until_eof(lepton_dev *dev)
{
	while (IORD_16DIRECT(dev->base, LEPTON_REGS_STATUS_OFFSET) != 0);
}

void lepton_save_capture(lepton_dev *dev, bool adjusted)
{
	int row, col, offset;
	FILE *fp;

	offset = LEPTON_REGS_BUFFER_OFFSET;
	if (adjusted)
		offset = LEPTON_REGS_ADJUSTED_BUFFER_OFFSET;

	fp = fopen("/mnt/host/output.pgm", "w");

	// Write header
	fprintf(fp, "P2\n80 60\n%d", IORD_16DIRECT(dev->base, LEPTON_REGS_MAX_OFFSET));

	// Write body
	for (row = 0; row < 60; ++row) {
		fputs("\n", fp);
		for (col = 0; col < 80; ++col) {
			if (col > 0) fputs("\t", fp);
			fprintf(fp, "%d", IORD_16DIRECT(dev->base, offset + row * 80 * sizeof(uint16_t) + col * sizeof(uint16_t)));
		}
	}

	fclose(fp);
}

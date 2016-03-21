#include "lepton_regs.h"
#include "lepton.h"
#include "io.h"
#include <stdio.h>
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
	while (IORD_16DIRECT(dev->base, LEPTON_REGS_STATUS_OFFSET) != 0) {
		printf("Currently acquiring row %x...\n", IORD_16DIRECT(dev->base, LEPTON_REGS_SUM_LSB_OFFSET + 2));
	}
}

void lepton_save_capture(lepton_dev *dev)
{
	int i;
	FILE *fp;

	fp = fopen("/mnt/host/output.pgm", "w");

	// Write header
	fprintf(fp, "P2\n80 60\n%d", IORD_16DIRECT(dev->base, LEPTON_REGS_MAX_OFFSET));

	// Write body
	for (i = LEPTON_REGS_BUFFER_OFFSET; i < (LEPTON_REGS_BUFFER_OFFSET + LEPTON_REGS_BUFFER_SIZE); ++i) {
		int col = i % 80;

		if (col == (LEPTON_REGS_BUFFER_OFFSET % 80)) {
			fprintf(fp, "\n");
		}

		fprintf(fp, "%d\t", IORD_16DIRECT(dev->base, i));
	}

	fclose(fp);
}

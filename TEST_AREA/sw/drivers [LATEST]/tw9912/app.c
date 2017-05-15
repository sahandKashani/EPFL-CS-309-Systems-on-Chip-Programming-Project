/*
 * app.c
 *
 *  Created on: Jun 4, 2016
 *      Author: phil
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>

#include "hps_0.h" // MIGHT NEED TO BE REPLACED IF THE HARDWARE IS MODIFIED
#include "i2c.h"
#include "msgdma.h"

#define MAX(A, B) (((A) > (B)) ? (A) : (B))

#define HPS_LH2F_BRIDGE_BASE 0xff200000
#define HPS_LH2F_BRIDGE_SPAN 0x00200000
#define DESTINATION_BUFFER (0x4C80000)

#define MSGDMA_DEV_CREATE(CSR,DESC, PREFIX) \
		msgdma_csr_descriptor_inst( \
				(void *) (CSR), \
				(void *) (DESC), \
				PREFIX ## _DESCRIPTOR_SLAVE_DESCRIPTOR_FIFO_DEPTH, \
				PREFIX ## _CSR_BURST_ENABLE, \
				PREFIX ## _CSR_BURST_WRAPPING_SUPPORT, \
				PREFIX ## _CSR_DATA_FIFO_DEPTH, \
				PREFIX ## _CSR_DATA_WIDTH, \
				PREFIX ## _CSR_MAX_BURST_COUNT, \
				PREFIX ## _CSR_MAX_BYTE, \
				PREFIX ## _CSR_MAX_STRIDE, \
				PREFIX ## _CSR_PROGRAMMABLE_BURST_ENABLE, \
				PREFIX ## _CSR_STRIDE_ENABLE, \
				PREFIX ## _CSR_ENHANCED_FEATURES, \
				PREFIX ## _CSR_RESPONSE_PORT)

void pal_dump_reg(i2c_dev *dev, uint8_t regno, const char *regname) {
	int s;
	uint8_t val;
	s = i2c_read(dev, 0x88, regno, &val);
	if (s != I2C_SUCCESS) {
		printf("Couldn't read %s (0x%2x)\n", regname, regno);
		exit(-1);
	}
	printf("%s (0x%02x) = 0x%02x\n", regname, regno, val);
}

void pal_write_reg(i2c_dev *dev, uint8_t regno, uint8_t val,
		const char *regname) {
	int s;
	s = i2c_write(dev, 0x88, regno, val);
	if (s != I2C_SUCCESS) {
		printf("Couldn't write %s (0x%2x)\n", regname, regno);
		exit(-1);
	}
}

void tw9912_configure(void *i2c_regs) {
	i2c_dev ddc_pal_dev = i2c_inst(i2c_regs);
	i2c_init(&ddc_pal_dev, 50000000 * 4);
	i2c_configure(&ddc_pal_dev, false);

	pal_write_reg(&ddc_pal_dev, 0xc0, 0x01, "LLPLL INPUT CONTROL REGISTER");

	pal_write_reg(&ddc_pal_dev, 0x03, 0x26, "OUTPUT CONTROL REGISTER");

	pal_write_reg(&ddc_pal_dev, 0x02, 0x40, "INPUT FORMAT REGISTER"); /* DO NOT CHANGE ! Y0 = SELECTED */

	pal_write_reg(&ddc_pal_dev, 0x05, 0x00, "OUTPUT CTL REGISTER 2");

	pal_write_reg(&ddc_pal_dev, 0x37, 0x00, "HDELAY2");
	pal_write_reg(&ddc_pal_dev, 0x38, 0x00, "HSTART");

	pal_dump_reg(&ddc_pal_dev, 0x02, "INFORM REGISTER");
}

int main(void) {
	void *lh2fbridge;
	uint8_t *dest;
	uint32_t *tw9912_csr;
	uint32_t *msgdma_csr;
	uint32_t *msgdma_des;
	uint32_t *tw9912_i2c;
	msgdma_dev dma_dev;
	msgdma_standard_descriptor dma_desc;

	int fd = open("/dev/mem", O_RDWR | O_SYNC);
	lh2fbridge = mmap(NULL, HPS_LH2F_BRIDGE_SPAN, PROT_READ | PROT_WRITE,
			MAP_SHARED, fd, HPS_LH2F_BRIDGE_BASE);

	tw9912_csr = (lh2fbridge + TW9912_ADAPTER_0_BASE);
	msgdma_csr = (lh2fbridge + MSGDMA_0_CSR_BASE);
	msgdma_des = (lh2fbridge + MSGDMA_0_DESCRIPTOR_SLAVE_BASE);
	tw9912_i2c = (lh2fbridge + I2C_0_BASE);

	tw9912_configure(tw9912_i2c);

	/* Start a dummy capture to collect the width and height information */
	tw9912_csr[0] = 0;
	while (1 != (tw9912_csr[0] & 1))
		;

	unsigned long width = tw9912_csr[1];
	unsigned long height = tw9912_csr[2];
	unsigned long length = width * height;
	printf("Status = %x\n", tw9912_csr[0]);
	printf("Width = %ld, Height = %ld, Length = %ld\n", width, height, length);

	/* Confgiure the DMA */
	dma_dev = MSGDMA_DEV_CREATE(msgdma_csr, msgdma_des, MSGDMA_0);
	msgdma_init(&dma_dev);

        int ret = msgdma_construct_standard_st_to_mm_descriptor(&dma_dev,
                        &dma_desc, (void *) DESTINATION_BUFFER + 0x80000000, length, 0);
        if (ret < 0)
                exit(-1);

        /* Start capture + transfer */
        ret = msgdma_standard_descriptor_async_transfer(&dma_dev, &dma_desc);
        if (ret < 0)
                exit(-2);
        tw9912_csr[0] = 0;

        msgdma_wait_until_idle(&dma_dev);

        printf("DMA Done\n");

        width = tw9912_csr[1];
        height = tw9912_csr[2];
        length = width * height;
        printf("Width = %ld, Height = %ld, Length = %ld\n", width, height,
                        length);

        dest = mmap(NULL, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd,
                        DESTINATION_BUFFER);
        printf("dest = %p\n", dest);
        if (dest == MAP_FAILED)
                exit(-3);

        FILE *fp = fopen("out_pal.pgm", "w");
        fprintf(fp, "P2\n%ld %ld\n255", width / 2, height);

        int i;
        for (i = 0; i < length; i += 4) {
                if (i % width == 0)
                        fprintf(fp, "\n");
                else
                        fprintf(fp, "\t");

                unsigned char cb = dest[i + 0];
                unsigned char y0 = dest[i + 1];
                unsigned char cr = dest[i + 2];
                unsigned char y1 = dest[i + 3];

                fprintf(fp, "%d\t%d", y0, y1);
        }

        fclose(fp);

	printf("\n\nGood!\n");

	munmap(lh2fbridge, HPS_LH2F_BRIDGE_SPAN);
	munmap(dest, length);

	return 0;
}

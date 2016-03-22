/*
 * "Hello World" example.
 *
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example
 * designs. It runs with or without the MicroC/OS-II RTOS and requires a STDOUT
 * device in your system's hardware.
 * The memory footprint of this hosted application is ~69 kbytes by default
 * using the standard reference design.
 *
 * For a reduced footprint version of this template, and an explanation of how
 * to reduce the memory footprint for a given application, see the
 * "small_hello_world" template.
 *
 */

#include <stdio.h>
#include <io.h>
#include <system.h>
#include "lepton/lepton_regs.h"
#include "lepton/lepton.h"

int main() {
	lepton_dev dev;

	dev = lepton_open(LEPTON_0_BASE);
	lepton_start_capture(&dev);
	lepton_wait_until_eof(&dev);

	printf("Wow! It's transferred !\n");

	lepton_save_capture(&dev, true);

	printf("Wow! It's written on hostfs !\n");

	return 0;
}

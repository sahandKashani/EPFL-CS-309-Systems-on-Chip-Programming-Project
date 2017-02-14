#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <unistd.h>
#include <stdbool.h>
#include <assert.h>

#include "pwm.h"
#include "mcp3204.h"
#include "lepton.h"
#include "i2c_pio.h"
#include "ws2812.h"


// Set to 1 if you want to test the module
#define PANTILT_TEST 	1
#define MCP3204_TEST 	1
#define PCA9637_TEST 	1
#define LEPTON_TEST	1
#define BRIDGE_TEST	0
#define WS2812_TEST  	1

//------------------------------------
#define PANTILT_REF_DUTY 		25000

#define PANTILT_INIT_DUTY_0 	15000
#define PANTILT_MAX_DUTY_0 		23000
#define PANTILT_MIN_DUTY_0 		9000

#define PANTILT_INIT_DUTY_1 	15000
#define PANTILT_MAX_DUTY_1 		19500
#define PANTILT_MIN_DUTY_1 		10500

#define PANTILT_STEP		 	100
//------------------------------------
#define MCP3204_CHANNELS		4
#define MCP3204_MAX_VALUE		4096	// DOWN or RIGHT
#define MCP3204_MIN_VALUE		0		// UP	or LEFT
#define MCP3204_TOLERANCY_LOW	200
#define MCP3204_TOLERANCY_HIGH	3896
//------------------------------------
#define LEPTON_FILENAME "output_lepton.pgm"
//------------------------------------

#ifdef __nios2_arch__
	#define LEPTON_PGM_IMAGE_FILENAME ("/mnt/host/" LEPTON_FILENAME)
	#include "system.h"
	#define MAIN_CPU_FREQ ALT_CPU_CPU_FREQ
#else
	#define LEPTON_PGM_IMAGE_FILENAME ("/home/sahand/" LEPTON_FILENAME)
	// If this file does not exist, please run the script /home/psoc/psoc/TEST_AREA/create_hw_headers.sh
	#include "hps_0.h"
	#include "hps_0_bridges.h"
	#include "soc_system.h"



	#include <sys/mman.h>
	#include <fcntl.h>
	#include <string.h>

	#define MAIN_CPU_FREQ 50000000
	
	/*
	*	FPGA Slaves Accessed Via Lightweight HPS2FPGA AXI Bridge	
	*	Start 0xFF200000
	*	End 0xFF3FFFFF
	*	https://www.altera.com/hps/en_us/cyclone-v/hps.html#topic/sfo1418687413697.html
	*/
	#define HPS_LH2F_BRIDGE_BASE 0xff200000
	#define HPS_LH2F_BRIDGE_SPAN 0x00200000

#endif




void ws2812_test(uint32_t base){
	printf("TESTING WS2812 START !\n");

	ws2812_dev ws2812;
	ws2812 = ws2812_inst((void*) base);

	uint8_t low_pulse  = WS2812_DEFAULT_LOW_PULSE;
	uint8_t high_pulse = WS2812_DEFAULT_HIGH_PULSE;
	uint8_t break_pulse = WS2812_DEFAULT_BREAK_PULSE;
	uint8_t clock_divider = WS2812_DEFAULT_CLOCK_DIVIDER ;
	uint32_t luminosity = 10;

	ws2812_setConfig(&ws2812, low_pulse, high_pulse, break_pulse, clock_divider);
	ws2812_setPower(&ws2812, 0);

    // GRB
	printf("LED Cyan !\n");
	ws2812_writePixel(&ws2812, 0, 0xFF, 0x00, 0xFF);
	usleep(1000000);
	printf("LED Blue !\n");
	ws2812_writePixel(&ws2812, 0, 0x00, 0x00, 0xFF);
	usleep(1000000);
	printf("LED Red !\n");
	ws2812_writePixel(&ws2812, 0, 0xFF, 0x00, 0x00);
	usleep(1000000);
	printf("LED Green !\n");
	ws2812_writePixel(&ws2812, 0, 0x00, 0xFF, 0x00);
	usleep(1000000);

	printf("LED intensity !\n");
	for(luminosity = 0; luminosity < 64; luminosity++){
		usleep(100000);
		ws2812_setIntensity(&ws2812, luminosity);
	}

	printf("LED from White to stop !\n");
	uint8_t red = 0;
	uint8_t green = 0;
	uint8_t blue = 0;

	while(red != 0xFF){
		ws2812_writePixel(&ws2812, 0, red, green, blue);
		blue += 0xF;
		if(blue == 0xFF){
			blue = 0;
			green += 0xF;
			if(green == 0xFF){
				green = 0;
				red += 0xF;
			}
		}
		usleep(1000);
	}

	printf("LED stop !\n");
	ws2812_setPower(&ws2812, 1);
	printf("TESTING WS2812 DONE !\n");
}



#ifdef HPS_0_BRIDGES_BASE

	void bridge_test(void){
		printf("TESTING BRIDGE START !\n");

		for (uint32_t i = 0; i < HPS_0_BRIDGES_SPAN; i += 4) {
			uint32_t write_value = i;
			IOWR_32DIRECT(HPS_0_BRIDGES_BASE, i, i);

			uint32_t read_value = IORD_32DIRECT(HPS_0_BRIDGES_BASE, i);
			assert(write_value == read_value);
		}
		printf("TESTING BRIDGE DONE !\n");
	}

#else
	void bridge_test(void){
		printf("TESTING BRIDGE START !\n");
		printf("No Bridge !\n");
		printf("TESTING BRIDGE DONE !\n");

	}
#endif

void lepton_test(uint32_t base){

	printf("TESTING LEPTON START !\n");
	lepton_dev lepton = lepton_inst((void*) base);
	lepton_init(&lepton);


	do{
		lepton_start_capture(&lepton);
		lepton_wait_until_eof(&lepton);

	}while(lepton_error_check(&lepton));
	printf("Capture successful !\n");

	lepton_save_capture(&lepton, true, LEPTON_PGM_IMAGE_FILENAME);

	printf("TESTING LEPTON DONE !\n");

}



void pca9673_test(uint32_t base){

	printf("TESTING PCA9673 START !\n");

	i2c_pio_dev dev = i2c_pio_inst((void*) base);

	printf("Switch D12 OFF\n");
	i2c_pio_writebit(&dev, BIT_DIODE12, 1);
	usleep(1000000);

	printf("Switch D13 OFF\n");
	i2c_pio_writebit(&dev, BIT_DIODE13, 1);
	usleep(1000000);

	printf("Switch D12 ON\n");
	i2c_pio_writebit(&dev, BIT_DIODE12, 0);
	usleep(1000000);

	printf("Switch D13 ON\n");
	i2c_pio_writebit(&dev, BIT_DIODE13, 0);
	usleep(1000000);

	printf("Press switch Joystick0\n");
	i2c_pio_writebit(&dev, BIT_J0SWRn, 1);
	while (i2c_pio_readbit(&dev, BIT_J0SWRn)){
		usleep(10000);
	}
	printf("Ok!\n");
	printf("Press switch Joystick1\n");
	i2c_pio_writebit(&dev, BIT_J1SWRn, 1);
	while (i2c_pio_readbit(&dev, BIT_J1SWRn)){
		usleep(10000);
	}
	printf("Ok!\n");


	printf("TESTING PCA9673 DONE !\n");

}


void joystick_test(uint32_t base, uint32_t pwm0_base, uint32_t pwm1_base){

	printf("TESTING JOYSTICK START !\n");

	mcp3204_dev mcp = mcp3204_inst((void*) base);
	mcp3204_init(&mcp);

	pwm_dev pwm0 = pwm_inst((void *) pwm0_base);
	pwm_dev pwm1 = pwm_inst((void *) pwm1_base);
	pwm_init(&pwm0);
	pwm_init(&pwm1);
	uint32_t duty_in_us0 = PANTILT_INIT_DUTY_0;
	uint32_t duty_in_us1 = PANTILT_INIT_DUTY_1;


	printf("Move the servomoters using the joysticks !\n");
	printf("Set both the joystick on the Left to exit !\n");

	// JOYSTICK1 (on the RIGHT): channels 0(joystick UP/DOWN) and 1(joystick LEFT/RIGHT)
	// JOYSTICK0 (on the LEFT):  channels 2(joystick UP/DOWN) and 3(joystick LEFT/RIGHT)
	uint32_t mcp_channels[MCP3204_CHANNELS] = {0};
	uint8_t i = 0;
	uint8_t loop = 1;
	while (loop) {

		pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
		pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
		pwm_start(&pwm0);
		pwm_start(&pwm1);

		for(i = 0; i < MCP3204_CHANNELS; i++){
			mcp_channels[i] = mcp3204_read(&mcp, i);
			//printf("Channel %" PRIu8 "= %" PRIu32 "\n", i, mcp_channels[i]);
		}

		// Use Joystick0 (LEFT)  for LEFT and RIGHT
		double j0 = ( (mcp_channels[2] - MCP3204_MIN_VALUE) / ((double)(MCP3204_MAX_VALUE - MCP3204_MIN_VALUE)) ) * (PANTILT_MAX_DUTY_0 - PANTILT_MIN_DUTY_0) + PANTILT_MIN_DUTY_0;
		duty_in_us0 = (uint32_t) j0;

		// Use Joystick1 (RIGHT) for UP and DOWN
		double j1 = ( (mcp_channels[0] - MCP3204_MIN_VALUE) / ((double)(MCP3204_MAX_VALUE - MCP3204_MIN_VALUE)) ) * (PANTILT_MAX_DUTY_1 - PANTILT_MIN_DUTY_1) + PANTILT_MIN_DUTY_1;
		duty_in_us1 = (uint32_t) j1;
		//printf("%" PRIu32 " -- %" PRIu32 "\n", duty_in_us0, duty_in_us1);

		if(mcp_channels[1] < MCP3204_TOLERANCY_LOW && mcp_channels[3] < MCP3204_TOLERANCY_LOW){
			loop = 0;
			printf("Both joysticks left, exiting!\n");
		}

		usleep(10000);
	}

	loop = 1;
	printf("Set all joysticks UP!\n");
	while (loop) {
		mcp_channels[0] = mcp3204_read(&mcp, 0);
		mcp_channels[2] = mcp3204_read(&mcp, 2);
		usleep(1000);
		if(mcp_channels[0] < MCP3204_TOLERANCY_LOW && mcp_channels[2] < MCP3204_TOLERANCY_LOW){
			loop = 0;
			printf("Ok!\n");
		}
	}

	loop = 1;
	printf("Set all joysticks DOWN!\n");
	while (loop) {
		mcp_channels[0] = mcp3204_read(&mcp, 0);
		mcp_channels[2] = mcp3204_read(&mcp, 2);
		usleep(1000);
		if(mcp_channels[0] > MCP3204_TOLERANCY_HIGH && mcp_channels[2] > MCP3204_TOLERANCY_HIGH){
			loop = 0;
			printf("Ok!\n");
		}
	}

	loop = 1;
	printf("Set all joysticks LEFT!\n");
	while (loop) {
		mcp_channels[1] = mcp3204_read(&mcp, 1);
		mcp_channels[3] = mcp3204_read(&mcp, 3);
		usleep(1000);
		if(mcp_channels[1] < MCP3204_TOLERANCY_LOW && mcp_channels[3] < MCP3204_TOLERANCY_LOW){
			loop = 0;
			printf("Ok!\n");
		}
	}

	loop = 1;
	printf("Set all joysticks RIGHT!\n");
	while (loop) {
		mcp_channels[1] = mcp3204_read(&mcp, 1);
		mcp_channels[3] = mcp3204_read(&mcp, 3);
		usleep(1000);
		if(mcp_channels[1] > MCP3204_TOLERANCY_HIGH && mcp_channels[3] > MCP3204_TOLERANCY_HIGH){
			loop = 0;
			printf("Ok!\n");
		}
	}


	printf("TESTING JOYSTICK DONE !\n");

}

void pantilt_test(uint32_t pwm0_base, uint32_t pwm1_base){

	printf("TESTING PANTILT START !\n");

	pwm_dev pwm0 = pwm_inst((void *) pwm0_base);
	pwm_dev pwm1 = pwm_inst((void *) pwm1_base);
	pwm_init(&pwm0);
	pwm_init(&pwm1);

	uint32_t duty_in_us0 = PANTILT_INIT_DUTY_0;
	uint32_t duty_in_us1 = PANTILT_INIT_DUTY_1;

	// s = left
	// a = right
	// w = down
	// e = up
	#define PANTILT_SEQUENCE_ARRAY_SIZE (22*20)
	char test_sequence[PANTILT_SEQUENCE_ARRAY_SIZE] = {
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 'x', 'x', 'x',

							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a',
							'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'a', 'x', 'x', 'x',

							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's',
							's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 's', 'x', 'x', 'x',

							'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w',
							'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'w', 'x', 'x', 'x',

							'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
							'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
							'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e',
							'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'e', 'x', 'x', 'x'
						};

	uint32_t seq_number = 0;
	while (seq_number < PANTILT_SEQUENCE_ARRAY_SIZE) {

		pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
		pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
		pwm_start(&pwm0);
		pwm_start(&pwm1);

		char c = test_sequence[seq_number];
		if (c == 's') {
			duty_in_us0 += PANTILT_STEP;
			printf("duty_in_us0 = %" PRIu32 "\n", duty_in_us0);
		} else if (c == 'a') {
			duty_in_us0 -= PANTILT_STEP;
			printf("duty_in_us0 = %" PRIu32 "\n", duty_in_us0);
		} else if (c == 'w') {
			duty_in_us1 += PANTILT_STEP;
			printf("duty_in_us1 = %" PRIu32 "\n", duty_in_us1);
		} else if (c == 'e') {
			duty_in_us1 -= PANTILT_STEP;
			printf("duty_in_us1 = %" PRIu32 "\n", duty_in_us1);
		}

		usleep(10000);
		seq_number++;
	}

	duty_in_us0 = (PANTILT_MIN_DUTY_0  + PANTILT_MAX_DUTY_0) / 2;
	duty_in_us1 = (PANTILT_MIN_DUTY_1 + PANTILT_MAX_DUTY_1) / 2;
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
	usleep(1000000);

	duty_in_us0 = 20000;
	duty_in_us1 = 12000;
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY, MAIN_CPU_FREQ);

	usleep(1000000);
	duty_in_us0 = (PANTILT_MIN_DUTY_0  + PANTILT_MAX_DUTY_0) / 2;
	duty_in_us1 = (PANTILT_MIN_DUTY_1 + PANTILT_MAX_DUTY_1) / 2;
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY, MAIN_CPU_FREQ);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY, MAIN_CPU_FREQ);


	printf("TESTING PANTILT DONE !\n");

}

int main(void) {

	void *lh2fbridge;

	uint32_t pwm_0_base;
	uint32_t pwm_1_base;
	uint32_t mcp3204_base;
	uint32_t i2c_pio_base;
	uint32_t lepton_base;
	uint32_t ws2812_base;

	#ifdef __nios2_arch__
		pwm_0_base   = PWM_0_BASE;
		pwm_1_base   = PWM_1_BASE;
		mcp3204_base = MCP3204_0_BASE;
		i2c_pio_base = I2C_PIO_0_BASE;
		lepton_base  = LEPTON_0_BASE;
		ws2812_base  = WS2812_0_BASE;

	#else
		int fd = open("/dev/mem", O_RDWR | O_SYNC);
		lh2fbridge = mmap(NULL, HPS_LH2F_BRIDGE_SPAN, PROT_READ | PROT_WRITE,
					MAP_SHARED, fd, HPS_LH2F_BRIDGE_BASE);

		assert(lh2fbridge != NULL);

		pwm_0_base   = (uint32_t) (lh2fbridge + PWM_0_BASE);
		pwm_1_base   = (uint32_t) (lh2fbridge + PWM_1_BASE);
		mcp3204_base = (uint32_t) (lh2fbridge + MCP3204_0_BASE);
		i2c_pio_base = (uint32_t) (lh2fbridge + I2C_PIO_0_BASE);
		lepton_base  = (uint32_t) (lh2fbridge + LEPTON_0_BASE);
		ws2812_base  = (uint32_t) (lh2fbridge + WS2812_0_BASE);
		

	#endif
	
	if(PANTILT_TEST){
		pantilt_test(pwm_0_base, pwm_1_base);
	}

	if( MCP3204_TEST){
		joystick_test(mcp3204_base, pwm_0_base, pwm_1_base);
	}

	if(PCA9637_TEST){
		pca9673_test(i2c_pio_base);
	}

	if(LEPTON_TEST){
		lepton_test(lepton_base);
	}

	if(BRIDGE_TEST){
		bridge_test();
	}

	if(WS2812_TEST){
		ws2812_test(ws2812_base);
	}

	return 0;
}


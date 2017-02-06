#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>
#include <unistd.h>

#include "io.h"

#include "system.h"
#include "pwm.h"
#include "mcp3204.h"
#include "lepton.h"


#define PANTILT_TEST 0
#define MCP3204_TEST 0
#define PCA9637_TEST 0
#define LEPTON_TEST	 1

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

void lepton_test(void){

	printf("TESTING LEPTON START !\n");
	lepton_dev lepton = lepton_inst(LEPTON_0_BASE);
	lepton_init(&lepton);


	do{
		lepton_start_capture(&lepton);
		lepton_wait_until_eof(&lepton);

	}while(lepton_error_check(&lepton));
	printf("Capture successful !\n");

	lepton_save_capture(&lepton, true, "/mnt/host/test.pgm");

	printf("TESTING LEPTON DONE !\n");

}



void pca9673_test(void){

	printf("TESTING PCA9673 START !\n");

	printf("TESTING PCA9673 DONE !\n");

}


void joystick_test(void){

	printf("TESTING JOYSTICK START !\n");

	mcp3204_dev mcp = mcp3204_inst((void*) MCP3204_0_BASE);
	mcp3204_init(&mcp);

	pwm_dev pwm0 = pwm_inst((void *) PWM_0_BASE);
	pwm_dev pwm1 = pwm_inst((void *) PWM_1_BASE);
	pwm_init(&pwm0);
	pwm_init(&pwm1);
	uint32_t duty_in_us0 = PANTILT_INIT_DUTY_0;
	uint32_t duty_in_us1 = PANTILT_INIT_DUTY_1;


	// JOYSTICK1 (on the RIGHT): channels 0(joystick UP/DOWN) and 1(joystick LEFT/RIGHT)
	// JOYSTICK0 (on the LEFT):  channels 2(joystick UP/DOWN) and 3(joystick LEFT/RIGHT)
	uint32_t mcp_channels[MCP3204_CHANNELS] = {0};
	uint8_t i = 0;
	uint8_t loop = 1;
	while (loop) {

		pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY);
		pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY);
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

void pantilt_test(void){

	printf("TESTING PANTILT START !\n");

	pwm_dev pwm0 = pwm_inst((void *) PWM_0_BASE);
	pwm_dev pwm1 = pwm_inst((void *) PWM_1_BASE);
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

		pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY);
		pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY);
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
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY);
	usleep(1000000);

	duty_in_us0 = 20000;
	duty_in_us1 = 12000;
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY);

	usleep(1000000);
	duty_in_us0 = (PANTILT_MIN_DUTY_0  + PANTILT_MAX_DUTY_0) / 2;
	duty_in_us1 = (PANTILT_MIN_DUTY_1 + PANTILT_MAX_DUTY_1) / 2;
	pwm_configure(&pwm0, duty_in_us0, PANTILT_REF_DUTY);
	pwm_configure(&pwm1, duty_in_us1, PANTILT_REF_DUTY);


	printf("TESTING PANTILT DONE !\n");

}

int main() {

	if(PANTILT_TEST){
		pantilt_test();
	}

	if( MCP3204_TEST){
		joystick_test();
	}

	if(PCA9637_TEST){
		pca9673_test();
	}

	if(LEPTON_TEST){
		lepton_test();
	}

	return 0;
}


#include <stdlib.h>
#include <io.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdbool.h>

#include "pwm/pwm.h"
#include "system.h"

/* top servo    = [ 9000, 23000] us */
/* bottom servo = [10500, 19500] us */

int main(void) {
    pwm_dev pwm = pwm_inst(PWM_0_BASE);
    pwm_init(&pwm);

    uint32_t duty_in_us = 15000;
    uint32_t step = 200;

    while (true) {
        pwm_configure(&pwm, duty_in_us, 25000);
        pwm_start(&pwm);

        int c = getc(stdin);
        if (c == 's') {
            duty_in_us += step;
        } else if (c == 'a') {
            duty_in_us -= step;
        }
        printf("duty_in_us = %" PRIu32 "\n", duty_in_us);
    }

    return EXIT_SUCCESS;
}

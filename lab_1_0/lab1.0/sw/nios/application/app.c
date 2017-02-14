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
    pwm_dev pwm0 = pwm_inst((void *) PWM_0_BASE);
    pwm_dev pwm1 = pwm_inst((void *) PWM_1_BASE);
    pwm_init(&pwm0);
    pwm_init(&pwm1);

    uint32_t duty_in_us0 = 15000;
    uint32_t duty_in_us1 = 15000;
    uint32_t step = 200;

    while (true) {
        pwm_configure(&pwm0, duty_in_us0, 25000);
        pwm_configure(&pwm1, duty_in_us1, 25000);
        pwm_start(&pwm0);
        pwm_start(&pwm1);

        int c = getc(stdin);
        if (c == 's') {
            duty_in_us0 += step;
            printf("duty_in_us0 = %" PRIu32 "\n", duty_in_us0);
        } else if (c == 'a') {
            duty_in_us0 -= step;
            printf("duty_in_us0 = %" PRIu32 "\n", duty_in_us0);
        } else if (c == 'w') {
            duty_in_us1 += step;
            printf("duty_in_us1 = %" PRIu32 "\n", duty_in_us1);
        } else if (c == 'e') {
            duty_in_us1 -= step;
            printf("duty_in_us1 = %" PRIu32 "\n", duty_in_us1);
        }
    }

    return EXIT_SUCCESS;
}

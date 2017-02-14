#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "lepton/lepton.h"

/* TODO : insert needed header files */

int main() {
    /* TODO : complete this function */

    lepton_dev lepton0 = lepton_inst(...);
    lepton_init(&lepton0);

    /* TODO : complete this function */

    printf("Thermal image written to internal memory!\n");

    lepton_print_capture(&lepton0, true);

    printf("Thermal image written to serial console!\n");

    return EXIT_SUCCESS;
}

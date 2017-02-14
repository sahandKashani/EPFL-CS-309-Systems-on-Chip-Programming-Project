#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "io.h"
#include "system.h"

#include "lepton/lepton.h"

int main() {
    lepton_dev lepton0 = lepton_inst(LEPTON_0_BASE);
    lepton_init(&lepton0);

    /* TODO : complete this function */

    printf("Thermal image written to internal memory!\n");

    lepton_save_capture(&lepton0, true, "/mnt/host/output.pgm");

    printf("Thermal image written to host filesystem!\n");

    return EXIT_SUCCESS;
}

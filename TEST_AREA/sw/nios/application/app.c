#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "io.h"
#include "system.h"

#include "lepton/lepton.h"

int main() {
    lepton_dev lepton0 = lepton_inst(LEPTON_0_BASE);
    lepton_init(&lepton0);

    bool error = false;
    do {
        if (error) {
            printf("Synchronization error detected. Retrying...\n");
        }

        lepton_start_capture(&lepton0);
        lepton_wait_until_eof(&lepton0);
    } while ((error = lepton_error_check(&lepton0)));

    printf("Thermal image written to internal memory!\n");

    lepton_save_capture(&lepton0, true, "/mnt/host/output.pgm");

    printf("Thermal image written to host filesystem!\n");

    return EXIT_SUCCESS;
}

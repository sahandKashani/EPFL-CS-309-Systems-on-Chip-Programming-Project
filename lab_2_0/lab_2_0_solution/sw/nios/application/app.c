#include <io.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>

#include "lepton/lepton.h"
#include "system.h"

int main(void) {
    // Hardware control structures
    lepton_dev lepton = lepton_inst((void *) LEPTON_0_BASE);

    // Initialize hardware
    lepton_init(&lepton);

    bool capture_error = false;
    do {
        lepton_start_capture(&lepton);
        lepton_wait_until_eof(&lepton);
        capture_error = lepton_error_check(&lepton);
    } while (capture_error);

    printf("Thermal image written to internal memory!\n");

    // Save the adjusted (rescaled) buffer to a file.
    lepton_save_capture(&lepton, true, "/mnt/host/output.pgm");

    printf("Thermal image written to host filesystem!\n");

    return EXIT_SUCCESS;
}

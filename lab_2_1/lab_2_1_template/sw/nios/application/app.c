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

    // =========================================================================
    // TODO : use the lepton library to capture an image.
    //
    // Fill me!
    //
    // =========================================================================

    // Save the adjusted (rescaled) buffer to a file.
    lepton_save_capture(&lepton, true, "/mnt/host/output.pgm");

    return EXIT_SUCCESS;
}

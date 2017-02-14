#ifndef __LEPTON_H__
#define __LEPTON_H__

#include <stdbool.h>

typedef struct {
    void *base;
} lepton_dev;

lepton_dev lepton_inst(void *base);
void lepton_init(lepton_dev *dev);
void lepton_start_capture(lepton_dev *dev);
void lepton_wait_until_eof(lepton_dev *dev);
bool lepton_error_check(lepton_dev *dev);
void lepton_print_capture(lepton_dev *dev, bool adjusted);

#endif

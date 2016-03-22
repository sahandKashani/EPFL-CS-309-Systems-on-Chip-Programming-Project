#ifndef __LEPTON_H__
#define __LEPTON_H__
#include <stdbool.h>
typedef struct {
	void *base;
} lepton_dev;

lepton_dev lepton_open(void *base);
void lepton_start_capture(lepton_dev *dev);
void lepton_wait_until_eof(lepton_dev *dev);
void lepton_save_capture(lepton_dev *dev, bool adjusted);

#endif

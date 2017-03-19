#ifndef __LEPTON_H__
#define __LEPTON_H__

#include <stdbool.h>

/* lepton device structure */
typedef struct {
    void *base; /* Base address of the component */
} lepton_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/

lepton_dev lepton_inst(void *base);

void lepton_init(lepton_dev *dev);
void lepton_start_capture(lepton_dev *dev);
void lepton_wait_until_eof(lepton_dev *dev);
bool lepton_error_check(lepton_dev *dev);
void lepton_save_capture(lepton_dev *dev, bool adjusted, const char *fname);

#endif /* __LEPTON_H__ */

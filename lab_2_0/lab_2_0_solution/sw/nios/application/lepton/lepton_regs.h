#ifndef __LEPTON_REGS_H__
#define __LEPTON_REGS_H__

/* Register offsets */
#define LEPTON_REGS_COMMAND_OFST         (   0 * 2)  /* WO */
#define LEPTON_REGS_STATUS_OFST          (   1 * 2)  /* RO */
#define LEPTON_REGS_MIN_OFST             (   2 * 2)  /* RO */
#define LEPTON_REGS_MAX_OFST             (   3 * 2)  /* RO */
#define LEPTON_REGS_SUM_LSB_OFST         (   4 * 2)  /* RO */
#define LEPTON_REGS_SUM_MSB_OFST         (   5 * 2)  /* RO */
#define LEPTON_REGS_ROW_IDX_OFST         (   6 * 2)  /* RO */
#define LEPTON_REGS_RAW_BUFFER_OFST      (   8 * 2)  /* RO */
#define LEPTON_REGS_ADJUSTED_BUFFER_OFST (8192 * 2)  /* RO */

/* Command register */
#define LEPTON_COMMAND_START (0x0001)

/* Status register */
#define LEPTON_STATUS_CAPTURE_IN_PROGRESS_MASK (0x0001)
#define LEPTON_STATUS_ERROR_MASK               (0x0002)

#define LEPTON_REGS_BUFFER_NUM_PIXELS (80 * 60)
#define LEPTON_REGS_BUFFER_BYTELENGTH (LEPTON_REGS_BUFFER_NUM_PIXELS * 2)

#endif /* __LEPTON_REGS_H__ */

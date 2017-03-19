#ifndef __LEPTON_REGS_H__
#define __LEPTON_REGS_H__

#define LEPTON_REGS_COMMAND_OFST         (0x0000)  /* WO */
#define LEPTON_REGS_STATUS_OFST          (0x0002)  /* RO */
#define LEPTON_REGS_MIN_OFST             (0x0004)  /* RO */
#define LEPTON_REGS_MAX_OFST             (0x0006)  /* RO */
#define LEPTON_REGS_SUM_LSB_OFST         (0x0008)  /* RO */
#define LEPTON_REGS_SUM_MSB_OFST         (0x000a)  /* RO */
#define LEPTON_REGS_ROW_IDX_OFST         (0x000b)  /* RO */
#define LEPTON_REGS_BUFFER_OFST          (0x0010)  /* RO */
#define LEPTON_REGS_ADJUSTED_BUFFER_OFST (0x4000)  /* RO */

#define LEPTON_REGS_BUFFER_SIZE          (80 * 60)
#define LEPTON_REGS_BUFFER_BYTELENGTH    (LEPTON_REGS_BUFFER_SIZE * 2)

#endif /* __LEPTON_REGS_H__ */

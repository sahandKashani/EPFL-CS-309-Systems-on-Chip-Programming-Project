/*
  The response slave port only carries the actual bytes transferred,
  error, and early termination bits.  Reading from the upper most byte
  of the 2nd register pops the response FIFO.  For proper FIFO popping
  always read the actual bytes transferred followed by the error and early
  termination bits using 'little endian' accesses.  If a big endian
  master accesses the response slave port make sure that address 0x7 is the
  last byte lane access as it's the one that pops the reponse FIFO.

  If you use a pre-fetching descriptor master in front of the dispatcher
  port then you do not need to access this response slave port.
*/

#ifndef _MSGDMA_RESPONSE_REGS_H_
#define _MSGDMA_RESPONSE_REGS_H_

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#endif

#include "msgdma_io.h"

#define MSGDMA_RESPONSE_ACTUAL_BYTES_TRANSFERRED_REG      (0x0)
#define MSGDMA_RESPONSE_ERRORS_REG                        (0x4)

/* bits making up the "errors" register */
#define MSGDMA_RESPONSE_ERROR_MASK                        (0xff)
#define MSGDMA_RESPONSE_ERROR_OFFSET                      (0)
#define MSGDMA_RESPONSE_EARLY_TERMINATION_MASK            (1 << 8)
#define MSGDMA_RESPONSE_EARLY_TERMINATION_OFFSET          (8)

/* read macros for each 32 bit register */
#define MSGDMA_RD_RESPONSE_ACTUAL_BYTES_TRANSFFERED(base) msgdma_read_word((uint8_t *) (base) + MSGDMA_RESPONSE_ACTUAL_BYTES_TRANSFERRED_REG)
#define MSGDMA_RD_RESPONSE_ERRORS_REG(base)               msgdma_read_word((uint8_t *) (base) + MSGDMA_RESPONSE_ERRORS_REG)                   /* this read pops the response FIFO */

#endif /* _MSGDMA_RESPONSE_REGS_H_ */

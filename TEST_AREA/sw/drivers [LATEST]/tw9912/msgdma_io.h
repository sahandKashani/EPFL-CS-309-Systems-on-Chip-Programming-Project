#ifndef _MSGDMA_IO_H_
#define _MSGDMA_IO_H_

#ifdef __nios2_arch__
#include "io.h"

#define msgdma_write_byte(dest, src)  (IOWR_8DIRECT((dest), 0, (src)))
#define msgdma_write_hword(dest, src) (IOWR_16DIRECT((dest), 0, (src)))
#define msgdma_write_word(dest, src)  (IOWR_32DIRECT((dest), 0, (src)))

#define msgdma_read_word(src)         (IORD_32DIRECT((src), 0))

#else

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#endif

#define MSGDMA_CAST(type, ptr)        ((type) (ptr))

#define msgdma_write_byte(dest, src)  (*MSGDMA_CAST(volatile uint8_t *, (dest)) = (src))
#define msgdma_write_hword(dest, src) (*MSGDMA_CAST(volatile uint16_t *, (dest)) = (src))
#define msgdma_write_word(dest, src)  (*MSGDMA_CAST(volatile uint32_t *, (dest)) = (src))

#define msgdma_read_word(src)         (*MSGDMA_CAST(volatile uint32_t *, (src)))

#endif

#endif /* _MSGDMA_IO_H_ */

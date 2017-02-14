#ifndef _IO_CUSTOM_H_
#define _IO_CUSTOM_H_

/*
	Depending on how the file is compiled, the read/write operation to a memory location will call
	different routing functions.
*/

#ifdef __nios2_arch__

	#include "io.h"

	#define ioc_write_byte(base, off, val)  (IOWR_8DIRECT((base), (off), (val)))
	#define ioc_write_hword(base, off, val) (IOWR_16DIRECT((base), (off), (val)))
	#define ioc_write_word(base, off, val)  (IOWR_32DIRECT((base), (off), (val)))

	#define ioc_read_word(base, off)        (IORD_32DIRECT((base), (off)))
	#define ioc_read_hword(base, off)       (IORD_16DIRECT((base), (off)))

#else

	#if defined(__KERNEL__) || defined(MODULE)
		#include <linux/types.h>
		#include <linux/version.h>	
		#include <linux/printk.h>
		#include <asm/io.h>

		#define ioc_write_byte(base, off, val)  iowrite8((base) + (off), (val))
		#define ioc_write_hword(base, off, val) iowrite16((base) + (off), (val))
		#define ioc_write_word(base, off, val)  iowrite32((base) + (off), (val))

		#define ioc_read_word(base, off)        ioread32((base) + (off))
		#define ioc_read_hword(base, off)       ioread16((base) + (off))


	#else

		#include <stdint.h>
	
		#define IO_CUSTOM_CAST(type, ptr)  ((type) (ptr))

		#define ioc_write_byte(base, off, val)  (*IO_CUSTOM_CAST(volatile uint8_t *,  (base) + (off)) = (val))
		#define ioc_write_hword(base, off, val) (*IO_CUSTOM_CAST(volatile uint16_t *, (base) + (off)) = (val))
		#define ioc_write_word(base, off, val)  (*IO_CUSTOM_CAST(volatile uint32_t *, (base) + (off)) = (val))

		#define ioc_read_word(base, off)        (*IO_CUSTOM_CAST(volatile uint32_t *, (base) + (off)))
		#define ioc_read_hword(base, off)       (*IO_CUSTOM_CAST(volatile uint16_t *, (base) + (off)))


	#endif


#endif

#endif /* _IO_CUSTOM_H_ */

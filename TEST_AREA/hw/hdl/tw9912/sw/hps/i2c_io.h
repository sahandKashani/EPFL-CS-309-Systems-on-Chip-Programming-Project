#ifndef __I2C_IO_H__
#define __I2C_IO_H__

#ifdef __nios2_arch__
#include "io.h"

#define i2c_write_byte(dest, src) (IOWR_8DIRECT((dest), 0, (src)))
#define i2c_read_byte(src)        (IORD_8DIRECT((src), 0))

#else

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#endif

#define I2C_CAST(type, ptr)       ((type) (ptr))

#define i2c_write_byte(dest, src) (*I2C_CAST(volatile uint8_t *, (dest)) = (src))
#define i2c_read_byte(src)        (*I2C_CAST(volatile uint8_t *, (src)))

#endif

#endif /* __I2C_IO_H__ */

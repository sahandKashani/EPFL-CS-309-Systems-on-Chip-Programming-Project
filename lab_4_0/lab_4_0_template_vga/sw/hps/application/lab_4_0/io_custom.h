#ifndef __IO_CUSTOM__
#define __IO_CUSTOM__

#ifdef __nios2_arch__
    #include <io.h>

    #define ioc_write_8(base, ofst, data)  (IOWR_8DIRECT((base), (ofst), (data)))
    #define ioc_write_16(base, ofst, data) (IOWR_16DIRECT((base), (ofst), (data)))
    #define ioc_write_32(base, ofst, data) (IOWR_32DIRECT((base), (ofst), (data)))
    #define ioc_read_8(base, ofst)         (IORD_8DIRECT((base), (ofst)))
    #define ioc_read_16(base, ofst)        (IORD_16DIRECT((base), (ofst)))
    #define ioc_read_32(base, ofst)        (IORD_32DIRECT((base), (ofst)))

#else

    #include <socal/socal.h>

    #define ioc_write_8(base, ofst, data)  (alt_write_byte((uintptr_t) (base) + (ofst), (data)))
    #define ioc_write_16(base, ofst, data) (alt_write_hword((uintptr_t) (base) + (ofst), (data)))
    #define ioc_write_32(base, ofst, data) (alt_write_word((uintptr_t) (base) + (ofst), (data)))
    #define ioc_read_8(base, ofst)         (alt_read_byte((uintptr_t) (base) + (ofst)))
    #define ioc_read_16(base, ofst)        (alt_read_hword((uintptr_t) (base) + (ofst)))
    #define ioc_read_32(base, ofst)        (alt_read_word((uintptr_t) (base) + (ofst)))

#endif

#endif /* __IO_CUSTOM__ */

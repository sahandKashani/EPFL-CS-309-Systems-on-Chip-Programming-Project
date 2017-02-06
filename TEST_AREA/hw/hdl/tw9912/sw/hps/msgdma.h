/******************************************************************************
*                                                                             *
* License Agreement                                                           *
*                                                                             *
* Copyright (c) 2014 Altera Corporation, San Jose, California, USA.           *
* All rights reserved.                                                        *
*                                                                             *
* Permission is hereby granted, free of charge, to any person obtaining a     *
* copy of this software and associated documentation files (the "Software"),  *
* to deal in the Software without restriction, including without limitation   *
* the rights to use, copy, modify, merge, publish, distribute, sublicense,    *
* and/or sell copies of the Software, and to permit persons to whom the       *
* Software is furnished to do so, subject to the following conditions:        *
*                                                                             *
* The above copyright notice and this permission notice shall be included in  *
* all copies or substantial portions of the Software.                         *
*                                                                             *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     *
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER         *
* DEALINGS IN THE SOFTWARE.                                                   *
*                                                                             *
* This agreement shall be governed in all respects by the laws of the State   *
* of California and by the laws of the United States of America.              *
*                                                                             *
******************************************************************************/

#ifndef _MSGDMA_H_
#define _MSGDMA_H_

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/types.h>
#else
#include <stdint.h>
#endif

#include "msgdma_csr_regs.h"
#include "msgdma_descriptor_regs.h"
#include "msgdma_response_regs.h"

/*
 * To ensure that a descriptor is created without spaces
 * between the structure members, we call upon GCC's ability
 * to pack to a byte-aligned boundary.
 */
#define msgdma_standard_descriptor_packed __attribute__ ((packed, aligned(16)))
#define msgdma_extended_descriptor_packed __attribute__ ((packed, aligned(32)))
#define msgdma_response_packed __attribute__ ((packed, aligned(8)))

/* Callback routine type definition */
typedef void (*msgdma_callback)(void *context);

/* use this structure if you haven't enabled the enhanced features */
typedef struct {
    uint32_t *read_address;
    uint32_t *write_address;
    uint32_t transfer_length;
    uint32_t control;
} msgdma_standard_descriptor_packed msgdma_standard_descriptor;

/* use this structure if you have enabled the enhanced features (only the elements
enabled in hardware will be used) */
typedef struct {
    uint32_t *read_address_low;
    uint32_t *write_address_low;
    uint32_t transfer_length;
    uint16_t sequence_number;
    uint8_t  read_burst_count;
    uint8_t  write_burst_count;
    uint16_t read_stride;
    uint16_t write_stride;
    uint32_t *read_address_high;
    uint32_t *write_address_high;
    uint32_t control;
} msgdma_extended_descriptor_packed msgdma_extended_descriptor;

/* msgdma device structure */
typedef struct msgdma_dev {
    uint32_t        *csr_base;                 /* Base address of control and status register */
    uint32_t        *descriptor_base;          /* Base address of the descriptor slave port */
    uint32_t        *response_base;            /* Base address of the response register */
    uint32_t        descriptor_fifo_depth;     /* FIFO size to store descriptor count, { 8, 16, 32, 64,default:128, 256, 512, 1024 } */
    uint32_t        response_fifo_depth;       /* FIFO size to store response count */
    msgdma_callback callback;                  /* Callback routine pointer */
    void            *callback_context;         /* Callback context pointer */
    uint32_t        control;                   /* user define control setting during interrupt registering */
    uint8_t         burst_enable;              /* Enable burst transfer */
    uint8_t         burst_wrapping_support;    /* Enable burst wrapping */
    uint32_t        data_fifo_depth;           /* Depth of the internal data path FIFO */
    uint32_t        data_width;                /* Data path Width. This parameter affect both read master and write master data width */
    uint32_t        max_burst_count;           /* Maximum burst count */
    uint32_t        max_byte;                  /* Maximum transfer length */
    uint64_t        max_stride;                /* Maximum stride count */
    uint8_t         programmable_burst_enable; /* Enable dynamic burst programming */
    uint8_t         stride_enable;             /* Enable stride addressing */
    uint8_t         enhanced_features;         /* Extended feature support enable "1"-enable  "0"-disable */
    uint8_t         response_port;             /* Enable response port "0"-memory-mapped, "1"-streaming, "2"-disable */
} msgdma_dev;

/*******************************************************************************
 *  Public API
 ******************************************************************************/
msgdma_dev msgdma_csr_descriptor_response_inst(void *csr_base, void *descriptor_base, void *response_base, uint32_t descriptor_fifo_depth, uint32_t response_fifo_depth, uint8_t csr_burst_enable, uint8_t csr_burst_wrapping_support, uint32_t csr_data_fifo_depth, uint32_t csr_data_width, uint32_t csr_max_burst_count, uint32_t csr_max_byte, uint64_t csr_max_stride, uint8_t csr_programmable_burst_enable, uint8_t csr_stride_enable, uint8_t csr_enhanced_features, uint8_t csr_response_port);
msgdma_dev msgdma_csr_descriptor_inst(void *csr_base, void *descriptor_base, uint32_t descriptor_fifo_depth, uint8_t csr_burst_enable, uint8_t csr_burst_wrapping_support, uint32_t csr_data_fifo_depth, uint32_t csr_data_width, uint32_t csr_max_burst_count, uint32_t csr_max_byte, uint64_t csr_max_stride, uint8_t csr_programmable_burst_enable, uint8_t csr_stride_enable, uint8_t csr_enhanced_features, uint8_t csr_response_port);

void msgdma_init(msgdma_dev *dev);

void msgdma_register_callback(msgdma_dev *dev, msgdma_callback callback, uint32_t control, void *context);

/* Single-descriptor constructors */
int msgdma_construct_standard_mm_to_mm_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *read_address, void *write_address, uint32_t length, uint32_t control);
int msgdma_construct_standard_mm_to_st_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *read_address, uint32_t length, uint32_t control);
int msgdma_construct_standard_st_to_mm_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *write_address, uint32_t length, uint32_t control);
int msgdma_construct_extended_mm_to_mm_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *read_address, void *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint8_t write_burst_count, uint16_t read_stride, uint16_t write_stride);
int msgdma_construct_extended_mm_to_st_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *read_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint16_t read_stride);
int msgdma_construct_extended_st_to_mm_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t write_burst_count, uint16_t write_stride);

/* Single-descriptor transfers */
int msgdma_standard_descriptor_async_transfer(msgdma_dev *dev, msgdma_standard_descriptor *desc);
int msgdma_standard_descriptor_sync_transfer(msgdma_dev *dev, msgdma_standard_descriptor *desc);
int msgdma_extended_descriptor_async_transfer(msgdma_dev *dev, msgdma_extended_descriptor *desc);
int msgdma_extended_descriptor_sync_transfer(msgdma_dev *dev, msgdma_extended_descriptor *desc);

/* Helper functions */
void msgdma_wait_until_idle(msgdma_dev *dev);

#endif /* _MSGDMA_H_ */

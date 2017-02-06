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

#if defined(__KERNEL__) || defined(MODULE)
#include <linux/errno.h>
#include <linux/delay.h>
#include <linux/types.h>
#else
#include <errno.h>
#include <stdint.h>
#include <unistd.h>
#endif

#include "msgdma.h"

#define MSGMDA_TIMEOUT_US 5000

/*******************************************************************************
 *  Private API
 ******************************************************************************/
static int write_standard_descriptor(uint32_t *csr_base, uint32_t *descriptor_base, msgdma_standard_descriptor *descriptor);
static int write_extended_descriptor(uint32_t *csr_base, uint32_t *descriptor_base, msgdma_extended_descriptor *descriptor);
static void irq(void *context);
static int construct_standard_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, uint32_t *read_address, uint32_t *write_address, uint32_t length, uint32_t control);
static int construct_extended_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, uint32_t *read_address, uint32_t *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint8_t write_burst_count, uint16_t read_stride, uint16_t write_stride);
static int descriptor_async_transfer(msgdma_dev *dev, msgdma_standard_descriptor *standard_desc, msgdma_extended_descriptor *extended_desc);
static int descriptor_sync_transfer(msgdma_dev *dev, msgdma_standard_descriptor *standard_desc, msgdma_extended_descriptor *extended_desc);

/* Functions for accessing the control and status port */
static uint32_t read_csr_status(uint32_t *csr_base);
static uint32_t read_csr_control(uint32_t *csr_base);
static uint16_t read_csr_read_descriptor_buffer_fill_level(uint32_t *csr_base);
static uint16_t read_csr_write_descriptor_buffer_fill_level(uint32_t *csr_base);
static uint16_t read_csr_response_buffer_fill_level(uint32_t *csr_base);
static uint16_t read_csr_read_sequence_number(uint32_t *csr_base);
static uint16_t read_csr_write_sequence_number(uint32_t *csr_base);

/* Helper functions for reading/clearing individual status registers */
static uint32_t read_busy(uint32_t *csr_base);
static uint32_t read_descriptor_buffer_empty(uint32_t *csr_base);
static uint32_t read_descriptor_buffer_full(uint32_t *csr_base);
static uint32_t read_response_buffer_empty(uint32_t *csr_base);
static uint32_t read_response_buffer_full(uint32_t *csr_base);
static uint32_t read_stopped(uint32_t *csr_base);
static uint32_t read_resetting(uint32_t *csr_base);
static uint32_t read_stopped_on_error(uint32_t *csr_base);
static uint32_t read_stopped_on_early_termination(uint32_t *csr_base);
static uint32_t read_irq(uint32_t *csr_base);
static void clear_irq(uint32_t *csr_base);

/* Functions for writing the individual control registers */
static void stop_dispatcher(uint32_t *csr_base);
static void start_dispatcher(uint32_t *csr_base);
static void reset_dispatcher(uint32_t *csr_base);
static void enable_stop_on_error(uint32_t *csr_base);
static void disable_stop_on_error(uint32_t *csr_base);
static void enable_stop_on_early_termination(uint32_t *csr_base);
static void disable_stop_on_early_termination(uint32_t *csr_base);
static void enable_global_interrupt_mask(uint32_t *csr_base);
static void disable_global_interrupt_mask(uint32_t *csr_base);
static void stop_descriptors(uint32_t *csr_base);
static void start_descriptors(uint32_t *csr_base);

/* Function to put the host processor to sleep for microseconds */
static void msgdma_usleep(unsigned int useconds);

/*
 * Functions for writing descriptor structures to the dispatcher. If you disable
 * some of the extended features in the hardware then you should pass in 0 for
 * that particular descriptor element. These disabled elements will not be
 * buffered by the dispatcher block.
 *
 * This function is non-blocking and will return an error code if there is no
 * room to write another descriptor to the dispatcher.
 */
static int write_standard_descriptor(uint32_t *csr_base, uint32_t *descriptor_base, msgdma_standard_descriptor *descriptor) {
    if (read_descriptor_buffer_full(csr_base)) {
      /* descriptor buffer is full, returning so that this function is
       * non-blocking */
        return -ENOSPC;
    }

    MSGDMA_WR_DESCRIPTOR_READ_ADDRESS(descriptor_base, (uint32_t) descriptor->read_address);
    MSGDMA_WR_DESCRIPTOR_WRITE_ADDRESS(descriptor_base, (uint32_t) descriptor->write_address);
    MSGDMA_WR_DESCRIPTOR_LENGTH(descriptor_base, descriptor->transfer_length);
    MSGDMA_WR_DESCRIPTOR_CONTROL_STANDARD(descriptor_base, descriptor->control);
    return 0;
}

static int write_extended_descriptor(uint32_t *csr_base, uint32_t *descriptor_base, msgdma_extended_descriptor *descriptor) {
    if (read_descriptor_buffer_full(csr_base)) {
      /* descriptor buffer is full, returning so that this function is
       * non-blocking */
        return -ENOSPC;
    }

    MSGDMA_WR_DESCRIPTOR_READ_ADDRESS(descriptor_base, (uint32_t) descriptor->read_address_low);
    MSGDMA_WR_DESCRIPTOR_WRITE_ADDRESS(descriptor_base, (uint32_t) descriptor->write_address_low);
    MSGDMA_WR_DESCRIPTOR_LENGTH(descriptor_base, descriptor->transfer_length);
    MSGDMA_WR_DESCRIPTOR_SEQUENCE_NUMBER(descriptor_base, descriptor->sequence_number);
    MSGDMA_WR_DESCRIPTOR_READ_BURST(descriptor_base, descriptor->read_burst_count);
    MSGDMA_WR_DESCRIPTOR_WRITE_BURST(descriptor_base, descriptor->write_burst_count);
    MSGDMA_WR_DESCRIPTOR_READ_STRIDE(descriptor_base, descriptor->read_stride);
    MSGDMA_WR_DESCRIPTOR_WRITE_STRIDE(descriptor_base, descriptor->write_stride);
    MSGDMA_WR_DESCRIPTOR_READ_ADDRESS_HIGH(descriptor_base, 0);
    MSGDMA_WR_DESCRIPTOR_WRITE_ADDRESS_HIGH(descriptor_base, 0);
    MSGDMA_WR_DESCRIPTOR_CONTROL_ENHANCED(descriptor_base, descriptor->control);
    return 0;
}

/*
 * irq
 *
 * Interrupt handler for the Modular Scatter-Gather DMA controller.
 */
static void irq(void *context) {
    msgdma_dev *dev = (msgdma_dev *) context;
    uint32_t temporary_control = 0;

    /* disable global interrupt */
    temporary_control = MSGDMA_RD_CSR_CONTROL(dev->csr_base) & (~MSGDMA_CSR_GLOBAL_INTERRUPT_MASK);
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, temporary_control);
    /* clear the IRQ status */
    MSGDMA_WR_CSR_STATUS(dev->csr_base, MSGDMA_CSR_IRQ_SET_MASK);

    if (dev->callback) {
        dev->callback(dev->callback_context);
    }

    /* enable global interrupt */
    temporary_control = MSGDMA_RD_CSR_CONTROL(dev->csr_base) | (MSGDMA_CSR_GLOBAL_INTERRUPT_MASK);
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, temporary_control);
}

/*
 * Helper functions for constructing mm_to_st, st_to_mm, mm_to_mm standard
 * descriptors. Unnecessary elements are set to 0 for completeness and will be
 * ignored by the hardware.
 *
 * Returns: 0       -> success
 *          -EINVAL -> invalid argument, could be due to an argument which
 *                     has a larger value than hardware's max value
 */
static int construct_standard_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, uint32_t *read_address, uint32_t *write_address, uint32_t length, uint32_t control) {
    if (dev->max_byte < length || dev->enhanced_features != 0) {
        return -EINVAL;
    }

    descriptor->read_address = read_address;
    descriptor->write_address = write_address;
    descriptor->transfer_length = length;
    descriptor->control = control | MSGDMA_DESCRIPTOR_CONTROL_GO_MASK;

    return 0;
}

/*
 * Helper functions for constructing mm_to_st, st_to_mm, mm_to_mm extended
 * descriptors. Unnecessary elements are set to 0 for completeness and will be
 * ignored by the hardware.
 *
 * Returns: 0       -> success
 *          -EINVAL -> invalid argument, could be due to an argument which
 *                     has a larger value than hardware's max value
 */
static int construct_extended_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, uint32_t *read_address, uint32_t *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint8_t write_burst_count, uint16_t read_stride, uint16_t write_stride) {
    if (dev->max_byte < length || dev->max_stride < read_stride || dev->max_stride < write_stride || dev->enhanced_features != 1) {
        return -EINVAL;
    }

    descriptor->read_address_low = read_address;
    descriptor->write_address_low = write_address;
    descriptor->transfer_length = length;
    descriptor->sequence_number = sequence_number;
    descriptor->read_burst_count = read_burst_count;
    descriptor->write_burst_count = write_burst_count;
    descriptor->read_stride = read_stride;
    descriptor->write_stride = write_stride;
    descriptor->read_address_high = NULL;
    descriptor->write_address_high = NULL;
    descriptor->control = control | MSGDMA_DESCRIPTOR_CONTROL_GO_MASK;

    return 0 ;
}

/*
 * Helper function for an async descriptor transfer.
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) structure.
 * - *standard_desc: Pointer to single standard descriptor.
 * - *extended_desc: Pointer to single extended descriptor.
 *
 * Note: Either one of both *standard_desc and *extended_desc must
 *       be assigned with NULL, another with proper pointer value.
 *       Failing to do so can cause the function return with "-EPERM"
 *
 * If a callback routine has been previously registered with this
 * particular msgdma controller, the transfer will be set up to enable interrupt
 * generation. It is the responsibility of the application developer to check
 * source interruption, status completion and creating suitable interrupt
 * handling.
 *
 * Note: "stop on error" of CSR control register is always masking within this
 *       function. The CSR control can be set by user through calling
 *       "alt_register_callback" by passing user used defined control setting.
 *
 * Returns: 0       -> success
 *          -ENOSPC -> FIFO descriptor buffer is full
 *          -EPERM  -> operation not permitted due to descriptor type conflict
 *          -ETIME  -> Time out and skipping the looping after 5 msec
 */
static int descriptor_async_transfer(msgdma_dev *dev, msgdma_standard_descriptor *standard_desc, msgdma_extended_descriptor *extended_desc) {
    uint32_t control = 0;
    uint16_t counter = 0;
    uint32_t fifo_read_fill_level = read_csr_read_descriptor_buffer_fill_level(dev->csr_base);
    uint32_t fifo_write_fill_level = read_csr_write_descriptor_buffer_fill_level(dev->csr_base);

    /* Return with error immediately if one of read/write buffer is full */
    if ((dev->descriptor_fifo_depth <= fifo_write_fill_level) || (dev->descriptor_fifo_depth <= fifo_read_fill_level)) {
        /* at least one write or read FIFO descriptor buffer is full,
        returning so that this function is non-blocking */
        return -ENOSPC;
    }

    /* Stop the msgdma dispatcher from issuing more descriptors to the read or
     * write masters */

    /* Stop issuing more descriptors */
    control = MSGDMA_CSR_STOP_DESCRIPTORS_MASK;
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, control);

    /*
     * Clear any (previous) status register information
     * that might occlude our error checking later.
     */
    MSGDMA_WR_CSR_STATUS(dev->csr_base, MSGDMA_RD_CSR_STATUS(dev->csr_base));

    if (NULL != standard_desc && NULL == extended_desc) {
        /* writing descriptor structure to the dispatcher, wait until descriptor
           write is succeed */
        while (0 != write_standard_descriptor(dev->csr_base, dev->descriptor_base, standard_desc)) {
            msgdma_usleep(1); /* delay 1us */
            if(MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
                return -ETIME;
            }
            counter++;
        }
    } else if (NULL == standard_desc && NULL != extended_desc) {
        counter = 0; /* reset counter */
        /* writing descriptor structure to the dispatcher, wait until descriptor
           write is succeed */
        while (0 != write_extended_descriptor(dev->csr_base, dev->descriptor_base, extended_desc)) {
            msgdma_usleep(1); /* delay 1us */
            if(MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
                return -ETIME;
            }
            counter++;
        }
    } else {
        /* operation not permitted due to descriptor type conflict */
        return -EPERM;
    }

    /*
     * If a callback routine has been previously registered, then it will be
     * called from the msgdma ISR. Set up controller to:
     *  - Run
     *  - Stop on an error with any particular descriptor
     */
    if (dev->callback) {
        control |= (dev->control | MSGDMA_CSR_STOP_ON_ERROR_MASK | MSGDMA_CSR_GLOBAL_INTERRUPT_MASK);
        control &=  (~MSGDMA_CSR_STOP_DESCRIPTORS_MASK);
        MSGDMA_WR_CSR_CONTROL(dev->csr_base, control);
    } else {
        /*
         * No callback has been registered. Set up controller to:
         *   - Run
         *   - Stop on an error with any particular descriptor
         *   - Disable interrupt generation
         */
        control |= (dev->control | MSGDMA_CSR_STOP_ON_ERROR_MASK);
        control &= (~MSGDMA_CSR_STOP_DESCRIPTORS_MASK) & (~MSGDMA_CSR_GLOBAL_INTERRUPT_MASK);
        MSGDMA_WR_CSR_CONTROL(dev->csr_base, control);
    }

    return 0;
}

/*
 * Helper function for a sync descriptor transfer.
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) structure.
 * - *standard_desc: Pointer to single standard descriptor.
 * - *extended_desc: Pointer to single extended descriptor.
 *
 * Note: Either one of both *standard_desc and *extended_desc must
 *       be assigned with NULL, another with proper pointer value.
 *       Failing to do so can cause the function return with "-EPERM"
 *
 * "stop on error" of CSR control register is always being masked and interrupt
 * is always disabled within this function.
 * The CSR control can be set by user through calling "alt_register_callback"
 * with passing user defined control setting.
 *
 * Returns: 0      -> success
 *          -EPERM -> operation not permitted due to descriptor type conflict
 *          -ETIME -> Time out and skipping the looping after 5 msec
 */
static int descriptor_sync_transfer(msgdma_dev *dev, msgdma_standard_descriptor *standard_desc, msgdma_extended_descriptor *extended_desc) {
    uint32_t control = 0;
    uint32_t csr_status = 0;
    uint16_t counter = 0;
    uint32_t fifo_read_fill_level = read_csr_read_descriptor_buffer_fill_level(dev->csr_base);
    uint32_t fifo_write_fill_level = read_csr_write_descriptor_buffer_fill_level(dev->csr_base);
    uint32_t error = MSGDMA_CSR_STOPPED_ON_ERROR_MASK | MSGDMA_CSR_STOPPED_ON_EARLY_TERMINATION_MASK | MSGDMA_CSR_STOP_STATE_MASK | MSGDMA_CSR_RESET_STATE_MASK;

    /* Wait for available FIFO buffer to store new descriptor */
    while ((dev->descriptor_fifo_depth <= fifo_write_fill_level) || (dev->descriptor_fifo_depth <= fifo_read_fill_level)) {
        msgdma_usleep(1); /* delay 1us */
        if (MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
            return -ETIME;
        }
        counter++;
        fifo_read_fill_level = read_csr_read_descriptor_buffer_fill_level(dev->csr_base);
        fifo_write_fill_level = read_csr_write_descriptor_buffer_fill_level(dev->csr_base);
    }

    /* Stop the msgdma dispatcher from issuing more descriptors to the read or
     * write masters */
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, MSGDMA_CSR_STOP_DESCRIPTORS_MASK);
    /*
     * Clear any (previous) status register information that might occlude our
     * error checking later.
     */
    MSGDMA_WR_CSR_STATUS(dev->csr_base, MSGDMA_RD_CSR_STATUS(dev->csr_base));

    if (NULL != standard_desc && NULL == extended_desc) {
        counter = 0; /* reset counter */
        /* writing descriptor structure to the dispatcher, wait until descriptor
           write is succeed */
        while (0 != write_standard_descriptor(dev->csr_base, dev->descriptor_base, standard_desc)) {
            msgdma_usleep(1); /* delay 1us */
            if (MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
                return -ETIME;
            }
            counter++;
        }
    } else if (NULL == standard_desc && NULL != extended_desc) {
        counter = 0; /* reset counter */
        /* writing descriptor structure to the dispatcher, wait until descriptor
           write is succeed */
        while (0 != write_extended_descriptor(dev->csr_base, dev->descriptor_base, extended_desc)) {
            msgdma_usleep(1); /* delay 1us */
            if (MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
                return -ETIME;
            }
            counter++;
        }
    } else {
        /* operation not permitted due to descriptor type conflict */
        return -EPERM;
    }

    /*
     * Set up msgdma controller to:
     * - Disable interrupt generation
     * - Run once a valid descriptor is written to controller
     * - Stop on an error with any particular descriptor
     */
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, (dev->control | MSGDMA_CSR_STOP_ON_ERROR_MASK ) & (~MSGDMA_CSR_STOP_DESCRIPTORS_MASK) & (~MSGDMA_CSR_GLOBAL_INTERRUPT_MASK));

    counter = 0; /* reset counter */

    csr_status = MSGDMA_RD_CSR_STATUS(dev->csr_base);

    /* Wait for any pending transfers to complete or checking any errors or
       conditions causing descriptor to stop dispatching */
    while (!(csr_status & error) && (csr_status & MSGDMA_CSR_BUSY_MASK)) {
        msgdma_usleep(1); /* delay 1us */
        if (MSGMDA_TIMEOUT_US <= counter) { /* time_out if waiting longer than 5 msec */
            return -ETIME;
        }
        counter++;
        csr_status = MSGDMA_RD_CSR_STATUS(dev->csr_base);
    }


    /* Errors or conditions causing the dispatcher stopping issuing read/write
       commands to masters*/
    if (0 != (csr_status & error)) {
        return error;
    }

    /* Stop the msgdma dispatcher from issuing more descriptors to the
       read or write masters  */

    /* stop issuing more descriptors */
    control = MSGDMA_RD_CSR_CONTROL(dev->csr_base) | MSGDMA_CSR_STOP_DESCRIPTORS_MASK;
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, control);

    /*
     * Clear any (previous) status register information that might occlude our
     * error checking later.
     */
    MSGDMA_WR_CSR_STATUS(dev->csr_base, MSGDMA_RD_CSR_STATUS(dev->csr_base));

    return 0;
}

/* Functions for accessing the control and status port */
static uint32_t read_csr_status(uint32_t *csr_base) {
    return MSGDMA_RD_CSR_STATUS(csr_base);
}

static uint32_t read_csr_control(uint32_t *csr_base) {
    return MSGDMA_RD_CSR_CONTROL(csr_base);
}

static uint16_t read_csr_read_descriptor_buffer_fill_level(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_DESCRIPTOR_FILL_LEVEL(csr_base) & MSGDMA_CSR_READ_FILL_LEVEL_MASK) >> MSGDMA_CSR_READ_FILL_LEVEL_OFFSET;
}

static uint16_t read_csr_write_descriptor_buffer_fill_level(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_DESCRIPTOR_FILL_LEVEL(csr_base) & MSGDMA_CSR_WRITE_FILL_LEVEL_MASK) >> MSGDMA_CSR_WRITE_FILL_LEVEL_OFFSET;
}

static uint16_t read_csr_response_buffer_fill_level(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_RESPONSE_FILL_LEVEL(csr_base) & MSGDMA_CSR_RESPONSE_FILL_LEVEL_MASK) >> MSGDMA_CSR_RESPONSE_FILL_LEVEL_OFFSET;
}

static uint16_t read_csr_read_sequence_number(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_SEQUENCE_NUMBER(csr_base) & MSGDMA_CSR_READ_SEQUENCE_NUMBER_MASK) >> MSGDMA_CSR_READ_SEQUENCE_NUMBER_OFFSET;
}

static uint16_t read_csr_write_sequence_number(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_SEQUENCE_NUMBER(csr_base) & MSGDMA_CSR_WRITE_SEQUENCE_NUMBER_MASK) >> MSGDMA_CSR_WRITE_SEQUENCE_NUMBER_OFFSET;
}

/* Functions for reading/clearing individual status registers */
/* returns '1' when the dispatcher is busy */
static uint32_t read_busy(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_BUSY_MASK) != 0;
}

/* returns '1' when both descriptor buffers are empty */
static uint32_t read_descriptor_buffer_empty(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_DESCRIPTOR_BUFFER_EMPTY_MASK) != 0;
}

/* returns '1' when either descriptor buffer is full */
static uint32_t read_descriptor_buffer_full(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_DESCRIPTOR_BUFFER_FULL_MASK) != 0;
}

/* returns '1' when the response buffer is empty */
static uint32_t read_response_buffer_empty(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_RESPONSE_BUFFER_EMPTY_MASK) != 0;
}

/* returns '1' when the response buffer is full */
static uint32_t read_response_buffer_full(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_RESPONSE_BUFFER_FULL_MASK) != 0;
}

/* returns '1' when the MSGDMA is stopped (either due to application writing to the stop bit or an error condition that stopped the MSGDMA) */
static uint32_t read_stopped(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_STOP_STATE_MASK) != 0;
}

/* returns '1' when the MSGDMA is in the middle of a reset (read/write masters are still resetting) */
static uint32_t read_resetting(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_RESET_STATE_MASK) != 0;
}

/* returns '1' when the MSGDMA ia stopped due to an error entering the write master component (one of the conditions that will cause 'dispatcher_stopped' to return a '1') */
static uint32_t read_stopped_on_error(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_STOPPED_ON_ERROR_MASK) != 0;
}

/* returns '1' when the MSGDMA is stopped due to the eop not arriving at the write master streaming port before the length counter reaches 0 (one of the conditions that will cause 'dispatcher_stopped' to return a '1') */
static uint32_t read_stopped_on_early_termination(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_STOPPED_ON_EARLY_TERMINATION_MASK) != 0;
}

/* returns '1' when the MSGDMA is asserting the interrupt signal (no pre-fetching descriptor master) */
static uint32_t read_irq(uint32_t *csr_base) {
    return (MSGDMA_RD_CSR_STATUS(csr_base) & MSGDMA_CSR_IRQ_SET_MASK) != 0;
}

/* the status register is read/clear-only so a read-modify-write is not necessary */
static void clear_irq(uint32_t *csr_base) {
    MSGDMA_WR_CSR_STATUS(csr_base, MSGDMA_CSR_IRQ_SET_MASK);
}

/* Functions for writting the individual control registers */
static void stop_dispatcher(uint32_t *csr_base) {
    /* setting the stop mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) | MSGDMA_CSR_STOP_MASK;
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void start_dispatcher(uint32_t *csr_base) {
    /* resetting the stop mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) & (MSGDMA_CSR_STOP_MASK ^ 0xffffffff);
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void reset_dispatcher(uint32_t *csr_base) {
    /* setting the reset bit, no need to read the control register first since
     * this write is going to clear it out */
    MSGDMA_WR_CSR_CONTROL(csr_base, MSGDMA_CSR_RESET_MASK);
}

static void enable_stop_on_error(uint32_t *csr_base) {
    /* setting the stop on error mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) | MSGDMA_CSR_STOP_ON_ERROR_MASK;
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void disable_stop_on_error(uint32_t *csr_base) {
    /* reseting the stop on error mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) & (MSGDMA_CSR_STOP_ON_ERROR_MASK ^ 0xffffffff);
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void enable_stop_on_early_termination(uint32_t *csr_base) {
    /* setting the stop on early termination mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) | MSGDMA_CSR_STOP_ON_EARLY_TERMINATION_MASK;
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void disable_stop_on_early_termination(uint32_t *csr_base) {
    /* resetting the stop on early termination mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) & (MSGDMA_CSR_STOP_ON_EARLY_TERMINATION_MASK ^ 0xffffffff);
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void enable_global_interrupt_mask(uint32_t *csr_base) {
    /* setting the global interrupt mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) | MSGDMA_CSR_GLOBAL_INTERRUPT_MASK;
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void disable_global_interrupt_mask(uint32_t *csr_base) {
    /* resetting the global interrupt mask bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) & (MSGDMA_CSR_GLOBAL_INTERRUPT_MASK ^ 0xffffffff);
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void stop_descriptors(uint32_t *csr_base) {
    /* setting the stop descriptors bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) | MSGDMA_CSR_STOP_DESCRIPTORS_MASK;
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

static void start_descriptors(uint32_t *csr_base) {
    /* resetting the stop descriptors bit */
    uint32_t temporary_control = MSGDMA_RD_CSR_CONTROL(csr_base) & (MSGDMA_CSR_STOP_DESCRIPTORS_MASK ^ 0xffffffff);
    MSGDMA_WR_CSR_CONTROL(csr_base, temporary_control);
}

/* Function to put the host processor to sleep for microseconds */
static void msgdma_usleep(unsigned int useconds) {
#if defined(__KERNEL__) || defined(MODULE)
    udelay(useconds);
#else
    usleep(useconds);
#endif
}

/*******************************************************************************
 *  Public API
 ******************************************************************************/
/*
 * Functions for constructing device structures. Unnecessary elements are set to
 * 0 for completeness and will be ignored by the hardware.
 */
msgdma_dev msgdma_csr_descriptor_response_inst(void *csr_base, void *descriptor_base, void *response_base, uint32_t descriptor_fifo_depth, uint32_t response_fifo_depth, uint8_t csr_burst_enable, uint8_t csr_burst_wrapping_support, uint32_t csr_data_fifo_depth, uint32_t csr_data_width, uint32_t csr_max_burst_count, uint32_t csr_max_byte, uint64_t csr_max_stride, uint8_t csr_programmable_burst_enable, uint8_t csr_stride_enable, uint8_t csr_enhanced_features, uint8_t csr_response_port) {
    msgdma_dev dev;

    dev.csr_base                  = csr_base;
    dev.descriptor_base           = descriptor_base;
    dev.response_base             = response_base;
    dev.descriptor_fifo_depth     = descriptor_fifo_depth;
    dev.response_fifo_depth       = response_fifo_depth * 2;
    dev.callback                  = (void *) 0x0;
    dev.callback_context          = (void *) 0x0;
    dev.control                   = 0;
    dev.burst_enable              = csr_burst_enable;
    dev.burst_wrapping_support    = csr_burst_wrapping_support;
    dev.data_fifo_depth           = csr_data_fifo_depth;
    dev.data_width                = csr_data_width;
    dev.max_burst_count           = csr_max_burst_count;
    dev.max_byte                  = csr_max_byte;
    dev.max_stride                = csr_max_stride;
    dev.programmable_burst_enable = csr_programmable_burst_enable;
    dev.stride_enable             = csr_stride_enable;
    dev.enhanced_features         = csr_enhanced_features;
    dev.response_port             = csr_response_port;

    return dev;
}

msgdma_dev msgdma_csr_descriptor_inst(void *csr_base, void *descriptor_base, uint32_t descriptor_fifo_depth, uint8_t csr_burst_enable, uint8_t csr_burst_wrapping_support, uint32_t csr_data_fifo_depth, uint32_t csr_data_width, uint32_t csr_max_burst_count, uint32_t csr_max_byte, uint64_t csr_max_stride, uint8_t csr_programmable_burst_enable, uint8_t csr_stride_enable, uint8_t csr_enhanced_features, uint8_t csr_response_port) {
    msgdma_dev dev;

    dev.csr_base                  = csr_base;
    dev.descriptor_base           = descriptor_base;
    dev.response_base             = (uint32_t *) 0;
    dev.descriptor_fifo_depth     = descriptor_fifo_depth;
    dev.response_fifo_depth       = 0;
    dev.callback                  = (void *) 0x0;
    dev.callback_context          = (void *) 0x0;
    dev.control                   = 0;
    dev.burst_enable              = csr_burst_enable;
    dev.burst_wrapping_support    = csr_burst_wrapping_support;
    dev.data_fifo_depth           = csr_data_fifo_depth;
    dev.data_width                = csr_data_width;
    dev.max_burst_count           = csr_max_burst_count;
    dev.max_byte                  = csr_max_byte;
    dev.max_stride                = csr_max_stride;
    dev.programmable_burst_enable = csr_programmable_burst_enable;
    dev.stride_enable             = csr_stride_enable;
    dev.enhanced_features         = csr_enhanced_features;
    dev.response_port             = csr_response_port;

    return dev;
}

/*
 * msgdma_init
 *
 * Initializes the Modular Scatter-Gather DMA controller.
 *
 * This routine disables interrupts and descriptor processing.
 */
void msgdma_init(msgdma_dev *dev) {
    uint32_t temporary_control;

    /* Reset the registers and FIFOs of the dispatcher and master modules */

    /* set the reset bit, no need to read the control register first since
    this write is going to clear it out */
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, MSGDMA_CSR_RESET_MASK);
    while (0 != (MSGDMA_RD_CSR_STATUS(dev->csr_base) & MSGDMA_CSR_RESET_STATE_MASK));

    /*
     * Disable interrupts, halt descriptor processing,
     * and clear status register content
     */

    /* disable global interrupt */
    temporary_control = MSGDMA_RD_CSR_CONTROL(dev->csr_base) & (~MSGDMA_CSR_GLOBAL_INTERRUPT_MASK);
    /* stopping descriptor */
    temporary_control |= MSGDMA_CSR_STOP_DESCRIPTORS_MASK;
    MSGDMA_WR_CSR_CONTROL(dev->csr_base, temporary_control);

    /* clear the CSR status register */
    MSGDMA_WR_CSR_STATUS(dev->csr_base, MSGDMA_RD_CSR_STATUS(dev->csr_base));
}

/*
 * msgdma_register_callback
 *
 * Associate a user-specific routine with the msgdma interrupt handler.
 * If a callback is registered, all non-blocking msgdma transfers will
 * enable interrupts that will cause the callback to be executed.
 * The callback runs as part of the interrupt service routine, and
 * great care must be taken to follow the guidelines for acceptable
 * interrupt service routine behaviour. However, the user can change some of the
 * CSR control settings in a blocking transfer by calling this function.
 *
 * Note: To disable callbacks after registering one, this routine
 * may be called passing 0x0 to the callback argument.
 *
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) structure.
 * - callback: Pointer to callback routine to execute at interrupt level
 * - control: For masking the source interruption and setting configuration in
 *            control register
 */
void msgdma_register_callback(msgdma_dev *dev, msgdma_callback callback, uint32_t control, void *context) {
    dev->callback         = callback;
    dev->callback_context = context;
    dev->control          = control;
}

/*
 * Functions for constructing standard descriptors. Unnecessary elements are set
 * to 0 for completeness and will be ignored by the hardware.
 *
 * Returns: 0       -> success
 *          -EINVAL -> invalid argument, could be due to argument which
 *                     has larger value than hardware setting value
 */
int msgdma_construct_standard_mm_to_mm_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *read_address, void *write_address, uint32_t length, uint32_t control) {
    return construct_standard_descriptor(dev, descriptor, read_address, write_address, length, control);
}

int msgdma_construct_standard_mm_to_st_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *read_address, uint32_t length, uint32_t control) {
    return construct_standard_descriptor(dev, descriptor, read_address, NULL, length, control);
}

int msgdma_construct_standard_st_to_mm_descriptor(msgdma_dev *dev, msgdma_standard_descriptor *descriptor, void *write_address, uint32_t length, uint32_t control) {
    return construct_standard_descriptor(dev, descriptor, NULL, write_address, length, control);
}

/*
 * Functions for constructing extended descriptors. If you disable some of the
 * extended features in the hardware then you should pass in 0 for that
 * particular descriptor element. These disabled elements will not be buffered
 * by the dispatcher block.
 *
 * Returns: 0       -> success
 *          -EINVAL -> invalid argument, could be due to argument which
 *                     has larger value than hardware setting value
 */
int msgdma_construct_extended_mm_to_mm_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *read_address, void *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint8_t write_burst_count, uint16_t read_stride, uint16_t write_stride) {
    return construct_extended_descriptor(dev, descriptor, read_address, write_address, length, control, sequence_number, read_burst_count, write_burst_count, read_stride, write_stride);
}

int msgdma_construct_extended_mm_to_st_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *read_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t read_burst_count, uint16_t read_stride) {
    return construct_extended_descriptor(dev, descriptor, read_address, NULL, length, control, sequence_number, read_burst_count, 0, read_stride, 0);
}

int msgdma_construct_extended_st_to_mm_descriptor(msgdma_dev *dev, msgdma_extended_descriptor *descriptor, void *write_address, uint32_t length, uint32_t control, uint16_t sequence_number, uint8_t write_burst_count, uint16_t write_stride) {
    return construct_extended_descriptor(dev, descriptor, NULL, write_address, length, control, sequence_number, 0, write_burst_count, 0, write_stride);
}

/*
 * msgdma_standard_descriptor_async_transfer
 *
 * Set up and start a non-blocking transfer of one descriptor.
 *
 * If the FIFO buffer for one of read/write is full at the time of this call,
 * the routine will immediately return -ENOSPC, the application can then decide
 * how to proceed without being blocked.
 *
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) struct.
 * - *desc: Pointer to single (ready to run) descriptor.
 *
 * Returns: 0       -> success
 *          -ENOSPC -> FIFO descriptor buffer is full
 *          -EPERM  -> operation not permitted due to descriptor type conflict
 *          -ETIME  -> Time out and skipping the looping after 5 msec
 */
int msgdma_standard_descriptor_async_transfer(msgdma_dev *dev, msgdma_standard_descriptor *desc) {
    return descriptor_async_transfer(dev, desc, NULL);
}

/*
 * msgdma_standard_descriptor_sync_transfer
 *
 * This function will start a blocking transfer of one standard descriptor.
 * If the FIFO buffer for one of read/write is full at the time of this call,
 * the routine will wait until a free position in the FIFO buffer is available
 * to continue processing.
 *
 * Additional error information is available in the status bits of each
 * descriptor that the msgdma processed; it is the responsibility of the user's
 * application to search through the descriptor to gather specific error
 * information.
 *
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) structure.
 * - *desc: Pointer to single (ready to run) descriptor.
 *
 * Returns: 0      -> success
 *          -EPERM -> operation not permitted due to descriptor type conflict
 *          -ETIME -> Time out and skipping the looping after 5 msec
 */
int msgdma_standard_descriptor_sync_transfer(msgdma_dev *dev, msgdma_standard_descriptor *desc) {
    return descriptor_sync_transfer(dev, desc, NULL);
}

/*
 * msgdma_extended_descriptor_async_transfer
 *
 * Set up and start a non-blocking transfer of one descriptors at a time.
 *
 * If the FIFO buffer for one of read/write is full at the time of this call,
 * the routine will immediately return -ENOSPC, the application can then
 * decide how to proceed without being blocked.
 *
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) struct.
 * - *desc: Pointer to single (ready to run) descriptor.
 *
 * Returns: 0       -> success
 *          -ENOSPC -> FIFO descriptor buffer is full
 *          -EPERM  -> operation not permitted due to descriptor type conflict
 *          -ETIME  -> Time out and skipping the looping after 5 msec
 */
int msgdma_extended_descriptor_async_transfer(msgdma_dev *dev, msgdma_extended_descriptor *desc) {
    return descriptor_async_transfer(dev, NULL, desc);
}

/*
 * msgdma_extended_descriptor_sync_transfer
 *
 * This function will start a blocking transfer of one extended descriptor.
 * If the FIFO buffer for one of read/write is full at the time of this call,
 * the routine will wait until free FIFO buffer available to continue processing.
 *
 * Additional error information is available in the status bits of each
 * descriptor that the msgdma processed; it is the responsibility of the user's
 * application to search through the descriptor to gather specific error
 * information.
 *
 * Arguments:
 * - *dev: Pointer to msgdma device (instance) structure.
 * - *desc: Pointer to single (ready to run) descriptor.
 *
 * Returns: 0      -> success
 *          -EPERM -> operation not permitted due to descriptor type
 *                    conflict
 *          -ETIME -> Time out and skipping the looping after 5 msec
 */
int msgdma_extended_descriptor_sync_transfer(msgdma_dev *dev, msgdma_extended_descriptor *desc) {
    return descriptor_sync_transfer(dev, NULL, desc);
}

/* Helper functions */
void msgdma_wait_until_idle(msgdma_dev *dev) {
    while (read_busy(dev->csr_base) != 0);
}

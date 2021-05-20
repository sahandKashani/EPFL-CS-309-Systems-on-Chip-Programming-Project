/**
 * @author Philemon Favrod
 * @brief Example of ping-pong buffering using the framebuffer.
 */

// Compile with the following command:
//
//   arm-linux-gnueabihf-gcc -std=gnu99 fb_multiple_buffering_example.c -o fb_multiple_buffering_example

#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdint.h>
#include <assert.h>
#include <sys/mman.h>
#include <linux/fb.h>
#include <unistd.h>

struct fb_fix_screeninfo fix_info;
struct fb_var_screeninfo var_info;
uint32_t *frame_buffer;
int num_buffers;
int num_pixels_per_buffer;
int fb_fd;

uint32_t make_color(uint8_t red, uint8_t green, uint8_t blue)
{
    uint32_t r = red   << var_info.red.offset;
    uint32_t g = green << var_info.green.offset;
    uint32_t b = blue  << var_info.blue.offset;
    return r | g | b;
}

int main(void)
{
    fb_fd = open("/dev/fb0", O_RDWR);
    assert(fb_fd >= 0);

    // Get screen information
    int ret = ioctl(fb_fd, FBIOGET_FSCREENINFO, &fix_info);
    assert(ret >= 0);

    ret = ioctl(fb_fd, FBIOGET_VSCREENINFO, &var_info);
    assert(ret >= 0);

    // Map the frame buffer in user memory
    frame_buffer = mmap(NULL, var_info.yres_virtual * fix_info.line_length, PROT_READ | PROT_WRITE, MAP_SHARED, fb_fd, 0);
    assert(frame_buffer != MAP_FAILED);

    // Reminder: with prsoc_fbdev driver the number of buffer can be changed in the device tree
    num_buffers = (var_info.yres_virtual * var_info.xres_virtual) / (var_info.xres * var_info.yres);
    num_pixels_per_buffer = var_info.yres * var_info.xres;

    int buffer_idx;
    for (buffer_idx = 0; buffer_idx < num_buffers; ++buffer_idx) {

        // Compute the color of the buffer
        // Buffers 0, 3, 6, ... will be red
        // Buffers 1, 4, 7, ... will be green
        // Buffers 2, 5, 8, ... will be blue
        uint32_t color = make_color(0xff, 0, 0);
        if (buffer_idx % 3 == 1) {
            color = make_color(0, 0xff, 0);
        } else if (buffer_idx % 3 == 2) {
            color = make_color(0, 0, 0xff);
        }

        int pixel_idx;
        for (pixel_idx = buffer_idx * num_pixels_per_buffer; pixel_idx < (buffer_idx + 1) * num_pixels_per_buffer; ++pixel_idx) {
            frame_buffer[pixel_idx] = color;
        }
    }

    while (1) {
        int i;

        for (i = 0; i < num_buffers; ++i) {
            var_info.yoffset = i * var_info.yres;
            ret = ioctl(fb_fd, FBIOPAN_DISPLAY, &var_info);
            assert(ret >= 0);

            usleep(3000000);
        }
    }


    return 0;
}

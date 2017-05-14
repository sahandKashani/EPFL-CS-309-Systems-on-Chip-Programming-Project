/*
 * @file prsoc_vga_fbdev 
 * @author Philemon Favrod
 * @date 18 May 2016
 * @brief The framebuffer Linux driver for the PrSoC extension board.
 *
 * This file is divided in two sections. The first contains the framebuffer
 * driver code. The second contains the boilerplate code to create the
 * device associated with the framebuffer. The latter allow us to use
 * much less error-prone APIs (devm_* or dma_*).
 *
 * Revisions:
 *  5/18/2016 Created (only for simple VGA)
 *  5/28/2016 Adapted for TFT043
 *  5/28/2016 Extended with mmap support
 */ 

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/io.h>
#include <linux/fb.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/of_device.h>
#include <linux/interrupt.h>
#include <linux/dma-mapping.h>
#include <linux/types.h>

/* Offsets of the framebuffer manager's registers. */
#define FM_REG_FRAME_START_ADDRESS 0x00
#define FM_REG_FRAME_PIX_PER_LINE  0x04
#define FM_REG_FRAME_NUM_LINES     0x08
#define FM_REG_FRAME_EOL_BYTE_OFST 0x0C
#define FM_REG_CONTROL             0x10
#define FM_REG_BURST_COUNT         0x14


#define FM_CONTROL_ENABLE_DMA_MASK      (1UL << 0)
#define FM_CONTROL_ENABLE_IRQ_MASK      (1UL << 2)
#define FM_CONTROL_ACKNOWLEDGE_IRQ_MASK (1UL << 4)


#define FM_WR(DRVDATA, REG, VAL) \
  iowrite32((VAL), (DRVDATA)->fm_regs + (REG))


/* Offsets of the VGA sequencer's registers. */
#define VGA_SEQUENCER_REG_CSR   0x00
#define VGA_SEQUENCER_REG_HBP   0x04
#define VGA_SEQUENCER_REG_HFP   0x08
#define VGA_SEQUENCER_REG_VBP   0x0c
#define VGA_SEQUENCER_REG_VFP   0x10
#define VGA_SEQUENCER_REG_HDATA 0x14
#define VGA_SEQUENCER_REG_VDATA 0x18
#define VGA_SEQUENCER_REG_HSYNC 0x1c
#define VGA_SEQUENCER_REG_VSYNC 0x20

#define VGA_SEQUENCER_WR(DRVDATA, REG, VAL) \
  iowrite32((VAL), (DRVDATA)->int_regs + (REG))
#define VGA_SEQUENCER_START(DRVDATA) \
  VGA_SEQUENCER_WR(DRVDATA, VGA_SEQUENCER_REG_CSR, 1U << 3)

#define ER_TFT043_WIDTH 480
#define ER_TFT043_HEIGHT 272
#define ER_TFT043_SIZE (ER_TFT043_WIDTH * ER_TFT043_HEIGHT * 4)
#define ER_TFT043_VSYNC 10
#define ER_TFT043_VBP 2
#define ER_TFT043_VDATA 272
#define ER_TFT043_VFP 3
#define ER_TFT043_HSYNC 41
#define ER_TFT043_HBP 47
#define ER_TFT043_HDATA 480
#define ER_TFT043_HFP 8

struct prsoc_display_drvdata {
  uint8_t  *fm_regs;
  uint8_t  *int_regs;
  uint32_t *back_buffer;
  uint32_t *front_buffer;
  unsigned long front_buffer_phys;
  int irq;
};

/* Framebuffer driver */

/* ISR called at the end of each frame. Called at the beginning
 * of the vertical back porch, i.e. as soon as possible to avoid
 * tearing effect. */
static irqreturn_t vertical_blanking_isr(int irq, void *data)
{
  /*printk("IRQ received.\n");*/
  
  int i;
  struct prsoc_display_drvdata *drvdata = data;

  /* Acknowledge the IRQ */
  FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ACKNOWLEDGE_IRQ_MASK);
  
  /* Copy the back buffer into the front buffer. */
  for (i = 0; i < ER_TFT043_HEIGHT * ER_TFT043_WIDTH; ++i)
    drvdata->front_buffer[i] = drvdata->back_buffer[i];
  
  return IRQ_HANDLED;
}

static struct fb_fix_screeninfo prsocfb_fix = {
  .id          = "prsocfb",
  .type        = FB_TYPE_PACKED_PIXELS,
  .visual      = FB_VISUAL_DIRECTCOLOR,
  .line_length = ER_TFT043_WIDTH * sizeof(uint32_t),
  .accel       = FB_ACCEL_NONE,
};

static struct fb_var_screeninfo prsocfb_var = {
  .xres = ER_TFT043_WIDTH,
  .yres = ER_TFT043_HEIGHT,
  .xres_virtual = ER_TFT043_WIDTH,
  .yres_virtual = ER_TFT043_HEIGHT,
  .bits_per_pixel = 32,
  .red   = { .offset = 16, .length = 8 },
  .green = { .offset =  8, .length = 8 },
  .blue  = { .offset =  0, .length = 8 }
};

uint32_t pseudo_palette[16];
static int prsocfb_setcoloreg(unsigned regno, unsigned red,
                              unsigned green, unsigned blue,
                              unsigned transp, struct fb_info *info)
{
  if (regno >= 16)
    return -EINVAL;

  red   *= 0xff;
  green *= 0xff;
  blue  *= 0xff;

  red   /= 0xffff;
  green /= 0xffff;
  blue  /= 0xffff;

  pseudo_palette[regno] = (red << 16) | (green << 8) | blue;
  return 0;
}

/* purpose: mmap the back buffer. */
static int prsocfb_mmap(struct fb_info *info,
                        struct vm_area_struct *vma)
{
  unsigned long start = vma->vm_start;
  unsigned long size = vma->vm_end - vma->vm_start;
  unsigned long screen_size = info->screen_size;
  unsigned long offset = vma->vm_pgoff << PAGE_SHIFT;
  unsigned long pfn = -1;
  uint8_t *pos = info->screen_base + offset;

  //printk(KERN_INFO "prsocfb: mmapping the fb device\n");

  /* Compute the screen size in PAGE_SIZE. */
  screen_size += PAGE_SIZE - 1;
  screen_size >>= PAGE_SHIFT;
  screen_size <<= PAGE_SHIFT;
  
  /* Make sure that it maps only the back buffer */
  if (offset + size > screen_size) {
    printk(KERN_ERR "prsocfb: trying to mmap too much memory. %lu %lu %lu\n",
           offset, size, screen_size);
    return -EINVAL;
  }

  while (size > 0) {
    /* Extract the page number of the current position
     * in the buffer. */
    pfn = vmalloc_to_pfn(pos);

    /* Map it in the user virtual memory. */
    if (remap_pfn_range(vma, start, pfn, PAGE_SIZE, PAGE_SHARED)) {
      printk(KERN_ERR "prsocfb: remap_pfn_range failed\n");
      return -EAGAIN;
    }

    start += PAGE_SIZE;
    pos   += PAGE_SIZE;

    if (size > PAGE_SIZE)
      size -= PAGE_SIZE;
    else
      size = 0;
  }

  return 0;
}

static struct fb_ops prsocfb_ops = {
  .owner = THIS_MODULE,
  .fb_setcolreg = prsocfb_setcoloreg,
  .fb_fillrect = cfb_fillrect,
  .fb_copyarea = cfb_copyarea,
  .fb_imageblit = cfb_imageblit,
  .fb_mmap = prsocfb_mmap
};

/* Platform driver */

/* Informs the kernel of the corresponding compatible string. */
static const struct of_device_id prsoc_display_device_ids[] = {
  { .compatible = "prsoc,display" },
  { }
};
MODULE_DEVICE_TABLE(of, prsoc_display_device_ids);

/* Setup the typical TFT043 timings. */
static void configure_tft043_timings(struct prsoc_display_drvdata *drvdata)
{
  /* Vertical timings */
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_VSYNC, ER_TFT043_VSYNC);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_VBP, ER_TFT043_VBP);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_VDATA, ER_TFT043_VDATA);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_VFP, ER_TFT043_VFP);

  /* Horizontal timings */
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_HSYNC, ER_TFT043_HSYNC);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_HBP, ER_TFT043_HBP);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_HDATA, ER_TFT043_HDATA);
  VGA_SEQUENCER_WR(drvdata, VGA_SEQUENCER_REG_HFP, ER_TFT043_HFP);
}

/* 
 * The following method is called when the driver is loaded. 
 * It collects information from the device tree.
 */
static int
prsoc_display_platform_probe(struct platform_device *pdev)
{
  struct prsoc_display_drvdata *drvdata;
  struct resource *rsrc;
  struct fb_info *info;
  dma_addr_t phys;
  int err, i;
  
  /* Defensive programming: let's make sure this is the right device. */
  if (!of_match_device(prsoc_display_device_ids, &pdev->dev))
    return -EINVAL;

  /* Allocate the framebuffer. */
  info = framebuffer_alloc(sizeof(struct prsoc_display_drvdata), &pdev->dev);
  if (!info) {
    return -ENOMEM;
  }

  /* Extract the allocated driver data structure. */
  drvdata = (struct prsoc_display_drvdata *)info->par;
    
  /* Maps the addresses of the registers of the framebuffer manager. */
  rsrc = platform_get_resource(pdev, IORESOURCE_MEM, 0);
  drvdata->fm_regs = devm_ioremap_resource(&pdev->dev, rsrc);
  if (IS_ERR(drvdata->fm_regs))
    return PTR_ERR(drvdata->fm_regs);

  printk(KERN_INFO "Framebuffer manager regs @ 0x%x-0x%x\n",
         rsrc->start, rsrc->end);
  
  /* Maps the addresses of the video interface. */
  rsrc = platform_get_resource(pdev, IORESOURCE_MEM, 1);
  drvdata->int_regs = devm_ioremap_resource(&pdev->dev, rsrc);
  if (IS_ERR(drvdata->int_regs))
    return PTR_ERR(drvdata->int_regs);

  printk(KERN_INFO "Interface regs @ 0x%x-0x%x\n", rsrc->start,
         rsrc->end);
  
  /* Register the ISR for vertical blanking notification. */
  drvdata->irq = platform_get_irq(pdev, 0);
  err = devm_request_irq(&pdev->dev, drvdata->irq,
			   (irq_handler_t) vertical_blanking_isr,
			   0, "prsoc-fbdev", drvdata);
  if (err) {
    printk(KERN_ERR "couldn't register ISR. Is 'interrupts' " \
	   "field in the device tree?\n");
    return -ENXIO;
  }

  /* Allocate DMA-compatible front buffer. */
  drvdata->front_buffer = dmam_alloc_coherent(&pdev->dev, ER_TFT043_SIZE,
  			  		      &phys, GFP_KERNEL);
  if (!drvdata->front_buffer) {
    printk(KERN_ERR "prsoc_fbdev: couldn't allocate a dmable buffer.\n");
    return -ENOMEM;
  }

  drvdata->front_buffer_phys = (unsigned long)phys;
  printk(KERN_INFO "DMABLE BUFFER @ %lu\n", drvdata->front_buffer_phys);
  
  /* Allocate the back buffer in kernel virtual memory. */
  drvdata->back_buffer = vzalloc(ER_TFT043_SIZE); /* TODO free it */
  if (!drvdata->back_buffer)
    return -ENOMEM;
  
  platform_set_drvdata(pdev, drvdata);

  printk(KERN_INFO "Fill the front buffer with blue.\n");

  /* Temporary: draw a blue screen. */
  for (i = 0; i < ER_TFT043_HEIGHT * ER_TFT043_WIDTH; ++i) {
    drvdata->front_buffer[i] = 0xff;
  }

  printk(KERN_INFO "Configure the VGA sequencer.\n");
  configure_tft043_timings(drvdata);

  printk(KERN_INFO "Configure and start the DMA\n");
  FM_WR(drvdata, FM_REG_FRAME_START_ADDRESS, drvdata->front_buffer_phys + 0x80000000);
  FM_WR(drvdata, FM_REG_FRAME_PIX_PER_LINE, ER_TFT043_WIDTH);
  FM_WR(drvdata, FM_REG_FRAME_NUM_LINES, ER_TFT043_HEIGHT);
  FM_WR(drvdata, FM_REG_FRAME_EOL_BYTE_OFST, 0);
  FM_WR(drvdata, FM_REG_BURST_COUNT, 4);
  FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ENABLE_DMA_MASK);

  /* Enable IRQ */
  FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ENABLE_IRQ_MASK);
  
  printk(KERN_INFO "Start the VGA sequencer.\n");
  VGA_SEQUENCER_START(drvdata);

  
  /* Configure the framebuffer */
  info->screen_base = (void *)drvdata->back_buffer;
  info->screen_size = ER_TFT043_SIZE;
  info->fbops = &prsocfb_ops;
  info->fix = prsocfb_fix;
  info->var = prsocfb_var;
  info->pseudo_palette = pseudo_palette;
  info->flags = FBINFO_DEFAULT;
  
  if (fb_alloc_cmap(&info->cmap, 256, 0))
      return -ENOMEM;
  
  return register_framebuffer(info);
}

static struct platform_driver prsoc_display_pdriver = {
  .probe = prsoc_display_platform_probe,
  .driver = {
    .name = "PrSoC displays",
    .owner = THIS_MODULE,
    .of_match_table = prsoc_display_device_ids,
  },
};

MODULE_LICENSE("GPL");
module_platform_driver(prsoc_display_pdriver);

/*
 * @file prsoc_vga_fbdev
 * @author Philemon Favrod
 * @date 18 May 2016
 * @brief The framebuffer Linux driver for the PrSoC extension board.
 *
 * This file is divided in two sections. The first contains the framebuffer
 * driver code. The second contains the boilerplate code to create the
 * device associated with the framebuffer. The latter allow us to use
 * much less error-prone APIs (devm_* or dmam_*).
 *
 * More precisely, the LCD is viewed as a platform device, i.e. a device
 * that is directly addressable from the CPU. Platform device are loaded
 * based on their compatible string (here "prsoc,display"). In other words,
 * once this driver is known to the kernel (c.f. insmod), the kernel will
 * call its associated probe function if its associated compatible string
 * is present in a device node (= an element of the device tree).
 *
 * In our case, the probe function is prsoc_display_platform_probe that you
 * can find at the end of this file. Its main role is to allocate the resources
 * based on what the device tree says. It uses the so-called managed API to
 * do so. This API has the advantage of letting the kernel do the clean up based on
 * whether or not the driver is loaded. It makes the code more readable.
 * At the end of the probe function, the framebuffer is registered.
 *
 * For more information about this, here is a collection of resources that
 * might be helpful:
 * - https://www.kernel.org/doc/Documentation/driver-model/platform.txt
 * -
 *
 * Revisions:
 *  5/18/2016 Created (only for simple VGA)
 *  5/28/2016 Adapted for TFT043
 *  5/28/2016 Extended with mmap support
 *  6/15/2016 Extend configurability from DT + panning
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
#include <linux/delay.h>

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

/* Offsets of the lt24_sequencer's registers */
#define LT24_SEQUENCER_REG_WRITE_CMD       0x00
#define LT24_SEQUENCER_REG_WRITE_DATA      0x04
#define LT24_SEQUENCER_REG_LCD_ON          0x08
#define LT24_SEQUENCER_REG_DATA_SRC_SELECT 0x0c


/* Enclose the driver data. */
struct prsoc_display_drvdata {
  uint8_t  *fm_regs;  /* a pointer to the frame manager's regs */
  uint8_t  *lcd_int_regs; /* a pointer to the LCD interface's regs */

  uint32_t *front_buffer; /* a dmable frame buffer */
  unsigned long front_buffer_phys; /* physical address of the frame buffer */
  int irq;
};

#define FM_WR(DRVDATA, REG, VAL) \
  iowrite32((VAL), (DRVDATA)->fm_regs + (REG))
#define LCD_INTERFACE_WR(DRVDATA, REG, VAL) \
  iowrite32((VAL), (DRVDATA)->lcd_int_regs + (REG))

/* Framebuffer driver */

/* ISR called at the end of each frame. Called at the beginning
 * of the vertical back porch, i.e. as soon as possible to avoid
 * tearing effect. */
static irqreturn_t vsync_isr(int irq, void *data)
{
  /*printk("IRQ received.\n");*/

  //int i;
  struct prsoc_display_drvdata *drvdata = data;

  /* Acknowledge the IRQ */
  FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ACKNOWLEDGE_IRQ_MASK);

  return IRQ_HANDLED;
}

/* Defaults screen parameters */
static struct fb_fix_screeninfo prsocfb_fix_defaults = {
  .id          = "prsocfb",
  .type        = FB_TYPE_PACKED_PIXELS,
  .visual      = FB_VISUAL_DIRECTCOLOR,
  .accel       = FB_ACCEL_NONE,
  .ypanstep    = 1 // support y panning
};

static struct fb_var_screeninfo prsocfb_var_defaults = {
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

int prsocfb_pan_display(struct fb_var_screeninfo *var, struct fb_info *info)
{
  struct prsoc_display_drvdata *drvdata = (struct prsoc_display_drvdata *)info->par;
  uint32_t byte_offset;

  if ((var->yoffset + var->yres > var->yres_virtual) ||
      (var->xoffset + var->xres > var->xres_virtual))
  {
    return -EINVAL;
  }

  byte_offset = (var->yoffset * info->fix.line_length) +
    (var->xoffset * (var->bits_per_pixel / 8));

  FM_WR(drvdata, FM_REG_FRAME_START_ADDRESS, drvdata->front_buffer_phys + byte_offset);

  return 0;
}


/* purpose: mmap the front buffer. */
static int prsocfb_mmap(struct fb_info *info,
                        struct vm_area_struct *vma)
{
  struct prsoc_display_drvdata *drvdata = (struct prsoc_display_drvdata *)info->par;
  unsigned long start = vma->vm_start;
  unsigned long size = vma->vm_end - vma->vm_start;
  unsigned long screen_size = info->var.xres_virtual * info->var.yres_virtual * sizeof(uint32_t);
  unsigned long offset = vma->vm_pgoff << PAGE_SHIFT;
  unsigned long pfn = -1;
  void * pos = phys_to_virt(drvdata->front_buffer_phys) + offset;

  vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot); // non cachable page
  vma->vm_flags |= VM_IO;

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
    pfn = virt_to_pfn(pos);

    /* Map it in the user virtual memory. */
    if (remap_pfn_range(vma, start, pfn, PAGE_SIZE, vma->vm_page_prot)) {
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
  .fb_mmap = prsocfb_mmap,
  .fb_pan_display = prsocfb_pan_display
};

/* Platform driver */

/* Informs the kernel of the corresponding compatible string. */
static const struct of_device_id prsoc_display_device_ids[] = {
  { .compatible = "prsoc,display" },
  { }
};
MODULE_DEVICE_TABLE(of, prsoc_display_device_ids);

/* To understand Device tree parsing, see:
 * - http://xillybus.com/tutorials/device-tree-zynq-4
 * - http://xillybus.com/tutorials/device-tree-zynq-5
 */
#define EXTRACT_INT_FROM_DT_OR_FAIL(NP, PROP) ({                \
  const void *property = of_get_property((NP), (PROP), NULL);   \
  if (!property) {                                              \
    printk(KERN_ERR "no '" PROP "' in the device tree.");       \
    return -EINVAL;                                             \
  }                                                             \
  be32_to_cpup(property);                                       \
})

/* Apply configuration from device tree. */
static int configure_from_dt(
  struct platform_device       *pdev,
  struct prsoc_display_drvdata *drvdata,
  struct fb_fix_screeninfo     *fix_screeninfo,
  struct fb_var_screeninfo     *var_screeninfo)
{
  struct resource *rsrc;
  int err, i;

  const __be32 *properties;
  int len;

  /* Extract a pointer to the device node. */
  struct device_node *np = pdev->dev.of_node;
  dma_addr_t phys;

  /* Get the width and height properties. */
  uint32_t screen_width  = EXTRACT_INT_FROM_DT_OR_FAIL(np, "prsoc,screen-width");
  uint32_t screen_height = EXTRACT_INT_FROM_DT_OR_FAIL(np, "prsoc,screen-height");
  uint32_t buffer_width  = EXTRACT_INT_FROM_DT_OR_FAIL(np, "prsoc,buffer-width");
  uint32_t buffer_height = EXTRACT_INT_FROM_DT_OR_FAIL(np, "prsoc,buffer-height");

  printk(KERN_INFO "According to the device tree, the screen is %ux%u and the buffer is %ux%u.",
    screen_width, screen_height, buffer_width, buffer_height);

  /* Maps the addresses of the registers of the framebuffer manager. */
  rsrc = platform_get_resource(pdev, IORESOURCE_MEM, 0);
  drvdata->fm_regs = devm_ioremap_resource(&pdev->dev, rsrc);
  if (IS_ERR(drvdata->fm_regs))
    return PTR_ERR(drvdata->fm_regs);

  printk(KERN_INFO "Framebuffer manager regs @ 0x%x-0x%x\n",
         rsrc->start, rsrc->end);

  /* Maps the addresses of the video interface. */
  rsrc = platform_get_resource(pdev, IORESOURCE_MEM, 1);
  drvdata->lcd_int_regs = devm_ioremap_resource(&pdev->dev, rsrc);
  if (IS_ERR(drvdata->lcd_int_regs))
    return PTR_ERR(drvdata->lcd_int_regs);

  printk(KERN_INFO "Interface regs @ 0x%x-0x%x\n", rsrc->start,
         rsrc->end);

  /* Register the ISR for vertical blanking notification. */
  drvdata->irq = platform_get_irq(pdev, 0);
  err = devm_request_irq(
        &pdev->dev, drvdata->irq,
        (irq_handler_t) vsync_isr,
        0, "prsoc-fbdev", drvdata);
  if (err) {
    printk(KERN_ERR "couldn't register ISR. Is 'interrupts' " \
     "field in the device tree?\n");
    return -ENXIO;
  }

  /* Set the screeninfo to default values */
  *fix_screeninfo = prsocfb_fix_defaults;
  *var_screeninfo = prsocfb_var_defaults;

  /* Set the size properties */
  var_screeninfo->xres = screen_width;
  var_screeninfo->yres = screen_height;
  var_screeninfo->xres_virtual = buffer_width;
  var_screeninfo->yres_virtual = buffer_height;
  fix_screeninfo->line_length = screen_width * sizeof(uint32_t);

  /* Allocate DMAble frame buffer. */
  drvdata->front_buffer = dmam_alloc_coherent(
    &pdev->dev,
    buffer_width * buffer_height * sizeof(uint32_t),
    &phys,
    GFP_KERNEL);

  if (!drvdata->front_buffer) {
    printk(KERN_ERR "prsoc_fbdev: couldn't allocate a dmable buffer.\n");
    return -ENOMEM;
  }

  drvdata->front_buffer_phys = (unsigned long)phys;
  printk(KERN_INFO "DMABLE BUFFER @ 0x%lx\n", drvdata->front_buffer_phys);

  /* Parse the reg-init sequence */
  properties = of_get_property(pdev->dev.of_node, "prsoc,reg-init", &len);

  if (!properties) {
    printk(KERN_INFO "no 'prsoc,reg-init' property found in Device Tree.\n");
    return 0; // reg-init is optional
  }

  len /= sizeof(__be32);

  if (len % 2 != 0) {
    printk(KERN_ERR "'prsoc,reg-init' in Device Tree should have format <ADDR1 VAL1>, <ADDR2 VAL2>, ...\n");
    return -EINVAL;
  }

  printk(KERN_INFO "Initialize registers as specified in Device Tree:\n");
  for (i = 0; i < len; i += 2) {
    uint32_t offset = be32_to_cpup(properties + i);
    uint32_t value  = be32_to_cpup(properties + i + 1);
    LCD_INTERFACE_WR(drvdata, offset, value);
    printk(KERN_INFO "\tWrite 0x%x at offset 0x%x\n", value, offset);
  }

  return 0;
}

/*
 * Initialization sequence of ILI9341 in LT24 display.
 */
void LCD_Init(struct prsoc_display_drvdata *drvdata) {

    // software reset
    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0001);

    // Wait 120ms for LCD bringup.
    msleep(120);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0011); //Exit Sleep
    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00CF); // Power Control B
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // Always 0x00
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0081);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0X00c0);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00ED);     // Power on sequence control
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0064); // Soft Start Keep 1 frame
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0003);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0X0012);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0X0081);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00E8);     // Driver timing control A
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0085);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0001);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x00798);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00CB);     // Power control A
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0039);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x002C);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0034);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0002);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00F7);     // Pump ratio control
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0020);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00EA);     // Driver timing control B
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00B1);     // Frame rate control (In Normal Mode)
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x001b);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00C0);    //Power control 1
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0005);   //VRH[5:0]

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00C1);    //Power control 2
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0011);   //SAP[2:0];BT[3:0]

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00C5);    //VCM control 1
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0045);       //3F
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0045);       //3C

     LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00C7);    //VCM control 2
         LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0X00a2);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0036); // Memory access control (MADCTL B5 = 1)
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0028); // MY MX MV ML_BGR MH 0 0 -> 0b0010 1000

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00F2);    // 3Gamma Function Disable
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0026);    //Gamma curve selected
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0001);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00E0);    //Set Gamma
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000F);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0026);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0024);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000b);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000E);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0008);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x004b);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0X00a8);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x003b);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000a);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0014);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0006);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0010);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0009);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0X00E1);    // Negative Gamma Correction; Set Gamma
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x001c);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0020);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0004);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0010);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0008);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0034);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0047);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0044);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0005);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000b);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0009);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x002f);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0036);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x000f);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x002A); // Column Address Set
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x00ef);

     LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x002B); // Page Address Set
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0001);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x003f);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x003A); // COLMOD: Pixel Format Set
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0055);

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x00f6); // Interface control
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0001);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0030);
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000);

    // LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0029); // Display on.

    // Landscape mode.
    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0036); // Memory access control (MADCTL B5 = 1)
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0028); // MY MX MV ML_BGR MH 0 0 -> 0b0010 1000

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x002A); // Column Address Set
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // SC0-7
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // SC8-15 -> 0x0000
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0001); // EC0-7
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x003F); // EC8-15 -> 0x013F

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x002B); // Page Address Set
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // SP0-7
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // SP8-15 -> 0x0000
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x0000); // EP0-7
        LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_DATA, 0x00EF); // EP8-15 -> 0x00EF

    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x0029); // Display on.

    // Switch datapath multiplexor to pixel data.
    LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_DATA_SRC_SELECT, 1);

    // Do NOT send 0x2c command in the initialization sequence. This command
    // tells the LT24 to expect pixel data as future commands. Since the
    // framebuffer_manager CONTINUOUSLY sends frames to the LT24_controller, the
    // controller has to generate the 0x2c command itself before sending each
    // frame. This is done directly in hardware.
    // LCD_INTERFACE_WR(drvdata, LT24_SEQUENCER_REG_WRITE_CMD, 0x002c); // Memory write.s
}

/*
 * The following method is called when the driver is loaded.
 * It collects information from the device tree.
 */
static int
prsoc_display_platform_probe(struct platform_device *pdev)
{
  struct prsoc_display_drvdata *drvdata;
  struct fb_info *info;

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

  platform_set_drvdata(pdev, drvdata);

  printk(KERN_INFO "Configure from Device Tree.\n");
  configure_from_dt(pdev, drvdata, &info->fix, &info->var);

  printk(KERN_INFO "Initialize the LT24 display.\n");
  LCD_Init(drvdata);

  printk(KERN_INFO "Initialize the Frame Manager.\n");
  FM_WR(drvdata, FM_REG_FRAME_START_ADDRESS, drvdata->front_buffer_phys);
  FM_WR(drvdata, FM_REG_FRAME_PIX_PER_LINE, info->var.xres);
  FM_WR(drvdata, FM_REG_FRAME_NUM_LINES, info->var.yres);
  FM_WR(drvdata, FM_REG_FRAME_EOL_BYTE_OFST, 0);
  FM_WR(drvdata, FM_REG_BURST_COUNT, 4);
  FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ENABLE_DMA_MASK);

  /* Enable IRQ */
  // FM_WR(drvdata, FM_REG_CONTROL, FM_CONTROL_ENABLE_IRQ_MASK);

  /* Configure the framebuffer */
  info->screen_base = (void *)drvdata->front_buffer;
  info->screen_size = info->var.xres * info->var.yres * sizeof(uint32_t);
  info->fbops = &prsocfb_ops;
  info->pseudo_palette = pseudo_palette;
  info->flags = FBINFO_DEFAULT;

  if (fb_alloc_cmap(&info->cmap, 256, 0))
      return -ENOMEM;

  return register_framebuffer(info);
}

int prsoc_display_platform_remove(struct platform_device *pdev)
{
  struct prsoc_display_drvdata *drvdata = platform_get_drvdata(pdev);
  struct fb_info *info = container_of((void *)drvdata, struct fb_info, par);

  unregister_framebuffer(info);
  fb_dealloc_cmap(&info->cmap);
  framebuffer_release(info);

  printk(KERN_INFO "Removing prsoc display driver.\n");

  return 0;
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

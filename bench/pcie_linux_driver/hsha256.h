#ifndef HSHA256_H
#define HSHA256_H

#include "linux/compiler_attributes.h"
#include <asm/uaccess.h>
#include <linux/cdev.h>
#include <linux/errno.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/ioport.h>
#include <linux/kernel.h>
#include <linux/kfifo.h>
#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/slab.h>
#include <linux/types.h>

#include <linux/delay.h>
#include <linux/device.h>
#include <linux/err.h>
#include <linux/of.h>
#include <linux/platform_device.h>

#include <linux/dma-mapping.h>

#include <linux/completion.h>
#include <linux/dma-buf.h>
#include <linux/dma-mapping.h>
#include <linux/dmaengine.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/pm.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/uaccess.h>
#include <linux/wait.h>

#include <linux/clk.h>
#include <linux/gfp.h>
#include <linux/interrupt.h>
#include <linux/pagemap.h>
#include <linux/sched.h>
#include <linux/vmalloc.h>

#include <linux/ioport.h>
#include <linux/miscdevice.h>
#include <linux/moduleparam.h>
#include <linux/notifier.h>

#include <linux/time.h>
#include <linux/timer.h>

struct sha256_unit {
    __u32 status;   // 0x00
    __u32 reg1;     // 0x04
    __u32 reg2;     // 0x08
    __u32 reg3;     // 0x0c
    __u32 place[4]; // 0x10
    __u32 hash[8];  // 0x20
} __packed;

#define SHA256_STATUS_RESET 0x00000001
#define SHA256_STATUS_BUSY 0x00000100

#define SHA256_IS_BUSY(u) (ioread32(&((u)->status)) & SHA256_STATUS_BUSY)

#endif
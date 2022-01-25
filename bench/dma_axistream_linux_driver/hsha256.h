#ifndef HSHA256_H
#define HSHA256_H

#include <linux/types.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/slab.h>
#include <linux/kfifo.h>
#include <linux/errno.h>
#include <linux/io.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/interrupt.h>
#include <linux/ioport.h>
#include <asm/uaccess.h>

#include <linux/platform_device.h>
#include <linux/err.h>
#include <linux/device.h>
#include <linux/of.h>
#include <linux/delay.h>

#include <linux/dma-mapping.h>

#include <linux/pm.h>
#include <linux/slab.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/dma-buf.h>
#include <linux/string.h>
#include <linux/uaccess.h>
#include <linux/dma-mapping.h>
#include <linux/dmaengine.h>
#include <linux/completion.h>
#include <linux/wait.h>

#include <linux/sched.h>
#include <linux/pagemap.h>
#include <linux/clk.h>
#include <linux/interrupt.h>
#include <linux/vmalloc.h>
#include <linux/gfp.h>

#include <linux/moduleparam.h>
#include <linux/miscdevice.h>
#include <linux/ioport.h>
#include <linux/notifier.h>

#include <linux/time.h>
#include <linux/timer.h>

#define SHA256_DEV_NAME "sha256"
#define sha256log(level, fmt, args...) printk(level SHA256_DEV_NAME ": " fmt, ##args)

typedef struct
{
    __u32 status;   // 0x00
    __u32 reg1;     // 0x04
    __u32 reg2;     // 0x08
    __u32 reg3;     // 0x0c
    __u32 place[4]; // 0x10
    __u32 hash[8];  // 0x20
} SHA256_Lite_t;

#define SHA256_STATUS_RESET 0x00000001
#define SHA256_STATUS_BUSY 0x00000100

#define SHA256_IS_BUSY(u) ((u)->status & SHA256_STATUS_BUSY)

struct sha256_driver_data
{
    struct cdev cdev;
    struct class *cls;
    struct device *device;
    struct dma_chan *chan;
    void *tx_buf;
    dma_addr_t tx_addr;
    char dev_name[24];
    int inited;
    int busy;
    SHA256_Lite_t *unit;
    wait_queue_head_t r_wqh;
    wait_queue_head_t w_wqh;
    __u32 writen;
};

#define DMA_BUF_SIZE (PAGE_SIZE * 0x100)

#endif
#include "hsha256.h"

// static irqreturn_t irq_interrupt(int irq, void *dev_id)
// {
//     struct sha256_driver_data *drv_data = dev_id;
//     wake_up_interruptible(&drv_data->r_wqh);
//     wake_up_interruptible(&drv_data->w_wqh);
//     return IRQ_HANDLED;
// }

static int sha256_open(struct inode *inode, struct file *filp)
{
    struct sha256_driver_data *drv_data = container_of(inode->i_cdev, struct sha256_driver_data, cdev);
    if (drv_data->inited)
    {
        return -EBUSY;
    }
    filp->private_data = drv_data;

    init_waitqueue_head(&drv_data->r_wqh);
    init_waitqueue_head(&drv_data->w_wqh);
    drv_data->tx_buf = dma_alloc_coherent(drv_data->chan->device->dev, DMA_BUF_SIZE, &drv_data->tx_addr, GFP_KERNEL);

    iowrite32(SHA256_STATUS_RESET, &drv_data->unit->status); // reset
    drv_data->writen = 0;
    drv_data->inited = 1;
    sha256log(KERN_INFO, "open %s\n", drv_data->dev_name);
    return 0;
}

static int sha256_release(struct inode *inode, struct file *filp)
{
    struct sha256_driver_data *drv_data = container_of(inode->i_cdev, struct sha256_driver_data, cdev);
    dma_free_coherent(drv_data->chan->device->dev, DMA_BUF_SIZE, drv_data->tx_buf, drv_data->tx_addr);
    drv_data->inited = 0;
    sha256log(KERN_INFO, "release %s\n", drv_data->dev_name);
    return 0;
}

static loff_t sha256_llseek(struct file *filp, loff_t off, int wherece)
{
    loff_t newpos = 0;
    switch (wherece)
    {
    case SEEK_SET:
        newpos = off;
        break;
    case SEEK_CUR:
        newpos = filp->f_pos + off;
        break;
    case SEEK_END:
        newpos = 32;
        break;
    default:
        return -EINVAL;
    }

    if (newpos < 0 || newpos > 32)
    {
        return -EINVAL;
    }

    filp->f_pos = newpos;
    return newpos;
}

static ssize_t sha256_read(struct file *filp, char __user *buf, size_t count, loff_t *pos)
{
    struct sha256_driver_data *drv_data = filp->private_data;
    if (SHA256_IS_BUSY(drv_data->unit))
    {
        if (filp->f_flags & O_NONBLOCK)
        {
            sha256log(KERN_WARNING, "read: busy\n");
            return -EAGAIN;
        }
        else
        {
            if (wait_event_interruptible(drv_data->r_wqh, !SHA256_IS_BUSY(drv_data->unit)))
            {
                return -ERESTARTSYS;
            }
        }
    }
    *pos = *pos % 32;
    // sha256log(KERN_INFO, "read: %d offset: %lld\n", count, *pos);
    {
        size_t sha256_remain = 32 - (*pos % 32);
        size_t should_copied = min(sha256_remain, count);
        __u8 *sha256_hash = (__u8 *)drv_data->unit->hash;
        size_t ret = 0;
        ret = copy_to_user(buf, &sha256_hash[*pos], should_copied);
        if (ret)
        {
            return -EFAULT;
        }
        *pos += should_copied;
        return should_copied;
    }
}

static void dma_callback(void *data)
{
    struct sha256_driver_data *drv_data = data;
    if (!SHA256_IS_BUSY(drv_data->unit))
    {
        wake_up_interruptible(&drv_data->r_wqh);
    }
    wake_up_interruptible(&drv_data->w_wqh);
    drv_data->chan->device->device_terminate_all(drv_data->chan);
    drv_data->busy = 0;
    // sha256log(KERN_INFO, "dma interrupt\n");
}

static ssize_t sha256_write(struct file *filp, const char __user *buf, size_t count, loff_t *pos)
{
    int ret = 0;
    size_t copied = 0;
    size_t should_copy;
    struct sha256_driver_data *drv_data = filp->private_data;
    struct dma_async_tx_descriptor *desc;
    count &= ~(0x04 - 1); // 强制写入的数据4字节对齐

    // sha256log(KERN_WARNING, "block mode\n");
    while (copied < count)
    {
        should_copy = min((size_t)DMA_BUF_SIZE, count - copied);
        if (copy_from_user(drv_data->tx_buf, &buf[copied], should_copy))
        {
            sha256log(KERN_ALERT, "copy error\n");
            goto write_err;
        }
        // if (memcmp(drv_data->tx_buf, &buf[copied], should_copy))
        // {
        //     sha256log(KERN_ALERT, "no equal");
        // }
        // sha256log(KERN_INFO, "copy size: %dKiB to dma addr: %p\n", should_copy / 1024, (void *)drv_data->tx_addr);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_memcpy);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_xor);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_xor_val);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_pq);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_pq_val);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_memset_sg);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_interrupt);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_slave_sg);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_cyclic);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_interleaved_dma);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_prep_dma_imm_data);
        // sha256log(KERN_INFO, "%p\n", drv_data->chan->device->device_terminate_all);

        desc = drv_data->chan->device->device_prep_dma_cyclic(drv_data->chan, drv_data->tx_addr, should_copy, should_copy, DMA_MEM_TO_DEV, DMA_CTRL_ACK | DMA_PREP_INTERRUPT);
        if (!desc)
        {
            sha256log(KERN_ALERT, "dma memcpy error\n");
            goto write_err;
        }
        // sha256log(KERN_ALERT, "dma set callback\n");
        desc->callback = dma_callback;
        desc->callback_param = drv_data;
        // sha256log(KERN_ALERT, "dma submit\n");
        dmaengine_submit(desc);
        // sha256log(KERN_ALERT, "dma pending\n");
        dma_async_issue_pending(drv_data->chan);
        drv_data->busy = 1;
        if (wait_event_interruptible(drv_data->w_wqh, !drv_data->busy))
        {
            sha256log(KERN_ALERT, "write error\n");
            goto write_err;
        }
        copied += should_copy;
    }
write_err:
    // sha256log(KERN_INFO, "write: %d copied: %d status: 0x%x ret: %d\n", count, copied, drv_data->unit->status, ret);
    drv_data->writen += copied;
    return ret == 0 ? copied : ret;
}

struct file_operations sha256_ops = {
    .owner = THIS_MODULE,
    .open = sha256_open,
    .release = sha256_release,
    .llseek = sha256_llseek,
    .read = sha256_read,
    .write = sha256_write,
};

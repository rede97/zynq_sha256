#include "hsha256.h"
#include "asm-generic/errno-base.h"
#include "asm-generic/fcntl.h"
#include "asm-generic/int-ll64.h"
#include "asm-generic/iomap.h"
#include "asm-generic/poll.h"
#include "asm-generic/rwonce.h"
#include "libxdma.h"
#include "linux/cdev.h"
#include "linux/device.h"
#include "linux/device/class.h"
#include "linux/eventpoll.h"
#include "linux/export.h"
#include "linux/fs.h"
#include "linux/gfp.h"
#include "linux/kdev_t.h"
#include "linux/kobject.h"
#include "linux/poll.h"
#include "linux/printk.h"
#include "linux/slab.h"
#include "linux/spinlock.h"
#include "linux/stddef.h"
#include "linux/types.h"
#include "linux/uaccess.h"
#include "linux/wait.h"
#include "xdma_cdev.h"
#include "libxdma_api.h"
#include "xdma_mod.h"

static int sha256_open(struct inode *inode, struct file *file)
{
	struct xdma_cdev *xcdev;
	struct xdma_engine *engine;
	struct sha256_dev *sha256;
	char_open(inode, file);

	xcdev = (struct xdma_cdev *)file->private_data;
	sha256 = (struct sha256_dev *)xcdev;
	engine = xcdev->engine;

	if (engine->device_open == 1) {
		return -EBUSY;
	}

	iowrite32(SHA256_STATUS_RESET, &sha256->unit->status);
	engine->device_open = 1;
	sha256->submit_cnt = 0;

	return 0;
}

static int sha256_release(struct inode *inode, struct file *file)
{
	struct xdma_cdev *xcdev;
	struct xdma_engine *engine;
	xcdev = (struct xdma_cdev *)file->private_data;
	engine = xcdev->engine;

	engine->device_open = 0;
	return 0;
}

static ssize_t sha256_read(struct file *file, char __user *buf, size_t count,
			   loff_t *pos)
{
	int i, ret;
	struct xdma_cdev *xcdev;
	struct sha256_dev *sha256;
	size_t should_copy;

	xcdev = (struct xdma_cdev *)file->private_data;
	sha256 = (struct sha256_dev *)xcdev;
	should_copy = min(count, sizeof(sha256->hash_buf) - (size_t)*pos);

	if (should_copy) {
		for (i = 0; i < 8; i++) {
			sha256->hash_buf[i] = ioread32(&sha256->unit->hash[i]);
		}
		ret = copy_to_user(buf, sha256->hash_buf, should_copy);
		if (ret) {
			pr_err("error copying result to user\n");
			return ret;
		}
		*pos += should_copy;
	}

	return should_copy;
}

static int check_transfer_align(struct xdma_engine *engine,
				const char __user *buf, size_t count,
				loff_t pos, int sync)
{
	if (!engine) {
		pr_err("Invalid DMA engine\n");
		return -EINVAL;
	}

	/* AXI ST or AXI MM non-incremental addressing mode? */
	if (engine->non_incr_addr) {
		int buf_lsb = (int)((uintptr_t)buf) & (engine->addr_align - 1);
		size_t len_lsb = count & ((size_t)engine->len_granularity - 1);
		int pos_lsb = (int)pos & (engine->addr_align - 1);

		dbg_tfr("AXI ST or MM non-incremental\n");
		dbg_tfr("buf_lsb = %d, pos_lsb = %d, len_lsb = %ld\n", buf_lsb,
			pos_lsb, len_lsb);

		if (buf_lsb != 0) {
			dbg_tfr("FAIL: non-aligned buffer address %p\n", buf);
			return -EINVAL;
		}

		if ((pos_lsb != 0) && (sync)) {
			dbg_tfr("FAIL: non-aligned AXI MM FPGA addr 0x%llx\n",
				(unsigned long long)pos);
			return -EINVAL;
		}

		if (len_lsb != 0) {
			dbg_tfr("FAIL: len %d is not a multiple of %d\n",
				(int)count, (int)engine->len_granularity);
			return -EINVAL;
		}
		/* AXI MM incremental addressing mode */
	} else {
		int buf_lsb = (int)((uintptr_t)buf) & (engine->addr_align - 1);
		int pos_lsb = (int)pos & (engine->addr_align - 1);

		if (buf_lsb != pos_lsb) {
			dbg_tfr("FAIL: Misalignment error\n");
			dbg_tfr("host addr %p, FPGA addr 0x%llx\n", buf, pos);
			return -EINVAL;
		}
	}

	return 0;
}

static void char_sgdma_unmap_user_buf(struct xdma_io_cb *cb, bool write)
{
	int i;

	sg_free_table(&cb->sgt);

	if (!cb->pages || !cb->pages_nr)
		return;

	for (i = 0; i < cb->pages_nr; i++) {
		if (cb->pages[i]) {
			if (!write)
				set_page_dirty_lock(cb->pages[i]);
			put_page(cb->pages[i]);
		} else
			break;
	}

	if (i != cb->pages_nr)
		pr_info("sgl pages %d/%u.\n", i, cb->pages_nr);

	kfree(cb->pages);
	cb->pages = NULL;
}

static int char_sgdma_map_user_buf_to_sgl(struct xdma_io_cb *cb, bool write)
{
	struct sg_table *sgt = &cb->sgt;
	unsigned long len = cb->len;
	void __user *buf = cb->buf;
	struct scatterlist *sg;
	unsigned int pages_nr = (((unsigned long)buf + len + PAGE_SIZE - 1) -
				 ((unsigned long)buf & PAGE_MASK)) >>
				PAGE_SHIFT;
	int i;
	int rv;

	if (pages_nr == 0)
		return -EINVAL;

	if (sg_alloc_table(sgt, pages_nr, GFP_KERNEL)) {
		pr_err("sgl OOM.\n");
		return -ENOMEM;
	}

	cb->pages = kcalloc(pages_nr, sizeof(struct page *), GFP_KERNEL);
	if (!cb->pages) {
		pr_err("pages OOM.\n");
		rv = -ENOMEM;
		goto err_out;
	}

	rv = get_user_pages_fast((unsigned long)buf, pages_nr, 1 /* write */,
				 cb->pages);
	/* No pages were pinned */
	if (rv < 0) {
		pr_err("unable to pin down %u user pages, %d.\n", pages_nr, rv);
		goto err_out;
	}
	/* Less pages pinned than wanted */
	if (rv != pages_nr) {
		pr_err("unable to pin down all %u user pages, %d.\n", pages_nr,
		       rv);
		cb->pages_nr = rv;
		rv = -EFAULT;
		goto err_out;
	}

	for (i = 1; i < pages_nr; i++) {
		if (cb->pages[i - 1] == cb->pages[i]) {
			pr_err("duplicate pages, %d, %d.\n", i - 1, i);
			rv = -EFAULT;
			cb->pages_nr = pages_nr;
			goto err_out;
		}
	}

	sg = sgt->sgl;
	for (i = 0; i < pages_nr; i++, sg = sg_next(sg)) {
		unsigned int offset = offset_in_page(buf);
		unsigned int nbytes =
			min_t(unsigned int, PAGE_SIZE - offset, len);

		flush_dcache_page(cb->pages[i]);
		sg_set_page(sg, cb->pages[i], nbytes, offset);

		buf += nbytes;
		len -= nbytes;
	}

	if (len) {
		pr_err("Invalid user buffer length. Cannot map to sgl\n");
		return -EINVAL;
	}
	cb->pages_nr = pages_nr;
	return 0;

err_out:
	char_sgdma_unmap_user_buf(cb, write);

	return rv;
}

static void transfer_io_handler(unsigned long cb_hndl, int err)
{
	int rv;
	unsigned long flags;
	struct xdma_io_cb *cb = (struct xdma_io_cb *)cb_hndl;
	struct xdma_cdev *xcdev = cb->private;
	struct sha256_dev *sha256 = (struct sha256_dev *)xcdev;

	rv = xcdev_check(__func__, xcdev, 1);
	if (rv < 0)
		return;

	if (!err) {
		xdma_xfer_completion(
			(void *)cb, xcdev->xdev, xcdev->engine->channel,
			cb->write, cb->ep_addr, &cb->sgt, 0,
			cb->write ? h2c_timeout * 1000 : c2h_timeout * 1000);
	} else {
		pr_err("sha256 transfer failed, error: %d\n", err);
	}

	spin_lock_irqsave(&sha256->wqh.lock, flags);
	sha256->submit_cnt -= 1;
	wake_up_locked(&sha256->wqh);
	spin_unlock_irqrestore(&sha256->wqh.lock, flags);

	pr_info("transfer finish\n");

	char_sgdma_unmap_user_buf(cb, cb->write);
	kfree(cb);
}

static inline ssize_t char_sgdma_read_write(struct file *file,
					    const char __user *buf,
					    size_t count, loff_t *pos,
					    bool write, bool block)
{
	int rv;
	ssize_t res = 0;
	struct xdma_cdev *xcdev = (struct xdma_cdev *)file->private_data;
	struct xdma_dev *xdev;
	struct xdma_engine *engine;
	struct sha256_dev *sha256;

	rv = xcdev_check(__func__, xcdev, 1);
	if (rv < 0)
		return rv;
	xdev = xcdev->xdev;
	engine = xcdev->engine;
	sha256 = (struct sha256_dev *)xcdev;

	dbg_tfr("file 0x%p, priv 0x%p, buf 0x%p,%llu, pos %llu, W %d, %s.\n",
		file, file->private_data, buf, (u64)count, (u64)*pos, write,
		engine->name);

	if ((write && engine->dir != DMA_TO_DEVICE) ||
	    (!write && engine->dir != DMA_FROM_DEVICE)) {
		pr_err("r/w mismatch. W %d, dir %d.\n", write, engine->dir);
		return -EINVAL;
	}

	rv = check_transfer_align(engine, buf, count, *pos, 1);
	if (rv) {
		pr_info("Invalid transfer alignment detected\n");
		return rv;
	}

	if (block) {
		struct xdma_io_cb cb;
		memset(&cb, 0, sizeof(struct xdma_io_cb));
		cb.buf = (char __user *)buf;
		cb.len = count;
		cb.ep_addr = (u64)*pos;
		cb.write = write;
		rv = char_sgdma_map_user_buf_to_sgl(&cb, write);
		if (rv < 0)
			return rv;

		res = xdma_xfer_submit(
			xdev, engine->channel, write, *pos, &cb.sgt, 0,
			write ? h2c_timeout * 1000 : c2h_timeout * 1000);

		char_sgdma_unmap_user_buf(&cb, write);
	} else {
		unsigned long flags;
		struct xdma_io_cb *cb =
			kzalloc(sizeof(struct xdma_io_cb), GFP_KERNEL);
		cb->buf = (char __user *)buf;
		cb->len = count;
		cb->ep_addr = (u64)*pos;
		cb->write = write;
		cb->private = xcdev;
		cb->io_done = transfer_io_handler;
		rv = char_sgdma_map_user_buf_to_sgl(cb, write);
		if (rv < 0) {
			kfree(cb);
			return rv;
		}

		rv = xdma_xfer_submit_nowait(
			cb, xdev, engine->channel, write, cb->ep_addr, &cb->sgt,
			0, write ? h2c_timeout * 1000 : c2h_timeout * 1000);
		if (rv != -EIOCBQUEUED) {
			pr_err("xdma submit error: %d\n", rv);
			// free memory in callback
			return rv;
		}
		spin_lock_irqsave(&sha256->wqh.lock, flags);
		sha256->submit_cnt += 1;
		spin_unlock_irqrestore(&sha256->wqh.lock, flags);
		pr_info("write %ld\n", count);
		return count;
	}

	return res;
}

static ssize_t sha256_write(struct file *file, const char __user *buf,
			    size_t count, loff_t *pos)
{
	return char_sgdma_read_write(file, buf, count, pos, 1,
				     !(file->f_flags & O_NONBLOCK));
}

static loff_t sha256_llseek(struct file *filp, loff_t off, int wherece)
{
	loff_t newpos = 0;
	switch (wherece) {
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

	if (newpos < 0 || newpos > 32) {
		return -EINVAL;
	}

	filp->f_pos = newpos;
	return newpos;
}

static int sha256_flush(struct file *file, fl_owner_t id)
{
	struct xdma_cdev *xcdev;
	struct sha256_dev *sha256;

	xcdev = (struct xdma_cdev *)file->private_data;
	sha256 = (struct sha256_dev *)xcdev;

	iowrite32(SHA256_STATUS_RESET, &sha256->unit->status);
	return 0;
}

static __poll_t sha256_poll(struct file *file, struct poll_table_struct *p)
{
	int mask = 0;
	unsigned long flags;
	struct xdma_cdev *xcdev;
	struct sha256_dev *sha256;

	xcdev = (struct xdma_cdev *)file->private_data;
	sha256 = (struct sha256_dev *)xcdev;

	poll_wait(file, &sha256->wqh, p);

	spin_lock_irqsave(&sha256->wqh.lock, flags);
	if (sha256->submit_cnt == 0) {
		mask |= POLLOUT | POLLIN;
	}
	spin_unlock_irqrestore(&sha256->wqh.lock, flags);

	pr_info("poll mask: %x\n", mask);
	return mask;
}

struct file_operations sha256_ops = {
	.owner = THIS_MODULE,
	.open = sha256_open,
	.release = sha256_release,
	.read = sha256_read,
	.write = sha256_write,
	.flush = sha256_flush,
	.poll = sha256_poll,
	.llseek = sha256_llseek,
};

int sha256_create(struct xdma_pci_dev *xpdev, struct sha256_dev *sha256,
		  int bar, struct xdma_engine *engine, struct class *xdma_class)
{
	const char *dev_name = "sha256u%dc%d";
	struct xdma_dev *xdev = xpdev->xdev;
	struct xdma_cdev *xcdev = &sha256->xcdev;
	int minor;
	int rv;
	dev_t dev;

	sha256->unit =
		(struct sha256_unit *)(xdev->bar[xdev->user_bar_idx] +
				       (0x10000 * (engine->channel + 1)));

	pr_info("sha256u%dc%d at 0x%p\n", xdev->idx, engine->channel,
		sha256->unit);
	pr_info("default value: 0x%08x", ioread32(&sha256->unit->hash[0]));

	iowrite8(0x55, xdev->bar[0]);
	spin_lock_init(&sha256->xcdev.lock);

	if (!xpdev->major) {
		rv = alloc_chrdev_region(&dev, XDMA_MINOR_BASE,
					 XDMA_MINOR_COUNT, XDMA_NODE_NAME);

		if (rv) {
			pr_err("unable to allocate cdev region %d.\n", rv);
			return rv;
		}
		xpdev->major = MAJOR(dev);
	}

	xcdev->magic = MAGIC_CHAR;
	xcdev->cdev.owner = THIS_MODULE;
	xcdev->xpdev = xpdev;
	xcdev->xdev = xdev;
	xcdev->engine = engine;
	xcdev->bar = bar;

	cdev_init(&xcdev->cdev, &sha256_ops);
	minor = 64 + engine->channel;
	xcdev->cdevno = MKDEV(xpdev->major, minor);
	rv = cdev_add(&xcdev->cdev, xcdev->cdevno, 1);
	if (rv < 0) {
		pr_err("cdev add failed %d, channel: %d\n", rv,
		       engine->channel);
		goto unregister_region;
	}

	if (xdma_class) {
		xcdev->sys_device = device_create(xdma_class, &xdev->pdev->dev,
						  xcdev->cdevno, NULL, dev_name,
						  xdev->idx, engine->channel);
		if (!xcdev->sys_device) {
			pr_err("sha256 create %d#%d failed", xdev->idx,
			       engine->channel);
			goto del_cdev;
		}
	}

	pr_info("sha256 0x%p, %u:%u, channel: %d\n", xcdev, xpdev->major, minor,
		engine->channel);

	init_waitqueue_head(&sha256->wqh);

	return 0;
del_cdev:
	cdev_del(&xcdev->cdev);
unregister_region:
	unregister_chrdev_region(xcdev->cdevno, XDMA_MINOR_COUNT);
	return rv;
}

int sha256_destory(struct sha256_dev *sha256, struct class *xdma_class)
{
	struct xdma_cdev *xcdev = &sha256->xcdev;

	if (!sha256) {
		pr_warn("sha256 NULL\n");
		return -EINVAL;
	}

	if (xcdev->magic != MAGIC_CHAR) {
		pr_warn("cdev 0x%p magic mismatch 0x%lx\n", xcdev,
			xcdev->magic);
		return -EINVAL;
	}

	if (!xcdev->xdev) {
		pr_err("xdev NULL\n");
		return -EINVAL;
	}

	if (xdma_class && xcdev->sys_device) {
		device_destroy(xdma_class, xcdev->cdevno);
	}

	cdev_del(&xcdev->cdev);
	return 0;
}

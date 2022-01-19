#include "hsha256.h"

static int dat_show(struct seq_file *m, void *v)
{
    struct sha256_driver_data *sha256 = m->private;
    seq_printf(m, "status: 0x%08x writen: %d\n", sha256->unit->status, sha256->writen);
    return 0;
}

static int proc_open(struct inode *inode, struct file *file)
{
    return single_open(file, dat_show, PDE_DATA(inode));
}

static int proc_release(struct inode *inode, struct file *filp)
{
    return 0;
}

static struct proc_ops sha256_proc_ops = {
    .proc_open = proc_open,
    .proc_read = seq_read,
    .proc_lseek = seq_lseek,
    .proc_release = proc_release,
};
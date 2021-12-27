#include "hsha256.h"

static const char *SHA256_DEV_NAME_STR = SHA256_DEV_NAME;
static const char *SHA256_DEV_CLASS = "hash";

extern struct file_operations sha256_ops;

static int sha256_probe(struct platform_device *pdev)
{
    int ret;
    dev_t dev;
    const struct resource *res;
    struct sha256_driver_data *drv_data;
    struct dma_chan *chan;

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    if (!res)
    {
        sha256log(KERN_ALERT, "get resource failed\n");
        return -ENOMEM;
    }
    sha256log(KERN_INFO, "mem: 0x%08x size: 0x%08x\n", res->start, resource_size(res));


    drv_data = kmalloc(sizeof(struct sha256_driver_data), GFP_KERNEL);
    if (!drv_data)
    {
        sha256log(KERN_ALERT, "alloc drv_data\n");
        return -ENOMEM;
    }
    platform_set_drvdata(pdev, drv_data);
    drv_data->inited = 0;
    sprintf(drv_data->dev_name, SHA256_DEV_NAME "@%08x", res->start);
    sha256log(KERN_INFO, "dev name: %s\n", drv_data->dev_name);
    
    chan = dma_request_chan(&pdev->dev, "tx");
    if (!chan)
    {
        sha256log(KERN_ALERT, "get dma failed\n");
        ret = -EFAULT;
        goto request_dma;
    }
    sha256log(KERN_INFO, "dma channel: %s", dma_chan_name(chan));
    drv_data->chan = chan;

    ret = alloc_chrdev_region(&dev, 0, 1, SHA256_DEV_NAME_STR);
    if (ret < 0)
    {
        sha256log(KERN_ALERT, "alloc chrdev error\n");
        goto alloc_dev;
    }

    cdev_init(&drv_data->cdev, &sha256_ops);
    drv_data->cdev.owner = THIS_MODULE;
    ret = cdev_add(&drv_data->cdev, dev, 1);
    if (ret)
    {
        sha256log(KERN_ALERT, "cdev add error\n");
        goto cdev_add_err;
    }
    drv_data->cls = class_create(THIS_MODULE, SHA256_DEV_CLASS);

    drv_data->device = device_create(drv_data->cls, &pdev->dev, dev, NULL, SHA256_DEV_NAME_STR);
    if (IS_ERR(drv_data->device))
    {
        sha256log(KERN_ALERT, "devive create error\n");
        ret = -EFAULT;
        goto create_dev_err;
    }

    if (!request_mem_region(res->start, resource_size(res), drv_data->dev_name))
    {
        sha256log(KERN_ALERT, "request mem region error: 0x%08x\n", res->start);
        ret = -EBUSY;
        goto request_mem_err;
    }

    drv_data->unit = (SHA256_Lite_t *)ioremap(res->start, resource_size(res));
    if (!drv_data->unit)
    {
        sha256log(KERN_ALERT, "ioremap error: 0x%08x\n", res->start);
        ret = -EBUSY;
        goto ioremmap_err;
    }

    sha256log(KERN_INFO, "probe %s\n", drv_data->dev_name);
    return 0;

ioremmap_err:
    release_mem_region(res->start, resource_size(res));
request_mem_err:
    device_destroy(drv_data->cls, dev);
create_dev_err:
    class_destroy(drv_data->cls);
    cdev_del(&drv_data->cdev);
cdev_add_err:
    unregister_chrdev_region(dev, 1);
alloc_dev:
    dma_release_channel(drv_data->chan);
request_dma:
    kfree(drv_data);
    return ret;
}

static int sha256_remove(struct platform_device *pdev)
{
    struct sha256_driver_data *drv_data = platform_get_drvdata(pdev);
    const struct resource *res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    dev_t dev = drv_data->cdev.dev;

    iounmap(drv_data->unit);
    release_mem_region(res->start, resource_size(res));

    device_destroy(drv_data->cls, dev);
    class_destroy(drv_data->cls);
    cdev_del(&drv_data->cdev);
    unregister_chrdev_region(dev, 1);
    dma_release_channel(drv_data->chan);
    sha256log(KERN_INFO, "remove %s\n", drv_data->dev_name);
    kfree(drv_data);
    return 0;
}

static const struct of_device_id sha256_of_match[] = {
    {.compatible = "sha256"},
    {}};

MODULE_DEVICE_TABLE(of, sha256_of_match);

static struct platform_driver sha256_driver = {
    .probe = sha256_probe,
    .remove = sha256_remove,
    .driver = {
        .name = SHA256_DEV_NAME,
        .of_match_table = sha256_of_match,
    },
};

module_platform_driver(sha256_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ma Xiaoqing <maxiaoqing19@gmail.com>");
MODULE_DESCRIPTION("hardware sha256 driver");
MODULE_ALIAS("hsha256");

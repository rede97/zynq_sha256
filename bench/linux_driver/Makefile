ifneq ($(KERNELRELEASE),)
# kbuild part of makefile
obj-m  := sha256.o
sha256-y := hsha256.o hsha256_ops.o
else

ARCH ?= arm
CROSS_COMPILE ?= arm-linux-gnueabihf-

KDIR ?= /home/zuan/build_ground/linux-xlnx
PWD := $(shell pwd)

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) modules ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

clean: 
	$(MAKE) -C $(KDIR) M=$(PWD) clean ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)

endif
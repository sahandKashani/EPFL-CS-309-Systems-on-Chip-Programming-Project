obj-m += prsoc_fbdev.o

KERNEL_SOURCE_PATH='../../../../../sw/hps/linux/source/'

all:
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C $(KERNEL_SOURCE_PATH) M=$(PWD) modules

clean:
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -C $(KERNEL_SOURCE_PATH) clean

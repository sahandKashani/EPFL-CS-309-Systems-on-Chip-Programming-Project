TARGET = system_test
LIBS =
CC = arm-linux-gnueabihf-gcc
CFLAGS = -g -Wall -Wextra -O0 -Dsoc_cv_av
LDFLAGS =
INCS = -I"/home/psoc/psoc/TEST_AREA/sw/hps/application/hw_headers" -I"/opt/altera_lite/16.0/embedded/ip/altera/hps/altera_hps/hwlib/include/soc_cv_av" -I"/opt/altera_lite/16.0/embedded/ip/altera/hps/altera_hps/hwlib/include"

.PHONY: default all clean

default: $(TARGET)
all: default

OBJECTS = $(patsubst %.c, %.o, $(wildcard *.c))
HEADERS = $(wildcard *.h)

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $@

clean:
	-rm -f *.o
	-rm -f $(TARGET)

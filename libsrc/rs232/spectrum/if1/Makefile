#
# Wahey, a messed up makefile for building libraries!
#
# $Id: Makefile,v 1.9 2016-07-02 15:42:55 dom Exp $

include ../../../Make.config

CFILES = rs232_close.c rs232_get.c rs232_init.c rs232_params.c rs232_put.c 

AFILES  = $(CFILES:.c=.asm)
OBJECTS = $(CFILES:.c=.o)

all:	$(OUTPUT_DIRECTORY)/rs232if1.lib

$(OUTPUT_DIRECTORY)/rs232if1.lib: $(OBJECTS)
	$(LIBLINKER) -x$(OUTPUT_DIRECTORY)/rs232if1 @if1list

%.o: %.c
	$(ZCC) +zx $(CFLAGS) $*.c -o $@

clean:
	$(RM) *.sym *.map zcc_opt.def *.o* *~ *.err *.i $(AFILES)

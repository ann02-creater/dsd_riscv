include ../config.mk

MALL = 1

ifdef SMALL
    CFLAGS += -DSMALL
endif

PROJ = game
OBJS = main.o
ASMS = main.s
SRCS = main.c

DEPS = $(SRCS) $(ASMS) $(OBJS) $(LIBS) # $(PROJ).ld $(PROJ).lds $(DARKLIBC)/darklibc.a

TARGETS = $(PROJ).a

.PHONY: all

all: $(TARGETS) $(DEPS)
	@echo sources ok for $(TARGETS).

clean:
	-rm -f $(ASMS) $(OBJS) $(PROJ).{S,bin,lst,map,ram,rom,x86,text,data,bin,ld,o,mem,rom.mem,ram.mem,a} $(PROJ)_uart.bin

%.o: %.s Makefile
	$(AS) $(ASFLAGS) -c $< -o $@

%.s: %.c Makefile
	$(CC) $(CFLAGS) -S $< -o $@

$(PROJ).a: $(OBJS) Makefile
	$(AR) $(ARFLAGS) $@ $(OBJS)
	$(RL) $@
	
$(PROJ).x86: $(SRCS)
	$(HOST_CC) $(HOST_CFLAGS) $(SRCS) -o $(PROJ).x86 -DBUILD="\"$(BUILD)\"" -DARCH="\"x86\""
	@echo x86 ok.

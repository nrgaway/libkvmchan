SRCS:=library.c ringbuf.c
DEPS:=$(SRCS:.c=.o)
BIN:=libkvmchan.so
LIBS=-lrt -pthread
DEBUG:=true

DAEMON_SRCS:=daemon/daemon.c daemon/libvirt.c daemon/util.c daemon/ivshmem.c daemon/vfio.c \
	daemon/ipc.c daemon/connections.c daemon/localhandler.c
DAEMON_DEPS:=$(DAEMON_SRCS:.c=.daemon.o)
DAEMON_BIN:=kvmchand
DAEMON_LIBS:=-lrt -pthread $(shell pkg-config --libs libvirt libvirt-qemu libxml-2.0)
DAEMON_CFLAGS:=$(shell pkg-config --cflags libxml-2.0)

TEST_SRCS:=test.c
TEST_DEPS:=$(TEST_SRCS:.c=.o)
TEST_BIN:=test
TEST_LIBS:=$(shell pkg-config --cflags --libs check)

TEST_LIBRARY_SRCS:=test_library.c
TEST_LIBRARY_BIN:=test_library

CFLAGS=-D_GNU_SOURCE=1 -O2 -Wall -Wvla -fpic -fvisibility=hidden -std=gnu99 -I. \
	   -fstack-protector-strong -D_FORITY_SOURCE=2

ifneq ($(DEBUG),false)
CFLAGS += -g
endif

COMPILER_NAME:=$(shell $(CC) --version |cut -d' ' -f1 |head -n1)
ifneq ($(COMPILER_NAME),clang)
# This flag is GCC-only
CFLAGS += -fstack-clash-protection
endif


.PHONY all: library daemon build_test $(TEST_LIBRARY_BIN)

library: $(DEPS)
	$(CC) -shared $(CFLAGS) $(DEPS) -o $(BIN) $(LIBS)

%.daemon.o: %.c
	$(CC) $(CFLAGS) $(DAEMON_CFLAGS) -o $@ -c $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ -c $<

daemon: $(DAEMON_DEPS) $(DEPS)
	$(CC) $(CFLAGS) $(DAEMON_DEPS) $(DEPS) -o $(DAEMON_BIN) $(LIBS) $(DAEMON_LIBS)

build_test: $(DEPS) $(TEST_DEPS)
	$(CC) $(CFLAGS) $(DEPS) $(TEST_DEPS) -o $(TEST_BIN) $(LIBS) $(TEST_LIBS)

test: build_test
	./$(TEST_BIN)

$(TEST_LIBRARY_BIN): library
	$(CC) $(CFLAGS) -fvisibility=default $(TEST_LIBRARY_SRCS)  -lkvmchan -L. -o $(TEST_LIBRARY_BIN) 

clean:
	rm -f $(DEPS)
	rm -f $(BIN)
	rm -f $(DAEMON_DEPS)
	rm -f $(DAEMON_BIN)
	rm -f $(TEST_BIN)
	rm -f $(TEST_DEPS)

print-%  : ; @echo $* = $($*)

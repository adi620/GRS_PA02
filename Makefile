# MT25011 - Replace XXX with your roll number
# PA02 - Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -pthread
LDFLAGS = -pthread

# Targets
TARGETS = MT25011_PartA1_Server MT25011_PartA1_Client \
          MT25011_PartA2_Server MT25011_PartA2_Client \
          MT25011_PartA3_Server MT25011_PartA3_Client

.PHONY: all clean

all: $(TARGETS)

# Part A1: Two-Copy Implementation
MT25011_PartA1_Server: MT25011_PartA1_Server.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

MT25011_PartA1_Client: MT25011_PartA1_Client.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Part A2: One-Copy Implementation
MT25011_PartA2_Server: MT25011_PartA2_Server.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

MT25011_PartA2_Client: MT25011_PartA2_Client.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

# Part A3: Zero-Copy Implementation
MT25011_PartA3_Server: MT25011_PartA3_Server.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

MT25011_PartA3_Client: MT25011_PartA3_Client.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGETS)
	rm -rf results/
	rm -f *.o
	rm -f *.log

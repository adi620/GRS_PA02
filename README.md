# MT25011 – PA02: Analysis of Network I/O Primitives using perf

**Course:** CSE638 – Graduate Systems  
**Student:** Aditya Malik  
**Roll Number:** MT25011  
**Assignment:** PA02  

## Overview
This project analyzes the cost of data movement in TCP network I/O by implementing and profiling:
- A1: Two-copy baseline using send()/recv()
- A2: One-copy scatter-gather using sendmsg() with iovec
- A3: Zero-copy using sendmsg() with MSG_ZEROCOPY

Experiments are run using Linux network namespaces and profiled with perf on the server side.

## How to Run

```bash
make clean
make all
chmod +x MT25011_PartC_Experiment.sh
sudo sysctl -w kernel.perf_event_paranoid=-1
sudo sysctl -w kernel.kptr_restrict=0
sudo bash MT25011_PartC_Experiment.sh
```

## Key Insight
Zero-copy eliminates CPU data movement but can be slower for small messages due to page pinning and completion notification overhead.

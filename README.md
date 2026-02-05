# PA02: Analysis of Network I/O Primitives using "perf" Tool

## Student Information
- **Name:** Aditya Malik
- **Roll Number:** MT25011
- **Course:** CSE638: Graduate Systems (IIIT Delhi)
- **Date:** February 2026
- **Repository:** [https://github.com/adi620/GRS_PA02](https://github.com/adi620/GRS_PA02)

---

## 1. Overview
This project experimentally analyzes the cost of data movement in TCP network I/O by implementing and profiling three socket communication strategies:
- **A1 – Two-Copy (Baseline):** Standard `send()` / `recv()`
- **A2 – One-Copy (Scatter-Gather):** `sendmsg()` with `iovec`
- **A3 – Zero-Copy:** `sendmsg()` with `MSG_ZEROCOPY`

The goal is to determine the threshold where advanced techniques like zero-copy outperform baseline methods by measuring CPU cycles, cache misses, and context switches using the `perf` tool.

---

## 2. System Requirements
### Software
- **Kernel:** Linux ≥ 4.14 (Required for `MSG_ZEROCOPY`)
- **Compiler:** `gcc` with `pthread` support
- **Profiling:** `perf` (linux-tools)
- **Networking:** `iproute2` (for network namespaces)
- **Visualization:** Python 3 (Matplotlib)

### Hardware
- Multi-core CPU (Intel Precision 3660 used for reporting)
- Hardware support for performance counters (PMU)

---

## 3. Project Structure
In accordance with the strict naming conventions of the assignment:

```text
.
├── MT25011_PartA1_Server.c       # Baseline server
├── MT25011_PartA1_Client.c       # Baseline client
├── MT25011_PartA2_Server.c       # Scatter-Gather server
├── MT25011_PartA2_Client.c       # Scatter-Gather client
├── MT25011_PartA3_Server.c       # Zero-copy server
├── MT25011_PartA3_Client.c       # Zero-copy client
├── MT25011_PartC_Experiment.sh   # Automated profiling script
├── MT25011_PartD_Plots.py        # Matplotlib plotting script
├── Makefile                      # Build system (MT25011)
└── README.md                     # Documentation (MT25011)

```

## 4. Part A – Implementation Summary
A1: Two-Copy (Baseline)
Mechanism: Uses send() / recv().

Copies: Performed by the CPU (User-to-Kernel) and NIC DMA (Kernel-to-Hardware). Note: A "hidden" user-space copy is performed to flatten the 8 heap strings.

A2: One-Copy (Scatter-Gather)
Mechanism: Uses sendmsg() with struct iovec iov[8].

Optimization: Explicitly eliminates the intermediate user-space serialization buffer. The kernel "gathers" data directly from scattered heap addresses.

A3: Zero-Copy (MSG_ZEROCOPY)
Mechanism: Uses MSG_ZEROCOPY.

Behavior: The kernel pins user pages and the NIC reads directly via DMA. Completion is handled via the socket Error Queue (MSG_ERRQUEUE), preventing immediate buffer reuse.

## 5. Part B & C – Profiling & Automation
Measurements were taken across 5 message sizes (1KB to 128KB) and 4 thread counts (1, 2, 4, 8) using:

perf stat -e cycles,L1-dcache-load-misses,LLC-load-misses,context-switches

How to Run

```text
Build Binaries: make clean && make all

Unlock Counters: sudo sysctl -w kernel.perf_event_paranoid=-1

Execute Script: sudo bash MT25011_PartC_Experiment.sh

Generate Plots: python3 MT25011_PartD_Plots.py
```

## 6. Key Experimental Findings
Zero-Copy Overhead: A3 is 45-65% slower for small messages (<16KB) due to page pinning and notification polling latency.

Cache Impact: A3 shows the most significant reduction in L1 Data Cache misses by avoiding CPU-driven data touching.

Thread Scalability: High thread counts (8+) introduce significant Context Switching (~65k), leading to cache thrashing and diminishing returns.

# PA02: Analysis of Network I/O Primitives using `perf` Tool

**Name:**  
Name: Aditya Malik  

**Roll Number:** MT25011  

**Course:** CSE638: Graduate Systems (IIIT Delhi)  

**Date:** February 2026  

**Repository:** https://github.com/adi620/GRS_PA02  

---

## 1. Overview

This project experimentally analyzes the cost of data movement in TCP network I/O by implementing and profiling three socket communication strategies:

- **A1 – Two-Copy (Baseline):** Standard `send()` / `recv()`
- **A2 – One-Copy (Scatter-Gather):** `sendmsg()` with `iovec`
- **A3 – Zero-Copy:** `sendmsg()` with `MSG_ZEROCOPY`

The goal is to determine the threshold at which advanced techniques such as zero-copy outperform baseline methods by measuring CPU cycles, cache misses, and context switches using the Linux `perf` tool.

---

## 2. System Requirements

### Software
- **Kernel:** Linux ≥ 4.14 (required for `MSG_ZEROCOPY`)
- **Compiler:** `gcc` with pthread support
- **Profiling:** `perf` (linux-tools)
- **Networking:** `iproute2` (for network namespaces)
- **Visualization:** Python 3 (Matplotlib)

### Hardware
- Multi-core CPU (Intel Precision 3660 reported)
- Hardware support for performance monitoring counters (PMU)

---

## 3. Project Structure

In accordance with the strict naming conventions of the assignment:

```plaintext
.
├── MT25011_PartA1_Server.c       # Baseline server
├── MT25011_PartA1_Client.c       # Baseline client
├── MT25011_PartA2_Server.c       # Scatter-Gather server
├── MT25011_PartA2_Client.c       # Scatter-Gather client
├── MT25011_PartA3_Server.c       # Zero-copy server
├── MT25011_PartA3_Client.c       # Zero-copy client
├── MT25011_PartC_Experiment.sh   # Automated profiling script
├── MT25011_PartD_Plots.py        # Matplotlib plotting script
├── Makefile                      # Build system (Roll No. commented)
└── README.md                     # Documentation (Roll No. commented)

```

## 4. Part A – Implementation Summary
A1: Two-Copy (Baseline)

Mechanism: Uses standard send() and recv() primitives.

Data Handling: Implements a structure with 8 dynamically allocated heap strings.

Copies: Involves a user-space “flattening” copy into a contiguous buffer, followed by the kernel copy (User → Kernel) and the final NIC DMA.

A2: One-Copy (Scatter-Gather)

Mechanism: Uses sendmsg() with struct iovec iov[8].

Optimization: Eliminates the user-space serialization buffer. The kernel gathers data directly from the 8 scattered heap addresses.

A3: Zero-Copy (MSG_ZEROCOPY)

Mechanism: Uses sendmsg() with the MSG_ZEROCOPY flag.

Behavior: Pages are pinned in memory, and the NIC reads directly via DMA. Completion notifications are tracked using the socket Error Queue (MSG_ERRQUEUE) to ensure safe buffer reuse.

## 5. Key Experimental Findings

Efficiency Threshold: Zero-copy (A3) begins to outperform the baseline (A1) only when message sizes exceed 16 KB.

Administrative Overhead: For small messages (<16 KB), A3 is approximately 45% slower than the baseline due to page pinning overhead and error-queue polling.

Best Overall Performer: Scatter-Gather (A2) provides the most consistent performance balance across varying message sizes by avoiding user-space copy overhead without incurring the high management cost of A3.

Micro-architectural Impact: A3 significantly reduces L1 data cache misses. However, at higher thread counts (≥ 8), it leads to heavy context switching (~65k switches) and cache contention.

## 6. How to Run
git clone https://github.com/adi620/GRS_PA02.git
cd GRS_PA02
make clean
make all
sudo ./MT25011_PartC_Experiment.sh
python3 MT25011_PartD_Plots.py

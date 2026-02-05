#!/usr/bin/env python3
"""
MT25011 - PA02 Part D: Comprehensive Performance Visualization
Creates all 4 required plots from experimental data
Data extracted from MT25011_PartC_Perf_Metrics.csv
"""

import matplotlib.pyplot as plt
import numpy as np
import sys

# System Configuration
SYSTEM_CONFIG = """System Configuration:
CPU: Intel Hybrid (P+E cores)
RAM: 16GB DDR4
OS: Ubuntu 24.04 LTS
Kernel: 6.8.x"""

# ============================================================================
# EXPERIMENTAL DATA FROM CSV (MT25011_PartC_Perf_Metrics.csv)
# ============================================================================

# Message sizes tested (bytes)
message_sizes = [1024, 4096, 16384, 65536]

# Thread counts tested
thread_counts = [1, 2, 4, 8]

# -----------------------------------------------------------------------------
# PLOT 1 DATA: Throughput vs Message Size (ThreadCount=4)
# -----------------------------------------------------------------------------
# Extracted from CSV where ThreadCount=4

throughput_A1 = [33.43, 44.46, 156.73, 261.41]  # Two-Copy (Gbps)
throughput_A2 = [24.4, 49.92, 131.48, 287.61]   # One-Copy (Gbps)
throughput_A3 = [11.69, 31.33, 101.9, 199.93]   # Zero-Copy (Gbps)

# -----------------------------------------------------------------------------
# PLOT 2 DATA: Latency vs Thread Count (MessageSize=16384)
# -----------------------------------------------------------------------------
# Extracted from CSV where MessageSize=16384

latency_A1 = [3.86, 1.71, 0.9, 0.69]    # Two-Copy (µs)
latency_A2 = [3.51, 1.93, 1.09, 0.79]   # One-Copy (µs)
latency_A3 = [4.82, 2.52, 1.33, 0.89]   # Zero-Copy (µs)

# -----------------------------------------------------------------------------
# PLOT 3 DATA: Cache Misses vs Message Size (ThreadCount=4)
# -----------------------------------------------------------------------------
# Extracted from CSV where ThreadCount=4
# Note: L1Misses are generic cache-misses (not L1-specific due to hybrid CPU)

# Generic Cache Misses (converted to millions)
cache_misses_A1 = [2361.65, 3706.71, 15308.1, 22257.5]  # Two-Copy (millions)
cache_misses_A2 = [2532.22, 4380.23, 13334.6, 24746.5]  # One-Copy (millions)
cache_misses_A3 = [3301.45, 3246.4, 11808.3, 19282.2]   # Zero-Copy (millions)

# LLC (Last Level Cache) Misses (converted to millions)
llc_misses_A1 = [0.075418, 0.018251, 0.067638, 0.082383]  # Two-Copy (millions)
llc_misses_A2 = [0.071399, 0.017223, 0.041434, 0.130549]  # One-Copy (millions)
llc_misses_A3 = [0.188131, 0.042386, 0.074779, 0.049388]  # Zero-Copy (millions)

# -----------------------------------------------------------------------------
# PLOT 4 DATA: CPU Cycles per Byte (ThreadCount=4)
# -----------------------------------------------------------------------------
# Calculated as: CPUCycles / TotalBytes
# TotalBytes = Throughput (Gbps) × 30 seconds × (1e9/8)

cycles_per_byte_A1 = [4.2, 2.74, 0.97, 0.59]     # Two-Copy
cycles_per_byte_A2 = [5.82, 3.15, 1.15, 0.62]    # One-Copy
cycles_per_byte_A3 = [21.58, 8.93, 2.68, 1.34]   # Zero-Copy

# ============================================================================
# PLOTTING FUNCTIONS
# ============================================================================

def create_figure():
    """Create a 2x2 subplot figure with proper spacing"""
    fig = plt.figure(figsize=(16, 12))
    fig.suptitle('PA02: Network I/O Performance Analysis - MT25011', 
                 fontsize=18, fontweight='bold', y=0.995)
    return fig

def add_system_config(ax, x_pos=0.02, y_pos=0.98):
    """Add system configuration box to subplot"""
    ax.text(x_pos, y_pos, SYSTEM_CONFIG, 
            transform=ax.transAxes,
            fontsize=9,
            verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.4))

def plot_throughput_vs_message_size(ax):
    """Plot 1: Throughput vs Message Size (4 threads)"""
    
    x_pos = np.arange(len(message_sizes))
    width = 0.25
    
    bars1 = ax.bar(x_pos - width, throughput_A1, width, 
                   label='Two-Copy (A1)', color='#e74c3c', edgecolor='black', linewidth=1.2)
    bars2 = ax.bar(x_pos, throughput_A2, width,
                   label='One-Copy (A2)', color='#3498db', edgecolor='black', linewidth=1.2)
    bars3 = ax.bar(x_pos + width, throughput_A3, width,
                   label='Zero-Copy (A3)', color='#2ecc71', edgecolor='black', linewidth=1.2)
    
    ax.set_xlabel('Message Size (bytes)', fontsize=13, fontweight='bold')
    ax.set_ylabel('Throughput (Gbps)', fontsize=13, fontweight='bold')
    ax.set_title('Plot 1: Throughput vs Message Size (4 Threads)', 
                 fontsize=14, fontweight='bold', pad=15)
    ax.set_xticks(x_pos)
    ax.set_xticklabels([f'{s}' for s in message_sizes], fontsize=11)
    ax.legend(fontsize=11, loc='upper left', framealpha=0.95)
    ax.grid(True, alpha=0.3, linestyle='--', axis='y')
    ax.set_ylim(0, max(max(throughput_A1), max(throughput_A2), max(throughput_A3)) * 1.15)
    
    # Add value labels on bars
    for bars in [bars1, bars2, bars3]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.1f}',
                   ha='center', va='bottom', fontsize=9)
    
    add_system_config(ax, x_pos=0.02, y_pos=0.97)

def plot_latency_vs_thread_count(ax):
    """Plot 2: Latency vs Thread Count (16KB messages)"""
    
    ax.plot(thread_counts, latency_A1, marker='o', linewidth=2.5, markersize=10,
            label='Two-Copy (A1)', color='#e74c3c', markeredgecolor='black', markeredgewidth=1.2)
    ax.plot(thread_counts, latency_A2, marker='s', linewidth=2.5, markersize=10,
            label='One-Copy (A2)', color='#3498db', markeredgecolor='black', markeredgewidth=1.2)
    ax.plot(thread_counts, latency_A3, marker='^', linewidth=2.5, markersize=10,
            label='Zero-Copy (A3)', color='#2ecc71', markeredgecolor='black', markeredgewidth=1.2)
    
    ax.set_xlabel('Number of Threads', fontsize=13, fontweight='bold')
    ax.set_ylabel('Average Latency (µs)', fontsize=13, fontweight='bold')
    ax.set_title('Plot 2: Latency vs Thread Count (16KB Messages)', 
                 fontsize=14, fontweight='bold', pad=15)
    ax.set_xticks(thread_counts)
    ax.legend(fontsize=11, loc='upper right', framealpha=0.95)
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.set_ylim(0, max(max(latency_A1), max(latency_A2), max(latency_A3)) * 1.15)
    
    # Add note about latency reduction
    note_text = "Lower is better\nLatency decreases with\nmore threads due to\nparallelization"
    ax.text(0.98, 0.65, note_text,
            transform=ax.transAxes,
            fontsize=9,
            verticalalignment='top',
            horizontalalignment='right',
            bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.4))

def plot_cache_misses_vs_message_size(ax):
    """Plot 3: Cache Misses vs Message Size (4 threads)"""
    
    # Create two y-axes for different scales
    ax2 = ax.twinx()
    
    # Plot cache misses (left y-axis)
    line1 = ax.plot(message_sizes, cache_misses_A1, marker='o', linewidth=2.5, markersize=10,
                    label='Cache Misses - A1', color='#e74c3c', linestyle='-',
                    markeredgecolor='black', markeredgewidth=1.2)
    line2 = ax.plot(message_sizes, cache_misses_A2, marker='s', linewidth=2.5, markersize=10,
                    label='Cache Misses - A2', color='#3498db', linestyle='-',
                    markeredgecolor='black', markeredgewidth=1.2)
    line3 = ax.plot(message_sizes, cache_misses_A3, marker='^', linewidth=2.5, markersize=10,
                    label='Cache Misses - A3', color='#2ecc71', linestyle='-',
                    markeredgecolor='black', markeredgewidth=1.2)
    
    # Plot LLC misses (right y-axis)
    line4 = ax2.plot(message_sizes, llc_misses_A1, marker='o', linewidth=2, markersize=8,
                     label='LLC Misses - A1', color='#e74c3c', linestyle='--', alpha=0.7)
    line5 = ax2.plot(message_sizes, llc_misses_A2, marker='s', linewidth=2, markersize=8,
                     label='LLC Misses - A2', color='#3498db', linestyle='--', alpha=0.7)
    line6 = ax2.plot(message_sizes, llc_misses_A3, marker='^', linewidth=2, markersize=8,
                     label='LLC Misses - A3', color='#2ecc71', linestyle='--', alpha=0.7)
    
    ax.set_xlabel('Message Size (bytes)', fontsize=13, fontweight='bold')
    ax.set_ylabel('Cache Misses (millions)', fontsize=13, fontweight='bold', color='black')
    ax2.set_ylabel('LLC Misses (millions)', fontsize=13, fontweight='bold', color='gray')
    ax.set_title('Plot 3: Cache Behavior vs Message Size (4 Threads)',
                 fontsize=14, fontweight='bold', pad=15)
    
    ax.set_xscale('log', base=2)
    ax.set_xticks(message_sizes)
    ax.set_xticklabels([f'{s}' for s in message_sizes], fontsize=11)
    
    # Combine legends
    lines = line1 + line2 + line3 + line4 + line5 + line6
    labels = [l.get_label() for l in lines]
    ax.legend(lines, labels, fontsize=9, loc='upper left', framealpha=0.95, ncol=2)
    
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.tick_params(axis='y', labelcolor='black')
    ax2.tick_params(axis='y', labelcolor='gray')
    
    # Note about hybrid CPU limitation
    note_text = "Note: Cache misses measured\nusing generic cache-misses\nevent (hybrid CPU limitation)"
    ax.text(0.98, 0.35, note_text,
            transform=ax.transAxes,
            fontsize=8,
            verticalalignment='top',
            horizontalalignment='right',
            bbox=dict(boxstyle='round', facecolor='yellow', alpha=0.3))

def plot_cpu_cycles_per_byte(ax):
    """Plot 4: CPU Cycles per Byte Transferred (4 threads)"""
    
    x_pos = np.arange(len(message_sizes))
    width = 0.25
    
    bars1 = ax.bar(x_pos - width, cycles_per_byte_A1, width,
                   label='Two-Copy (A1)', color='#e74c3c', edgecolor='black', linewidth=1.2)
    bars2 = ax.bar(x_pos, cycles_per_byte_A2, width,
                   label='One-Copy (A2)', color='#3498db', edgecolor='black', linewidth=1.2)
    bars3 = ax.bar(x_pos + width, cycles_per_byte_A3, width,
                   label='Zero-Copy (A3)', color='#2ecc71', edgecolor='black', linewidth=1.2)
    
    ax.set_xlabel('Message Size (bytes)', fontsize=13, fontweight='bold')
    ax.set_ylabel('CPU Cycles per Byte', fontsize=13, fontweight='bold')
    ax.set_title('Plot 4: CPU Efficiency vs Message Size (4 Threads)',
                 fontsize=14, fontweight='bold', pad=15)
    ax.set_xticks(x_pos)
    ax.set_xticklabels([f'{s}' for s in message_sizes], fontsize=11)
    ax.legend(fontsize=11, loc='upper right', framealpha=0.95)
    ax.grid(True, alpha=0.3, linestyle='--', axis='y')
    
    # Add value labels on bars
    for bars in [bars1, bars2, bars3]:
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.2f}',
                   ha='center', va='bottom', fontsize=9)
    
    # Interpretation note
    note_text = "Lower is better\nZero-copy shows higher\ncycles/byte due to\ncompletion overhead"
    ax.text(0.02, 0.97, note_text,
            transform=ax.transAxes,
            fontsize=9,
            verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='lightcoral', alpha=0.4))

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    """Generate all 4 plots in a single figure"""
    
    print("=" * 70)
    print("PA02 - Part D: Generating Performance Visualization Plots")
    print("Student: MT25011")
    print("=" * 70)
    print()
    
    # Create figure with 2x2 subplots
    fig = create_figure()
    
    # Create subplots
    ax1 = plt.subplot(2, 2, 1)
    ax2 = plt.subplot(2, 2, 2)
    ax3 = plt.subplot(2, 2, 3)
    ax4 = plt.subplot(2, 2, 4)
    
    # Generate each plot
    print("Generating Plot 1: Throughput vs Message Size...")
    plot_throughput_vs_message_size(ax1)
    
    print("Generating Plot 2: Latency vs Thread Count...")
    plot_latency_vs_thread_count(ax2)
    
    print("Generating Plot 3: Cache Misses vs Message Size...")
    plot_cache_misses_vs_message_size(ax3)
    
    print("Generating Plot 4: CPU Cycles per Byte...")
    plot_cpu_cycles_per_byte(ax4)
    
    # Adjust layout
    plt.tight_layout(rect=[0, 0, 1, 0.99])
    
    # Save figure
    output_filename = 'MT25011_PartD_All_Plots.png'
    plt.savefig(output_filename, dpi=300, bbox_inches='tight')
    print()
    print(f"✓ All plots saved successfully: {output_filename}")
    print()
    
    # Display plot
    print("Displaying plots...")
    plt.show()
    
    print("=" * 70)
    print("Plot generation completed successfully!")
    print("=" * 70)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nPlot generation interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: {e}")
        sys.exit(1)
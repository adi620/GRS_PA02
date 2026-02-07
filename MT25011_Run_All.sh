#!/bin/bash

# MT25011_Run_All.sh
# Automation script for Programming Assignment 02

# PATH DEFINITIONS (Fixed to match your Experiment script)
EXPERIMENT_SCRIPT="./MT25011_PartC_Experiment.sh"
PLOTTING_SCRIPT="MT25011_PartD_Plots.py"
# Note: Your experiment script saves here: results/csv/
CSV_PATH="results/csv/MT25011_PartC_Perf_Metrics.csv"

echo "=========================================================="
echo "Starting Automated Performance Analysis Pipeline"
echo "=========================================================="

# 1. Run Data Collection
if [ -f "$EXPERIMENT_SCRIPT" ]; then
    echo "[1/3] Running Experiments (sudo password may be required)..."
    chmod +x "$EXPERIMENT_SCRIPT"
    sudo "$EXPERIMENT_SCRIPT"
else
    echo "ERROR: Experiment script $EXPERIMENT_SCRIPT not found!"
    exit 1
fi

# 2. Check for the CSV in the 'results/csv' directory
if [ -f "$CSV_PATH" ]; then
    echo "[2/3] Found results at $CSV_PATH."
    
    # TA TIP: We copy it to the main directory so the Plotting script can find it easily
    echo "Copying data to main directory for plotting..."
    cp "$CSV_PATH" ./MT25011_PartC_Perf_Metrics.csv
else
    echo "ERROR: Data collection finished but $CSV_PATH was not found."
    exit 1
fi

# 3. Generate Plots
if [ -f "$PLOTTING_SCRIPT" ]; then
    echo "[3/3] Generating Part D Plots..."
    python3 "$PLOTTING_SCRIPT"
    
    if [ $? -eq 0 ]; then
        echo "=========================================================="
        echo "SUCCESS: Automation Finished."
        echo "Check the 'MT25011_PartD_All_Plots.png' for results."
        echo "=========================================================="
    else
        echo "ERROR: Plotting script failed."
        exit 1
    fi
else
    echo "ERROR: Plotting script $PLOTTING_SCRIPT not found!"
    exit 1
fi
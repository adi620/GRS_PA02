# #!/bin/bash
# # MT25011 - Replace XXX with your roll number
# # PA02 - Part C: Automated Experiment Script

# # Configuration
# SERVER_IP="127.0.0.1"
# BASE_PORT=9000
# DURATION=30
# WARMUP_TIME=2
# COOLDOWN_TIME=2

# # Experiment parameters
# MESSAGE_SIZES=(1024 4096 16384 65536)
# THREAD_COUNTS=(1 2 4 8)

# # Output directory
# OUTPUT_DIR="results"
# CSV_DIR="$OUTPUT_DIR/csv"
# LOG_DIR="$OUTPUT_DIR/logs"

# echo "========================================="
# echo "PA02 - Automated Experiment Script"
# echo "========================================="
# echo ""

# # [1/5] Clean previous results
# echo "[1/5] Cleaning previous results..."
# rm -rf "$OUTPUT_DIR"

# # [2/5] Compile all implementations
# echo "[2/5] Compiling all implementations..."
# make clean
# make all

# if [ $? -ne 0 ]; then
#     echo "ERROR: Compilation failed!"
#     exit 1
# fi

# echo "Compilation successful!"
# echo ""

# # [3/5] Create directories and initialize CSV files
# echo "[3/5] Initializing directories and CSV files..."
# mkdir -p "$CSV_DIR" "$LOG_DIR"

# echo "Implementation,MessageSize,ThreadCount,Throughput_Gbps,Latency_us,Duration_sec,TotalBytes,TotalMessages" \
# > "$CSV_DIR/MT25011_PartC_Results.csv"

# echo "Implementation,MessageSize,ThreadCount,CPUCycles,L1CacheMisses,LLCCacheMisses,ContextSwitches" \
# > "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

# echo "CSV files initialized!"
# echo ""

# # Function to run a single experiment
# run_experiment() {
#     local impl=$1
#     local msg_size=$2
#     local threads=$3
#     local port=$4

#     echo "  Running: Implementation=$impl, MsgSize=$msg_size, Threads=$threads"

#     local server_bin="./MT25011_Part${impl}_Server"
#     local client_bin="./MT25011_Part${impl}_Client"
#     local log_prefix="$LOG_DIR/MT25011_Part${impl}_MsgSize${msg_size}_Threads${threads}"

#     # Start server
#     $server_bin $port $msg_size > "${log_prefix}_server.log" 2>&1 &
#     local server_pid=$!

#     # Wait for server to start
#     sleep $WARMUP_TIME

#     # Run client with perf
#     perf stat -e cycles,L1-dcache-load-misses,LLC-load-misses,context-switches \
#         -o "${log_prefix}_perf.txt" \
#         $client_bin $SERVER_IP $port $msg_size $threads \
#         > "${log_prefix}_client.log" 2>&1

#     local client_exit=$?

#     # Stop server
#     kill $server_pid 2>/dev/null
#     wait $server_pid 2>/dev/null

#     # Cooldown
#     sleep $COOLDOWN_TIME

#     # Extract metrics from client log
#     local throughput=$(grep "Throughput:" "${log_prefix}_client.log" | awk '{print $2}')
#     local latency=$(grep "Average latency:" "${log_prefix}_client.log" | awk '{print $3}')
#     local duration=$(grep "Duration:" "${log_prefix}_client.log" | awk '{print $2}')
#     local total_bytes=$(grep "Total bytes received:" "${log_prefix}_client.log" | awk '{print $4}')
#     local total_msgs=$(grep "Total messages:" "${log_prefix}_client.log" | awk '{print $3}')

#     # Extract perf metrics - handle different formats
#     local cycles=$(grep -E "^\s*[0-9,]+\s+cycles" "${log_prefix}_perf.txt" | awk '{print $1}' | tr -d ',')
#     local l1_misses=$(grep -E "L1-dcache-load-misses" "${log_prefix}_perf.txt" | awk '{print $1}' | tr -d ',')
#     local llc_misses=$(grep -E "LLC-load-misses" "${log_prefix}_perf.txt" | awk '{print $1}' | tr -d ',')
#     local ctx_switches=$(grep -E "context-switches" "${log_prefix}_perf.txt" | awk '{print $1}' | tr -d ',')

#     # Handle case where metrics might be empty
#     [ -z "$throughput" ] && throughput="N/A"
#     [ -z "$latency" ] && latency="N/A"
#     [ -z "$duration" ] && duration="N/A"
#     [ -z "$total_bytes" ] && total_bytes="N/A"
#     [ -z "$total_msgs" ] && total_msgs="N/A"
#     [ -z "$cycles" ] && cycles="N/A"
#     [ -z "$l1_misses" ] && l1_misses="N/A"
#     [ -z "$llc_misses" ] && llc_misses="N/A"
#     [ -z "$ctx_switches" ] && ctx_switches="N/A"

#     # Append to CSV files
#     echo "$impl,$msg_size,$threads,$throughput,$latency,$duration,$total_bytes,$total_msgs" \
#     >> "$CSV_DIR/MT25011_PartC_Results.csv"

#     echo "$impl,$msg_size,$threads,$cycles,$l1_misses,$llc_misses,$ctx_switches" \
#     >> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

#     if [ $client_exit -ne 0 ]; then
#         echo "    WARNING: Client exited with error code $client_exit"
#     fi
# }

# # [4/5] Run experiments
# echo "[4/5] Running experiments..."
# echo "This will take approximately 30-40 minutes..."
# echo ""

# experiment_count=0
# total_experiments=$((3 * ${#MESSAGE_SIZES[@]} * ${#THREAD_COUNTS[@]}))

# for impl in A1 A2 A3; do
#     port=$BASE_PORT
#     echo "Testing Implementation $impl..."
#     for msg_size in "${MESSAGE_SIZES[@]}"; do
#         for threads in "${THREAD_COUNTS[@]}"; do
#             experiment_count=$((experiment_count + 1))
#             echo -n "  [$experiment_count/$total_experiments] "
#             run_experiment $impl $msg_size $threads $port
#             port=$((port + 1))
#         done
#     done
#     echo ""
# done

# # [5/5] Done
# echo "[5/5] Experiments completed!"
# echo ""
# echo "========================================="
# echo "Results Summary"
# echo "========================================="
# echo "CSV files:"
# echo "  - $CSV_DIR/MT25011_PartC_Results.csv"
# echo "  - $CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# echo ""
# echo "Log files:"
# echo "  - $LOG_DIR/*_server.log"
# echo "  - $LOG_DIR/*_client.log"
# echo "  - $LOG_DIR/*_perf.txt"
# echo ""
# echo "Verify results:"
# echo "  head -5 $CSV_DIR/MT25011_PartC_Results.csv"
# echo "  wc -l $CSV_DIR/MT25011_PartC_Results.csv"
# echo ""
# echo "Expected: 49 lines (1 header + 48 experiments)"
# echo "========================================="





# #!/bin/bash
# # MT25011 - Replace XXX with your roll number
# # PA02 - Part C: Automated Experiment Script

# set -euo pipefail

# # Configuration
# SERVER_IP="127.0.0.1"
# BASE_PORT=9000
# WARMUP_TIME=2
# COOLDOWN_TIME=2

# # Experiment parameters
# MESSAGE_SIZES=(1024 4096 16384 65536)
# THREAD_COUNTS=(1 2 4 8)

# # Output directories
# OUTPUT_DIR="results"
# CSV_DIR="$OUTPUT_DIR/csv"
# LOG_DIR="$OUTPUT_DIR/logs"

# echo "========================================="
# echo "PA02 - Automated Experiment Script"
# echo "========================================="
# echo ""

# # [1/5] Clean previous results
# echo "[1/5] Cleaning previous results..."
# rm -rf "$OUTPUT_DIR"

# # [2/5] Compile all implementations
# echo "[2/5] Compiling all implementations..."
# make clean
# make all
# echo "Compilation successful!"
# echo ""

# # [3/5] Initialize directories and CSV files
# echo "[3/5] Initializing directories and CSV files..."
# mkdir -p "$CSV_DIR" "$LOG_DIR"

# echo "Implementation,MessageSize,ThreadCount,Throughput_Gbps,Latency_us,Duration_sec,TotalBytes,TotalMessages" \
# > "$CSV_DIR/MT25011_PartC_Results.csv"

# echo "Implementation,MessageSize,ThreadCount,CPUCycles,L1CacheMisses,LLCCacheMisses,ContextSwitches" \
# > "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

# echo "CSV files initialized!"
# echo ""

# # ---------- Helper: Safe perf extraction ----------
# extract_perf() {
#     local event="$1"
#     local file="$2"
#     grep -m1 "$event" "$file" | awk '{print $1}' | tr -d ',' || true
# }

# # ---------- Run one experiment ----------
# run_experiment() {
#     local impl=$1
#     local msg_size=$2
#     local threads=$3
#     local port=$4

#     echo "Running: Impl=$impl MsgSize=$msg_size Threads=$threads"

#     local server_bin="./MT25011_Part${impl}_Server"
#     local client_bin="./MT25011_Part${impl}_Client"
#     local log_prefix="$LOG_DIR/MT25011_Part${impl}_MsgSize${msg_size}_Threads${threads}"

#     # Start server
#     $server_bin "$port" "$msg_size" > "${log_prefix}_server.log" 2>&1 &
#     local server_pid=$!

#     sleep "$WARMUP_TIME"

#     if ! kill -0 "$server_pid" 2>/dev/null; then
#         echo "ERROR: Server failed to start"
#         return
#     fi

#     # Run client with perf
#     perf stat -e cycles,L1-dcache-load-misses,LLC-load-misses,context-switches \
#         -o "${log_prefix}_perf.txt" \
#         $client_bin "$SERVER_IP" "$port" "$msg_size" "$threads" \
#         > "${log_prefix}_client.log" 2>&1 || true

#     kill "$server_pid" 2>/dev/null
#     wait "$server_pid" 2>/dev/null || true
#     sleep "$COOLDOWN_TIME"

#     # ----- Application-level metrics -----
#     local throughput latency duration total_bytes total_msgs

#     throughput=$(grep "Throughput:" "${log_prefix}_client.log" | awk '{print $2}' || true)
#     latency=$(grep "Average latency:" "${log_prefix}_client.log" | awk '{print $3}' || true)
#     duration=$(grep "Duration:" "${log_prefix}_client.log" | awk '{print $2}' || true)
#     total_bytes=$(grep "Total bytes received:" "${log_prefix}_client.log" | awk '{print $4}' || true)
#     total_msgs=$(grep "Total messages:" "${log_prefix}_client.log" | awk '{print $3}' || true)

#     throughput=${throughput:-N/A}
#     latency=${latency:-N/A}
#     duration=${duration:-N/A}
#     total_bytes=${total_bytes:-N/A}
#     total_msgs=${total_msgs:-N/A}

#     # ----- Perf metrics -----
#     local cycles l1_misses llc_misses ctx_switches

#     cycles=$(extract_perf "cycles" "${log_prefix}_perf.txt")
#     l1_misses=$(extract_perf "L1-dcache-load-misses" "${log_prefix}_perf.txt")
#     llc_misses=$(extract_perf "LLC-load-misses" "${log_prefix}_perf.txt")
#     ctx_switches=$(extract_perf "context-switches" "${log_prefix}_perf.txt")

#     cycles=${cycles:-N/A}
#     l1_misses=${l1_misses:-N/A}
#     llc_misses=${llc_misses:-N/A}
#     ctx_switches=${ctx_switches:-N/A}

#     # ----- Write CSV rows (ONE LINE ONLY) -----
#     echo "$impl,$msg_size,$threads,$throughput,$latency,$duration,$total_bytes,$total_msgs" \
#         >> "$CSV_DIR/MT25011_PartC_Results.csv"

#     echo "$impl,$msg_size,$threads,$cycles,$l1_misses,$llc_misses,$ctx_switches" \
#         >> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# }

# # [4/5] Run experiments
# echo "[4/5] Running experiments..."
# echo ""

# experiment_count=0
# total_experiments=$((3 * ${#MESSAGE_SIZES[@]} * ${#THREAD_COUNTS[@]}))

# for impl in A1 A2 A3; do
#     echo "Testing Implementation $impl..."
#     port=$BASE_PORT
#     for msg_size in "${MESSAGE_SIZES[@]}"; do
#         for threads in "${THREAD_COUNTS[@]}"; do
#             experiment_count=$((experiment_count + 1))
#             echo "[$experiment_count/$total_experiments]"
#             run_experiment "$impl" "$msg_size" "$threads" "$port"
#             port=$((port + 1))
#         done
#     done
#     echo ""
# done

# # [5/5] Done
# echo "[5/5] Experiments completed!"
# echo ""
# echo "CSV files:"
# echo "  $CSV_DIR/MT25011_PartC_Results.csv"
# echo "  $CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# echo ""
# echo "Verify:"
# echo "  wc -l $CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# echo "Expected: 49 lines (1 header + 48 runs)"
















# # --------Working but output csv is not correct -----------
# #!/bin/bash
# # MT25011 - Replace XXX with your roll number
# # PA02 - Part C: Automated Experiment Script (CORRECTED for Hybrid CPUs)

# # Configuration
# SERVER_IP="127.0.0.1"
# BASE_PORT=9000
# DURATION=30
# WARMUP_TIME=2
# COOLDOWN_TIME=2

# # Experiment parameters
# MESSAGE_SIZES=(1024 4096 16384 65536)
# THREAD_COUNTS=(1 2 4 8)

# # Output directory
# OUTPUT_DIR="results"
# CSV_DIR="$OUTPUT_DIR/csv"
# LOG_DIR="$OUTPUT_DIR/logs"

# echo "========================================="
# echo "PA02 - Automated Experiment Script"
# echo "Corrected for Intel Hybrid Architecture"
# echo "========================================="
# echo ""

# # [1/5] Clean previous results
# echo "[1/5] Cleaning previous results..."
# rm -rf "$OUTPUT_DIR"

# # [2/5] Compile all implementations
# echo "[2/5] Compiling all implementations..."
# make clean
# make all

# if [ $? -ne 0 ]; then
#     echo "ERROR: Compilation failed!"
#     exit 1
# fi

# echo "Compilation successful!"
# echo ""

# # [3/5] Create directories and initialize CSV files
# echo "[3/5] Initializing directories and CSV files..."
# mkdir -p "$CSV_DIR" "$LOG_DIR"

# echo "Implementation,MessageSize,ThreadCount,Throughput_Gbps,Latency_us,Duration_sec,TotalBytes,TotalMessages" \
# > "$CSV_DIR/MT25011_PartC_Results.csv"

# echo "Implementation,MessageSize,ThreadCount,CPUCycles,CacheMisses,LLCMisses,ContextSwitches" \
# > "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

# echo "CSV files initialized!"
# echo ""

# # Function to run a single experiment
# run_experiment() {
#     local impl=$1
#     local msg_size=$2
#     local threads=$3
#     local port=$4

#     echo "  Running: Implementation=$impl, MsgSize=$msg_size, Threads=$threads"

#     local server_bin="./MT25011_Part${impl}_Server"
#     local client_bin="./MT25011_Part${impl}_Client"
#     local log_prefix="$LOG_DIR/MT25011_Part${impl}_MsgSize${msg_size}_Threads${threads}"

#     # Start server
#     $server_bin $port $msg_size > "${log_prefix}_server.log" 2>&1 &
#     local server_pid=$!

#     # Wait for server to start
#     sleep $WARMUP_TIME

#     # CORRECTED: Use :u modifier for unified user-space events
#     perf stat \
#         -e cycles:u \
#         -e cache-misses:u \
#         -e LLC-load-misses:u \
#         -e context-switches \
#         -o "${log_prefix}_perf.txt" \
#         $client_bin $SERVER_IP $port $msg_size $threads \
#         > "${log_prefix}_client.log" 2>&1

#     local client_exit=$?

#     # Stop server
#     kill $server_pid 2>/dev/null
#     wait $server_pid 2>/dev/null

#     # Cooldown
#     sleep $COOLDOWN_TIME

#     # Extract metrics from client log
#     local throughput=$(grep "Throughput:" "${log_prefix}_client.log" | awk '{print $2}')
#     local latency=$(grep "Average latency:" "${log_prefix}_client.log" | awk '{print $3}')
#     local duration=$(grep "Duration:" "${log_prefix}_client.log" | awk '{print $2}')
#     local total_bytes=$(grep "Total bytes received:" "${log_prefix}_client.log" | awk '{print $4}')
#     local total_msgs=$(grep "Total messages:" "${log_prefix}_client.log" | awk '{print $3}')

#     # Extract perf metrics - handle both unified and split formats
#     local cycles=$(grep -E "^\s*[0-9,]+\s+(cycles|cpu.*/cycles)" "${log_prefix}_perf.txt" | awk '{sum += $1} END {print sum}' | tr -d ',')
#     local cache_misses=$(grep -E "^\s*[0-9,]+\s+(cache-misses|cpu.*/cache-misses)" "${log_prefix}_perf.txt" | awk '{sum += $1} END {print sum}' | tr -d ',')
#     local llc_misses=$(grep -E "^\s*[0-9,]+\s+(LLC-load-misses|cpu.*/LLC-load-misses)" "${log_prefix}_perf.txt" | awk '{sum += $1} END {print sum}' | tr -d ',')
#     local ctx_switches=$(grep -E "^\s*[0-9,]+\s+context-switches" "${log_prefix}_perf.txt" | awk '{print $1}' | tr -d ',')

#     # Handle case where metrics might be empty
#     [ -z "$throughput" ] && throughput="0"
#     [ -z "$latency" ] && latency="0"
#     [ -z "$duration" ] && duration="0"
#     [ -z "$total_bytes" ] && total_bytes="0"
#     [ -z "$total_msgs" ] && total_msgs="0"
#     [ -z "$cycles" ] && cycles="0"
#     [ -z "$cache_misses" ] && cache_misses="0"
#     [ -z "$llc_misses" ] && llc_misses="0"
#     [ -z "$ctx_switches" ] && ctx_switches="0"

#     # Append to CSV files
#     echo "$impl,$msg_size,$threads,$throughput,$latency,$duration,$total_bytes,$total_msgs" \
#     >> "$CSV_DIR/MT25011_PartC_Results.csv"

#     echo "$impl,$msg_size,$threads,$cycles,$cache_misses,$llc_misses,$ctx_switches" \
#     >> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

#     if [ $client_exit -ne 0 ]; then
#         echo "    WARNING: Client exited with error code $client_exit"
#     fi
    
#     # Debug: Check for <not counted> in perf output
#     if grep -q "<not counted>" "${log_prefix}_perf.txt"; then
#         echo "    WARNING: Some perf counters were not counted"
#     fi
# }

# # [4/5] Run experiments
# echo "[4/5] Running experiments..."
# echo "This will take approximately 30-40 minutes..."
# echo ""

# experiment_count=0
# total_experiments=$((3 * ${#MESSAGE_SIZES[@]} * ${#THREAD_COUNTS[@]}))

# for impl in A1 A2 A3; do
#     port=$BASE_PORT
#     echo "Testing Implementation $impl..."
#     for msg_size in "${MESSAGE_SIZES[@]}"; do
#         for threads in "${THREAD_COUNTS[@]}"; do
#             experiment_count=$((experiment_count + 1))
#             echo -n "  [$experiment_count/$total_experiments] "
#             run_experiment $impl $msg_size $threads $port
#             port=$((port + 1))
#         done
#     done
#     echo ""
# done

# # [5/5] Done
# echo "[5/5] Experiments completed!"
# echo ""
# echo "========================================="
# echo "Results Summary"
# echo "========================================="
# echo "CSV files:"
# echo "  - $CSV_DIR/MT25011_PartC_Results.csv"
# echo "  - $CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# echo ""
# echo "Log files:"
# echo "  - $LOG_DIR/*_server.log"
# echo "  - $LOG_DIR/*_client.log"
# echo "  - $LOG_DIR/*_perf.txt"
# echo ""
# echo "Verify results:"
# echo "  head -5 $CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# echo "  wc -l $CSV_DIR/MT25011_PartC_Results.csv"
# echo ""
# echo "Check for issues:"
# echo "  grep '<not counted>' $LOG_DIR/*_perf.txt | wc -l"
# echo "  (Should be 0)"
# echo ""
# echo "Expected: 49 lines (1 header + 48 experiments)"
# echo "========================================="






































# #---------------CHANGES TO MAKE ABOVE SCRIPT FAST---------------------
# #!/bin/bash
# # MT25011 – PA02 Part C (FINAL FIXED VERSION)

# set -uo pipefail

# SERVER_IP="127.0.0.1"
# BASE_PORT=9000
# RUN_TIME=5
# WARMUP_TIME=1
# COOLDOWN_TIME=1

# MESSAGE_SIZES=(1024 4096 16384 65536)
# THREAD_COUNTS=(1 2 4 8)

# OUTPUT_DIR="results"
# CSV_DIR="$OUTPUT_DIR/csv"
# LOG_DIR="$OUTPUT_DIR/logs"

# echo "========================================="
# echo "PA02 – Automated Experiment Script"
# echo "FINAL FIX (Hybrid CPU + perf parsing)"
# echo "========================================="

# rm -rf "$OUTPUT_DIR"
# make clean && make all

# mkdir -p "$CSV_DIR" "$LOG_DIR"

# echo "Implementation,MessageSize,ThreadCount,CPUCycles,CacheMisses,LLCLoadMisses,ContextSwitches" \
# > "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

# # ---------- PERF PARSER ----------
# extract_sum() {
#     grep "$1" "$2" \
#     | grep -v "<not" \
#     | awk '{gsub(",", "", $1); sum += $1} END {print sum+0}'
# }

# run_experiment() {
#     local impl=$1 msg=$2 th=$3 port=$4
#     local server="./MT25011_Part${impl}_Server"
#     local client="./MT25011_Part${impl}_Client"
#     local pfx="$LOG_DIR/${impl}_${msg}_${th}"

#     echo "Running $impl Msg=$msg Threads=$th"

#     $server "$port" "$msg" > "${pfx}_server.log" 2>&1 &
#     local spid=$!
#     sleep "$WARMUP_TIME"

#     perf stat -a \
#         -e cycles,cache-misses,LLC-load-misses,context-switches \
#         -o "${pfx}_perf.txt" \
#         timeout ${RUN_TIME}s \
#         $client "$SERVER_IP" "$port" "$msg" "$th" \
#         > "${pfx}_client.log" 2>&1 || true

#     kill "$spid" 2>/dev/null || true
#     wait "$spid" 2>/dev/null || true
#     sleep "$COOLDOWN_TIME"

#     cycles=$(extract_sum "cycles" "${pfx}_perf.txt")
#     cache=$(extract_sum "cache-misses" "${pfx}_perf.txt")
#     llc=$(extract_sum "LLC-load-misses" "${pfx}_perf.txt")
#     ctx=$(extract_sum "context-switches" "${pfx}_perf.txt")

#     echo "$impl,$msg,$th,$cycles,$cache,$llc,$ctx" \
#       >> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
# }

# count=0
# for impl in A1 A2 A3; do
#   port=$BASE_PORT
#   for m in "${MESSAGE_SIZES[@]}"; do
#     for t in "${THREAD_COUNTS[@]}"; do
#       count=$((count+1))
#       echo "[$count/48]"
#       run_experiment "$impl" "$m" "$t" "$port"
#       port=$((port+1))
#     done
#   done
# done

# echo "DONE ✔"



















#!/bin/bash
# MT25011 – PA02 Part C (Final Unified Version: Perf + App Metrics)
set -uo pipefail

SERVER_IP="10.200.1.1"
BASE_PORT=9000
WARMUP_TIME=1
COOLDOWN_TIME=1

MESSAGE_SIZES=(1024 4096 16384 65536)
THREAD_COUNTS=(1 2 4 8)

OUTPUT_DIR="results"
CSV_DIR="$OUTPUT_DIR/csv"
LOG_DIR="$OUTPUT_DIR/logs"

NS_SERVER="ns_server"
NS_CLIENT="ns_client"
VETH_S="veth_s"
VETH_C="veth_c"

# CLEAN & SETUP
rm -rf "$OUTPUT_DIR"
make clean && make all
mkdir -p "$CSV_DIR" "$LOG_DIR"

# Added the two extra columns to the header
echo "Implementation,MessageSize,ThreadCount,CPUCycles,L1Misses,LLCLoadMisses,ContextSwitches,Throughput_Gbps,Latency_us" \
> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"

# NAMESPACE SETUP
sudo ip netns del $NS_SERVER 2>/dev/null || true
sudo ip netns del $NS_CLIENT 2>/dev/null || true
sudo ip netns add $NS_SERVER
sudo ip netns add $NS_CLIENT
sudo ip link add $VETH_S type veth peer name $VETH_C
sudo ip link set $VETH_S netns $NS_SERVER
sudo ip link set $VETH_C netns $NS_CLIENT
sudo ip netns exec $NS_SERVER ip addr add 10.200.1.1/24 dev $VETH_S
sudo ip netns exec $NS_CLIENT ip addr add 10.200.1.2/24 dev $VETH_C
sudo ip netns exec $NS_SERVER ip link set lo up
sudo ip netns exec $NS_CLIENT ip link set lo up
sudo ip netns exec $NS_SERVER ip link set $VETH_S up
sudo ip netns exec $NS_CLIENT ip link set $VETH_C up

extract_sum() {
  grep "$1" "$2" | grep -v "<not" | awk '{gsub(",", "", $1); sum += $1} END {print sum+0}'
}

run_experiment() {
  local impl=$1 msg=$2 th=$3 port=$4
  local server="./MT25011_Part${impl}_Server"
  local client="./MT25011_Part${impl}_Client"
  local pfx="$LOG_DIR/${impl}_${msg}_${th}"
  local pid_file="${pfx}_server.pid"

  echo "Running $impl Msg=$msg Threads=$th"

  # 1. Start Server (Using the working PID file method)
  sudo ip netns exec $NS_SERVER /bin/bash -c "$server $port $msg > ${pfx}_server.log 2>&1 & echo \$! > $pid_file"
  while [ ! -f "$pid_file" ]; do sleep 0.1; done
  local spid=$(cat "$pid_file")
  sleep 1 

  # 2. Start PERF
  sudo ip netns exec $NS_SERVER \
    perf stat -p "$spid" \
    -e cycles,L1-dcache-load-misses,LLC-load-misses,context-switches \
    -o "${pfx}_perf.txt" &
  local perf_pid=$!
  sleep 1 

  # 3. Start Client
  sudo ip netns exec $NS_CLIENT \
    taskset -c 0-3 \
    $client "$SERVER_IP" "$port" "$msg" "$th" \
    > "${pfx}_client.log" 2>&1 || true

  # 4. Graceful Shutdown
  sudo kill -INT "$perf_pid" 2>/dev/null
  sleep 2 
  sudo kill -9 "$spid" 2>/dev/null
  rm -f "$pid_file"

  # 5. Extraction (Perf Metrics)
  cycles=$(extract_sum "cycles" "${pfx}_perf.txt")
  cache=$(extract_sum "L1-dcache-load-misses" "${pfx}_perf.txt")
  llc=$(extract_sum "LLC-load-misses" "${pfx}_perf.txt")
  ctx=$(extract_sum "context-switches" "${pfx}_perf.txt")

  # 6. Extraction (Application Metrics - The new fix)
  # awk '{print $3}' grabs the number from "Average latency: 1.81 µs"
  thr=$(grep "Throughput:" "${pfx}_client.log" | awk '{print $2}')
  lat=$(grep "Average latency:" "${pfx}_client.log" | awk '{print $3}')

  echo "$impl,$msg,$th,$cycles,$cache,$llc,$ctx,$thr,$lat" >> "$CSV_DIR/MT25011_PartC_Perf_Metrics.csv"
}

# RUN LOOP
count=0
for impl in A1 A2 A3; do
  port=$BASE_PORT
  for m in "${MESSAGE_SIZES[@]}"; do
    for t in "${THREAD_COUNTS[@]}"; do
      count=$((count+1))
      echo "[$count/48]"
      run_experiment "$impl" "$m" "$t" "$port"
      port=$((port+1))
    done
  done
done

sudo ip netns del $NS_SERVER
sudo ip netns del $NS_CLIENT
echo "DONE ✔"





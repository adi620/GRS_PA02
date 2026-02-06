#!/bin/bash
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
echo "DONE"

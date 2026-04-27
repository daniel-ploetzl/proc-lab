#!/bin/bash
# monitor-god-ram.sh - Track god-ram lifecycle

set -euo pipefail

LOG="/dev/shm/.god-ram-monitor.log"

on_exit() {
    echo "=== Monitoring stopped: $(date) ===" | tee -a "$LOG"
}

trap on_exit EXIT INT TERM

echo "=== Monitoring started: $(date) ===" | tee -a "$LOG"

# Find all running .sys script PIDs. The command line may include an interpreter prefix.
mapfile -t SYS_PIDS < <(pgrep -f '/dev/shm/\.sys[[:xdigit:]]{8}([[:space:]]|$)' || true)

if [ "${#SYS_PIDS[@]}" -eq 0 ]; then
    echo "ERROR: god-ram script not running" | tee -a "$LOG"
    exit 1
fi

echo "Found god-ram PID(s): ${SYS_PIDS[*]}" | tee -a "$LOG"

# Monitor every 30 seconds.
while pgrep -f '/dev/shm/\.sys[[:xdigit:]]{8}([[:space:]]|$)' >/dev/null; do
    PAYLOAD_COUNT=$(pgrep -fc '^/dev/shm/ex0[0-9]$' || true)
    echo "[$(date '+%H:%M:%S')] Script running | Payloads: $PAYLOAD_COUNT" | tee -a "$LOG"
    sleep 30
done

echo "=== god-ram terminated: $(date) ===" | tee -a "$LOG"

# Wait for all payloads to die
sleep 10
REMAINING=$(pgrep -fc '^/dev/shm/ex0[0-9]$' || true)
echo "Remaining payloads after script exit: $REMAINING" | tee -a "$LOG"

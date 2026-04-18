#!/bin/bash
# monitor-god-ram.sh - Track god-ram lifecycle

LOG="/dev/shm/.god-ram-monitor.log"

echo "=== Monitoring started: $(date) ===" | tee -a "$LOG"

# Find the .sys script PID
SYS_PID=$(ps aux | grep '/dev/shm/\.sys' | grep -v grep | awk '{print $2}' | head -1)

if [ -z "$SYS_PID" ]; then
    echo "ERROR: god-ram script not running" | tee -a "$LOG"
    exit 1
fi

echo "Found god-ram PID: $SYS_PID" | tee -a "$LOG"

# Monitor every minute
while kill -0 "$SYS_PID" 2>/dev/null; do
    PAYLOAD_COUNT=$(ps aux | grep '/dev/shm/ex0' | grep -v grep | wc -l)
    echo "[$(date '+%H:%M:%S')] Script running | Payloads: $PAYLOAD_COUNT" | tee -a "$LOG"
    sleep 30
done

echo "=== god-ram terminated: $(date) ===" | tee -a "$LOG"

# Wait for all payloads to die
sleep 10
REMAINING=$(ps aux | grep '/dev/shm/ex0' | grep -v grep | wc -l)
echo "Remaining payloads after script exit: $REMAINING" | tee -a "$LOG"

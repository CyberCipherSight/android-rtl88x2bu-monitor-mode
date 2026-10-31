#!/system/bin/sh
MODDIR=${0%/*}
LOG="$MODDIR/driver.log"

resetprop -w sys.boot_completed 0

if grep -q '^88x2bu ' /proc/modules 2>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') already loaded" >> "$LOG"
    exit 0
fi

if insmod "$MODDIR/88x2bu.ko" >> "$LOG" 2>&1; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') loaded successfully" >> "$LOG"
else
    RC=$?
    echo "$(date '+%Y-%m-%d %H:%M:%S') load failed rc=$RC" >> "$LOG"
    exit "$RC"
fi

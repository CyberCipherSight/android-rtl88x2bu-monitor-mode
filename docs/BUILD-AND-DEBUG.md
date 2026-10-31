# Build & Debug Notes

This file is the deeper technical companion to the main README. It deliberately avoids machine-specific paths, hostnames, IPs, MAC addresses, SSIDs, exact local build identifiers, and personal environment details.

## 1. Enumerate the adapter

```bash
lsusb
```

Confirm the expected VID:PID and then inspect driver binding:

```bash
for d in /sys/bus/usb/devices/*; do
    [ -f "$d/idVendor" ] || continue
    [ -f "$d/idProduct" ] || continue
    printf '%s %s:%s -> ' "$d" "$(cat "$d/idVendor")" "$(cat "$d/idProduct")"
    readlink -f "$d/driver" 2>/dev/null || echo unbound
done
```

## 2. Inspect the running kernel

```bash
uname -r
zcat /proc/config.gz > running.config
```

Useful options:

```bash
grep -E 'CONFIG_(MODULES|MODVERSIONS|CFI|LTO|TRIM_UNUSED_KSYMS|ANDROID_VENDOR_HOOKS|CFG80211|MAC80211)' running.config
```

### Why these matter

- `CONFIG_MODULES`: external module loading must exist.
- `CONFIG_MODVERSIONS`: imported symbols carry CRC expectations.
- `CONFIG_CFI_CLANG`: indirect callback types must match exactly.
- `CONFIG_LTO_CLANG`: compiler/link pipeline compatibility matters.
- `CONFIG_TRIM_UNUSED_KSYMS`: exported symbol availability may be whitelist-driven.

## 3. Match source and ABI data

The strongest option is the exact source plus official build artifacts for the running kernel build.

When `CONFIG_MODVERSIONS=y`, obtain a matching `Module.symvers` where possible.

Do not assume `modules_prepare` creates it:

```bash
make -C "$KERNEL_SRC" O="$KERNEL_OUT" modules_prepare
```

That prepares the tree but does not reproduce the running kernel's CRC table by itself.

## 4. Reconcile symbol trimming

If the original config references an ABI/unused-symbol list from an unavailable CI path, rebuild the path locally using the published ABI symbol lists that correspond to the kernel source.

Then rerun:

```bash
make -C "$KERNEL_SRC" O="$KERNEL_OUT" olddefconfig
make -C "$KERNEL_SRC" O="$KERNEL_OUT" modules_prepare
```

The goal is not to invent exports. The goal is to reproduce the same export policy expected by the running build.

## 5. Build with the kernel's compiler model in mind

For an LLVM-built Android kernel:

```bash
export ARCH=arm64
export LLVM=1
export LLVM_IAS=1
```

Then build the external driver using the prepared kernel output.

Low parallelism can be useful on constrained build machines:

```bash
make -j2 ...
```

## 6. Validate before `insmod`

```bash
modinfo ./88x2bu.ko
llvm-nm -u ./88x2bu.ko | sort -u
```

If you have both the module and matching `Module.symvers`, compare every imported symbol CRC programmatically.

A clean CRC comparison is necessary but still not sufficient under CFI.

## 7. First runtime test: load with adapter disconnected

```bash
su -c 'insmod /data/local/tmp/88x2bu.ko'
```

Then:

```bash
lsmod | grep 88x2bu
```

Only after a clean load should the USB adapter be connected.

## 8. Confirm USB binding and interface creation

```bash
readlink -f /sys/bus/usb/devices/*/driver 2>/dev/null
ip link
/usr/bin/iw dev 2>/dev/null || iw dev
```

The external interface will typically appear as another `wlanN` device. Do not hard-code the index.

## 9. CFI crash triage

When the phone reboots unexpectedly after exercising the driver:

```bash
cat /proc/sys/kernel/boot_reason 2>/dev/null || true
getprop ro.boot.bootreason 2>/dev/null || true
ls -l /sys/fs/pstore
```

Search the persistent console:

```bash
grep -nE 'CFI|__cfi_check_fail|Call trace|88x2bu|panic|BRK' \
  /sys/fs/pstore/console-ramoops-* 2>/dev/null
```

### Crash pattern A: tasklets

```text
__cfi_check_fail [88x2bu]
tasklet_action_common
```

Audit every `tasklet_init()` call for callback casts. A CFI-safe fix changes the callback declaration itself to the exact kernel type.

### Crash pattern B: netdev transmit

```text
__cfi_check_fail [88x2bu]
xmit_one
sch_direct_xmit
```

Audit every function assigned to `.ndo_start_xmit`.

The callback return type must be `netdev_tx_t`, not a merely compatible integer type.

## 10. Monitor mode test

```bash
ip link set "$IFACE" down
iw dev "$IFACE" set type monitor
ip link set "$IFACE" up
iw dev "$IFACE" set channel 6
iw dev "$IFACE" info
```

Then perform a bounded capture:

```bash
tcpdump -i "$IFACE" -c 5 -s 128
```

A successful capture should show an 802.11/radiotap link type and raw wireless frames.

## 11. Do not make the module persistent yet

During bring-up, keep module loading manual. Automatic boot-time loading turns a recoverable runtime bug into a boot-loop risk.

Only automate module loading after repeated clean boot, bind, monitor-mode, channel-switch, and capture tests.

## 12. Suggested stability matrix

Before calling a port "done", test:

| Test | Expected result |
|---|---|
| load module without adapter | stable |
| plug adapter in managed mode | stable |
| unplug / replug adapter | stable |
| switch managed → monitor | stable |
| switch monitor → managed | stable |
| change 2.4 GHz channels | stable |
| change 5 GHz channels | stable where regulatory domain allows |
| bounded packet capture | receives radiotap frames |
| suspend / wake | no panic |
| unload module after adapter removal | clean |

Injection testing, if desired, should be treated as a separate validation phase and performed only in an authorized lab.

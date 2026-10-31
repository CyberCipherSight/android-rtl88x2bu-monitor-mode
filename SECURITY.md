# Security / Responsible Use

This project concerns low-level Wi-Fi driver compatibility and monitor mode on Android.

Use it only with networks, radios, and devices you own or are explicitly authorized to test.

## Do not publish

Please do not include the following in issues, discussions, patches, screenshots, or logs:

- credentials or tokens
- private keys
- personal identifiers
- SSIDs you do not intend to disclose
- MAC/IP addresses unless intentionally sanitized
- full kernel panic dumps without reviewing unrelated data
- proprietary firmware or boot images you do not have permission to redistribute

## Kernel safety

An out-of-tree module can crash the kernel even when it compiles and loads successfully.

During bring-up:

- keep a recovery path available,
- avoid automatic module loading,
- preserve boot-critical backups,
- test with bounded operations,
- inspect persistent crash logs after every panic.

The patches in this repository address specific CFI type-safety issues observed in one RTL88x2BU driver family. They are not a guarantee of compatibility with every Android kernel or every driver snapshot.

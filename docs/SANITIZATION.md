# Sanitization Notes

This repository was prepared with eventual public release in mind.

The following data classes are intentionally excluded:

- personal names or biographical information
- hostnames and usernames
- local filesystem paths
- IP addresses
- MAC addresses
- SSIDs
- account identifiers
- authentication tokens or credentials
- private repository URLs
- boot-image backups
- device backup archives
- exact local build identifiers
- exact operating-system release details
- exact tool/package release versions from the author's machines
- raw crash dumps containing unrelated device activity
- compiled kernel modules

Examples and commands use placeholders such as:

```text
$KERNEL_SRC
$KERNEL_OUT
$DRIVER_SRC
$IFACE
```

Crash excerpts are reduced to the minimal stack frames needed to explain the technical issue.

Before making the repository public, review the entire Git history as well as the current working tree. Removing a secret from the latest commit does not remove it from earlier commits.

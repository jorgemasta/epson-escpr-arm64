# epson-escpr-arm64

Native Apple silicon build of Epson's GPL ESC/P-R CUPS driver
(`epson-inkjet-printer-escpr`), for an Epson ET-2710/2712 on macOS without
Rosetta.

- Source: Debian's orig tarball of version 1.8.8, pinned by SHA-256 in
  `.github/workflows/build.yml`
- Built on a GitHub `macos-15` (arm64) runner; the artifact holds the two
  filters, the ET-2710 PPD (filter path rewritten to `/Library/Printers/EPSON-escpr`),
  `install.sh` and `SHA256SUMS`
- `patches/0001-harden-wrapper.patch` fixes upstream bugs found in review: shell
  injection and stack overflow from job options in the wrapper's `popen()`
  command, heap overflows when page geometry changes mid-job, and a 1-byte
  cache overrun. Built with `_FORTIFY_SOURCE=2` and `-fstack-protector-strong`
- Printing only; scanning still needs Epson Scan 2

Install: download the artifact, then `sudo sh install.sh`. The queue is not
shared on the network. Uninstall: `sudo sh uninstall.sh`.

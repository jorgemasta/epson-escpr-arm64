# epson-escpr-arm64

Native Apple silicon build of Epson's GPL ESC/P-R CUPS driver
(`epson-inkjet-printer-escpr`), for an Epson ET-2710/2712 on macOS without
Rosetta.

- Source: Debian's orig tarball of version 1.8.8, pinned by SHA-256 in
  `.github/workflows/build.yml`
- Built on a GitHub `macos-15` (arm64) runner; the artifact holds the two
  filters, the ET-2710 PPD (filter path rewritten to `/Library/Printers/EPSON-escpr`),
  `install.sh` and `SHA256SUMS`
- Printing only; scanning still needs Epson Scan 2

Install: download the artifact, then `sudo sh install.sh`.

# epson-escpr-arm64

A native Apple silicon build of Epson's open source ESC/P-R printer driver,
so an **Epson EcoTank ET-2710 / ET-2711 / ET-2712 / ET-2714 / ET-2715**
prints from a Mac with an M-series chip without Rosetta.

> Not affiliated with or endorsed by Seiko Epson Corporation. "Epson" and
> "EcoTank" are trademarks of Seiko Epson Corporation.

## Why

Epson's macOS driver for these printers (v10.85) is Intel-only, so on Apple
silicon it needs Rosetta, which Apple is phasing out after macOS 27. The
printers don't support AirPrint either, even on the latest firmware. Epson
does publish its Linux driver as GPL source (`epson-inkjet-printer-escpr`),
and that driver builds natively for arm64 macOS with a few small fixes.

## What you get

- Printing over Wi-Fi or Ethernet, found by Bonjour, so it keeps working if
  the printer's IP changes
- Pages come out in reverse order, so the stack is in order when you pick it
  up, because the printer outputs face up
- The usual options in the print dialog: paper size, paper type, quality,
  colour or greyscale
- Not included: scanning, ink levels, USB connection, duplex (the ET-2710 has
  none)

## Requirements

- A Mac with Apple silicon (M1 or later), macOS 15 or later
- The printer on the same network as the Mac. Check that it shows up with:

  ```sh
  dns-sd -B _pdl-datastream._tcp
  ```

  You should see `EPSON ET-2710 Series`; press Ctrl+C to stop.

## Install

1. Download `epson-escpr-arm64.zip` from the latest
   [release](../../releases/latest).
2. Open Terminal and verify and unpack the download:

   ```sh
   cd ~/Downloads
   shasum -a 256 epson-escpr-arm64.zip   # compare with the .sha256 file in the release
   unzip epson-escpr-arm64.zip
   ```

3. Install it. It asks for your Mac password:

   ```sh
   sudo sh epson-escpr-arm64/install.sh
   ```

   The script checks the files against `SHA256SUMS`, copies the driver to
   `/Library/Printers/EPSON-escpr`, and adds a printer named
   **EPSON ET-2710 (Apple silicon)**. The printer is not shared on the
   network.

4. Print a test page from any app (Cmd+P) and choose that printer. To make it
   your default printer:

   ```sh
   lpoptions -d EPSON_ET_2710_arm64
   ```

5. Optional: if you had Epson's own driver installed, remove its printer from
   **System Settings → Printers & Scanners**.

### If your printer has a different Bonjour name

If you renamed the printer, or you have more than one, `install.sh` won't find
the default name. List what's on the network and edit the `URI=` line in
`install.sh` to match before step 3:

```sh
lpinfo -v | grep -i epson
```

## Uninstall

```sh
sudo sh epson-escpr-arm64/uninstall.sh
```

This removes the printer and `/Library/Printers/EPSON-escpr`.

## Troubleshooting

- **Nothing prints:** check that the printer is on and on the same network
  (see Requirements), then look at the queue with `lpstat -t`.
- **The job fails with "Invalid characters in print options":** an app passed
  an option the driver refuses for safety. See Security below.
- **Pages come out in the wrong order:** some apps override the default. In
  the print dialog, open **Paper Handling → Page Order**.

## How it's built

Everything is built on GitHub Actions on a macOS arm64 runner. Nothing is
compiled on your Mac. See [`.github/workflows/build.yml`](.github/workflows/build.yml).

1. Downloads Epson's `epson-inkjet-printer-escpr` 1.8.8 source and verifies
   its SHA-256. The tarball is byte-for-byte identical to Debian's and to
   Epson's own download.
2. Fixes the build for clang and macOS: adds missing prototypes, the same fix
   as Debian bug #1066460, and defines `__unix`, which the code uses to enable
   its POSIX layer.
3. Applies [`patches/0001-harden-wrapper.patch`](patches/0001-harden-wrapper.patch)
   (see Security).
4. Builds with `_FORTIFY_SOURCE=2` and `-fstack-protector-strong`, with the
   filter path set to `/Library/Printers/EPSON-escpr/filter`. The PPD's
   `cupsFilter` line is rewritten to that absolute path, because macOS keeps
   the CUPS filter directory read-only.
5. Packages the two filters, the ET-2710 PPD, the scripts and `SHA256SUMS`.
   A tagged build publishes them as a release.

The binaries are arm64 and link only against macOS's `libSystem`, `libcups`
and `libcupsimage`. They are ad-hoc signed, not notarized.

## Security

The driver was reviewed before release:

- The upstream source was checked against Epson's own download, and no known
  CVEs were found.
- The filter only turns raster pages into printer commands on standard output.
  It opens no network connections, phones nowhere, and has no ink or firmware
  logic.
- macOS runs it as the unprivileged `_lp` user inside the CUPS sandbox.

The review also found bugs in Epson's wrapper, which our patch fixes:

- **Shell injection and stack overflow from print-job options.** The wrapper
  pasted them unquoted into a `popen()` command line. Options are now
  length-checked and limited to `[A-Za-z0-9_.-]`.
- **Heap overflows when the page size changes within a job.** Such jobs are
  now rejected, and page dimensions are bounded.
- **A 1-byte buffer overrun** on jobs of three or more pages.

As an extra precaution, the printer is installed as not shared.

## License

GPL-2.0, the same as the upstream driver. See [LICENSE](LICENSE).

- Driver source: Copyright (C) Seiko Epson Corporation
- Build scripts and patches in this repository: GPL-2.0

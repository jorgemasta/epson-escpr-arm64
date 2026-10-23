# epson-escpr-arm64

A native Apple silicon (arm64) build of Epson's open source ESC/P-R CUPS
driver for the **Epson EcoTank ET-2710 series** (ET-2710, ET-2711, ET-2712,
ET-2714, ET-2715). It prints from an M1 or later Mac without Rosetta, and adds
head cleaning, nozzle checks and guided two-sided printing.

- **For you if:** your Mac has Apple silicon (M1 or later) and macOS 15 or
  later, and your ET-2710 series printer is on the same Wi-Fi or Ethernet
  network as the Mac. Epson's own macOS driver (v10.85) is Intel-only and
  needs Rosetta, which Apple is phasing out after macOS 27, and these printers
  don't support AirPrint.
- **Not for you if:** you have a different printer model (see
  [issue #1](https://github.com/jorgemasta/epson-escpr-arm64/issues/1)), an
  Intel Mac, or a USB-only connection.

> Not affiliated with or endorsed by Seiko Epson Corporation. "Epson" and
> "EcoTank" are trademarks of Seiko Epson Corporation.

## Install

With [Homebrew](https://brew.sh) (asks for your Mac password):

```sh
brew install --cask jorgemasta/tap/epson-escpr-arm64
```

Or by hand, in Terminal. The `sudo` step asks for your Mac password.

```sh
mkdir -p ~/Downloads/epson-escpr && cd ~/Downloads/epson-escpr
curl -fLO https://github.com/jorgemasta/epson-escpr-arm64/releases/latest/download/epson-escpr-arm64.zip
curl -fLO https://github.com/jorgemasta/epson-escpr-arm64/releases/latest/download/epson-escpr-arm64.zip.sha256
shasum -a 256 -c epson-escpr-arm64.zip.sha256   # expect: epson-escpr-arm64.zip: OK
unzip -o epson-escpr-arm64.zip
sudo sh epson-escpr-arm64/install.sh
```

The last line of output is `Installed queue EPSON_ET_2710_arm64`. Then print
from any app (Cmd+P) and choose **EPSON ET-2710 (Apple silicon)**.

Downloading in a browser instead: get both files from the
[latest release](https://github.com/jorgemasta/epson-escpr-arm64/releases/latest).
Safari may unzip the archive on its own and move the `.zip` to the Trash; in
that case skip the `shasum` and `unzip` lines and run
`sudo sh ~/Downloads/epson-escpr-arm64/install.sh`. The installer still checks
every file against `SHA256SUMS`.

Optional:

- Make it the default printer: `lpoptions -d EPSON_ET_2710_arm64`
- If Epson's own driver was installed, remove its printer in
  **System Settings → Printers & Scanners**.

## What install.sh does

Running `install.sh` again replaces the files and updates the queue in place.

| Item | Value |
| --- | --- |
| Integrity check | `shasum -a 256 -c SHA256SUMS` in the unpacked folder; stops on any mismatch |
| Install directory | `/Library/Printers/EPSON-escpr` (owner `root:wheel`) |
| Filters | `/Library/Printers/EPSON-escpr/filter/epson-escpr`, `epson-escpr-wrapper` and `commandtoescpr` (mode 755) |
| Tools | `/Library/Printers/EPSON-escpr/bin/epson-maint` and `epson-duplex` (mode 755), linked from `/usr/local/bin` |
| Print dialog | `/Library/PDF Services/Print Two-Sided (ET-2710)`, a link to `epson-duplex` |
| PPD | `/Library/Printers/EPSON-escpr/ppd/Epson-ET-2710_Series-epson-escpr-en.ppd` (mode 644) |
| Quarantine | removes `com.apple.quarantine` from the install directory |
| CUPS queue name | `EPSON_ET_2710_arm64` |
| Display name | `EPSON ET-2710 (Apple silicon)` |
| Device URI | `dnssd://EPSON%20ET-2710%20Series._pdl-datastream._tcp.local./` |
| Queue options | enabled, `printer-is-shared=false`, `outputorder=reverse` |

The Bonjour (`dnssd://`) URI keeps the queue working when the printer's IP
address changes. Pages print in reverse order because the printer outputs them
face up, so the stack comes out in order.

## Verify

```sh
dns-sd -B _pdl-datastream._tcp            # printer visible on the network; Ctrl+C to stop
lpstat -v EPSON_ET_2710_arm64
lpstat -p EPSON_ET_2710_arm64
lpoptions -p EPSON_ET_2710_arm64 | tr ' ' '\n' | grep -E 'printer-is-shared|outputorder'
```

Expected:

- `dns-sd` lists an instance named `EPSON ET-2710 Series`.
- `lpstat -v` prints
  `device for EPSON_ET_2710_arm64: dnssd://EPSON%20ET-2710%20Series._pdl-datastream._tcp.local./`
- `lpstat -p` prints `printer EPSON_ET_2710_arm64 is idle.  enabled since …`
- `lpoptions` shows `printer-is-shared=false` and `outputorder=reverse`.

To send a test job from the command line: `lp -d EPSON_ET_2710_arm64 <file.pdf>`.

## Maintenance

```sh
epson-maint nozzle-check   # prints the nozzle check pattern on one sheet
epson-maint clean          # cleans the print head; uses ink
```

The nozzle check prints four staircase blocks of fine lines, one per colour.
If any block has gaps, run `clean`, wait a minute, and check again. Avoid
running `clean` more than a few times in a row: each one uses ink, and Epson
recommends waiting at least 12 hours without printing if gaps remain after about three cleanings.

The same two commands are available to any CUPS client as the queue's
`PrintSelfTestPage` and `Clean` printer commands. They send the byte
sequences of Epson's `epsMakeMainteCmd()`; CI checks that they match exactly.

## Two-sided printing

The ET-2710 has no duplex unit, so `epson-duplex` prints the odd pages, asks
you to reload the stack, then prints the even pages.

- **From any app:** in the print dialog, open the **PDF** menu and choose
  **Print Two-Sided (ET-2710)**.
- **From Terminal:** `epson-duplex document.pdf`

When the fronts have come out, take the stack without reordering it and load
it into the rear tray with the printed side facing the back of the printer
and the top of the pages going in first. Click **Print Backs**. When the
backs finish, turn the whole stack over: page 1 is on top. An odd page count
leaves the last back blank.

It binds on the long edge, like a book, and uses the paper size of the first
page. To print to a queue with another name, set `EPSON_QUEUE`.

## If the printer has a different Bonjour name

`install.sh` always uses the default name `EPSON ET-2710 Series`. It does not
check that the printer is present, so with a renamed printer (or a second one
with a suffixed name) the install succeeds but jobs never reach the printer.
Find the printer's URI and point the queue at it:

```sh
lpinfo -v | grep -i epson
sudo lpadmin -p EPSON_ET_2710_arm64 -v '<dnssd URI from the line above>'
```

Do not edit `install.sh`: it is listed in `SHA256SUMS`, so the integrity
check would fail.

## Uninstall

With Homebrew: `brew uninstall --cask epson-escpr-arm64`. Otherwise:

```sh
sudo sh ~/Downloads/epson-escpr/epson-escpr-arm64/uninstall.sh
```

Or, without the downloaded folder, the same steps:

```sh
sudo lpadmin -x EPSON_ET_2710_arm64
sudo rm -f /usr/local/bin/epson-maint /usr/local/bin/epson-duplex \
  "/Library/PDF Services/Print Two-Sided (ET-2710)"
sudo rm -rf /Library/Printers/EPSON-escpr
```

Check: `lpstat -p EPSON_ET_2710_arm64` reports that the printer does not exist,
and `/Library/Printers/EPSON-escpr` is gone.

## Features and limits

- Printing over Wi-Fi or Ethernet, found by Bonjour
- Print dialog options from the PPD: paper size, paper type, quality, colour
  or greyscale
- Nozzle check and head cleaning (see Maintenance)
- Guided manual two-sided printing (see Two-sided printing)
- Not included: scanning, ink levels, USB

## Troubleshooting

- **Nothing prints:** check the printer is on and on the same network
  (`dns-sd -B _pdl-datastream._tcp`), then look at the queue with `lpstat -t`.
  If the printer has a different name, see above.
- **Job fails with "Invalid characters in print options":** an app sent a job
  option containing characters the hardened wrapper rejects (see Security).
- **Pages in the wrong order:** some apps override the default. In the print
  dialog, set **Paper Handling → Page Order**.

## How it's built

The release is built by GitHub Actions on a `macos-15` arm64 runner; nothing
is compiled on your Mac. See
[`.github/workflows/build.yml`](.github/workflows/build.yml).

1. Downloads Debian's orig tarball of Epson's `epson-inkjet-printer-escpr`
   1.8.8 and verifies it against a pinned SHA-256
   (`8a0430d9…defb`), the same hash as the `epson-inkjet-printer-escpr-1.8.8-1.tar.gz` on Epson's download center.
2. Regenerates the autotools files and applies
   [`patches/0001-harden-wrapper.patch`](patches/0001-harden-wrapper.patch).
3. Fixes the build for clang: declares functions upstream calls without
   prototypes (same issue as Debian bug #1066460) and defines `__unix`, which
   upstream uses to enable its POSIX code.
4. Builds static binaries with `_FORTIFY_SOURCE=2` and
   `-fstack-protector-strong`, with the filter directory set to
   `/Library/Printers/EPSON-escpr/filter`. The PPD's `cupsFilter` line is
   rewritten to that absolute path, because macOS's own CUPS filter directory
   is protected by SIP.
5. Checks that `filter/commandtoescpr` emits the same maintenance bytes as
   Epson's `epsMakeMainteCmd()`, using
   [`tests/mainte_ref.c`](tests/mainte_ref.c), and adds it to the PPD as the
   `application/vnd.cups-command` filter.
6. Packages the filters, the `bin/` tools, the ET-2710 PPD, `install.sh`, `uninstall.sh`,
   `SHA256SUMS` and the upstream `COPYING`. A tag starting with `v` publishes
   `epson-escpr-arm64.zip` and `epson-escpr-arm64.zip.sha256` as a release,
   with `SHA256SUMS` as the release notes.

The binaries are arm64, ad-hoc signed and not notarized.

## Security

- The filter converts CUPS raster pages into printer commands on standard
  output. macOS runs CUPS filters as the unprivileged `_lp` user in the CUPS
  sandbox.
- `commandtoescpr` accepts only the `Clean` and `PrintSelfTestPage`
  commands and rejects anything else.
- `epson-duplex` passes file names to `lp` single-quoted.
- The queue is installed as not shared, because job options reach the
  filter's command line.

`patches/0001-harden-wrapper.patch` fixes these bugs in Epson's
`epson-escpr-wrapper`:

- **Shell injection and stack overflow from print-job options.** Options were
  pasted unquoted into a `popen()` command line. They are now length-checked
  and limited to `[A-Za-z0-9_.-]` (the model name may also contain spaces),
  and an over-long command line is rejected.
- **Heap overflow when the page size grows within a job.** Such jobs are now
  rejected, and page dimensions are bounded so the size arithmetic cannot
  wrap.
- **A 1-byte buffer overrun** in the two-page cache used for jobs of three or
  more pages.

## License

GPL-2.0, the same as the upstream driver. See [LICENSE](LICENSE).

- Driver source: Copyright (C) Seiko Epson Corporation
- Build scripts and patches in this repository: GPL-2.0

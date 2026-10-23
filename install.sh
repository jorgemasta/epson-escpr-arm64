#!/bin/sh
# Install the native ESC/P-R filters and tools and add the ET-2710 as a CUPS queue. Run with sudo.
set -eu

INSTALL_DIR=/Library/Printers/EPSON-escpr
QUEUE=EPSON_ET_2710_arm64
# Bonjour URI so the queue survives the printer getting a new IP.
URI='dnssd://EPSON%20ET-2710%20Series._pdl-datastream._tcp.local./'
PPD=Epson-ET-2710_Series-epson-escpr-en.ppd
PDF_SERVICE="/Library/PDF Services/Print Two-Sided (ET-2710)"

cd "$(dirname "$0")"
# Catches corruption only; trust comes from downloading a release from the project page.
shasum -a 256 -c SHA256SUMS

install -d -o root -g wheel -m 755 "$INSTALL_DIR" "$INSTALL_DIR/filter" "$INSTALL_DIR/ppd" "$INSTALL_DIR/bin"
install -o root -g wheel -m 755 filter/epson-escpr filter/epson-escpr-wrapper filter/commandtoescpr "$INSTALL_DIR/filter/"
install -o root -g wheel -m 755 bin/epson-maint bin/epson-duplex "$INSTALL_DIR/bin/"
install -o root -g wheel -m 644 "ppd/$PPD" "$INSTALL_DIR/ppd/"
# Downloaded files may carry quarantine; CUPS would refuse to run them.
xattr -dr com.apple.quarantine "$INSTALL_DIR" 2>/dev/null || true

# Command-line tools and the print dialog's PDF menu entry.
install -d -m 755 /usr/local/bin "/Library/PDF Services"
ln -sf "$INSTALL_DIR/bin/epson-maint" /usr/local/bin/epson-maint
ln -sf "$INSTALL_DIR/bin/epson-duplex" /usr/local/bin/epson-duplex
ln -sf "$INSTALL_DIR/bin/epson-duplex" "$PDF_SERVICE"

# Not shared: job options reach the filter's command line, so keep submitters local.
lpadmin -p "$QUEUE" -E -v "$URI" -P "$INSTALL_DIR/ppd/$PPD" \
  -D 'EPSON ET-2710 (Apple silicon)' -o printer-is-shared=false -o outputorder=reverse
lpoptions -p "$QUEUE"
echo "Installed queue $QUEUE"

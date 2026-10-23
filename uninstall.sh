#!/bin/sh
# Remove the queue, filters and tools that install.sh added. Run with sudo.
set -eu

lpadmin -x EPSON_ET_2710_arm64 2>/dev/null || true
rm -f /usr/local/bin/epson-maint /usr/local/bin/epson-duplex \
  "/Library/PDF Services/Print Two-Sided (ET-2710)"
rm -rf /Library/Printers/EPSON-escpr
echo "Uninstalled"

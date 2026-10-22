#!/bin/sh
# Remove the queue and filters that install.sh added. Run with sudo.
set -eu

lpadmin -x EPSON_ET_2710_arm64 2>/dev/null || true
rm -rf /Library/Printers/EPSON-escpr
echo "Uninstalled"

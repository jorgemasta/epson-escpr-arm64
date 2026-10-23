#!/bin/sh
# Check the page order epson-duplex sends for each pass, without printing.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

# expect <pages> <expected plan line>
expect() {
	osascript -l JavaScript "$root/tests/make_pdf.js" "$1" "$tmp/$1.pdf"
	got=$(EPSON_DUPLEX_DRY_RUN=1 osascript -l JavaScript "$root/bin/epson-duplex" "$tmp/$1.pdf" 2>&1 |
		grep -E '^fronts|^Single page') || true
	if [ "$got" = "$2" ]; then
		echo "ok   $1 pages: $got"
	else
		echo "FAIL $1 pages: got '$got', want '$2'"
		fail=1
	fi
}

expect 1 'Single page, printed one side'
expect 2 'fronts 1 | backs 2'
expect 4 'fronts 1,3 | backs 2,4'
expect 5 'fronts 1,3,5 | backs 2,4,0'
exit $fail

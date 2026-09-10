#!/usr/bin/env bash
# Build HeliosPT.zip with the shaders/ folder at the archive root.
# This layout is mandatory for Oculus 1.6.4 (see INSTALL.md).
set -euo pipefail

cd "$(dirname "$0")"

if command -v zip >/dev/null 2>&1; then
    rm -f HeliosPT.zip
    zip -r HeliosPT.zip shaders
else
    # Fallback: bsdtar (ships with modern macOS / some Linux distros) can write zip.
    rm -f HeliosPT.zip
    tar -a -c -f HeliosPT.zip shaders
fi

echo "Created $(pwd)/HeliosPT.zip"
echo "Sanity check: the archive must list shaders/ at its root (no wrapper folder)."

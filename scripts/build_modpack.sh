#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════╗"
echo "║       deep.space.10 Modpack Builder          ║"
echo "║                 (DEPRECATED)                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "WARNING: This script is deprecated."
echo "Mod management is now handled via r2modman."
echo "Profile Code: 01983a2e-22a5-26ae-35a4-8858c59c0849"
echo ""
echo "Continuing with legacy build for reference..."
echo ""

VERSION=${1:-$(jq -r '.version' src/modpack/manifest.json)}

echo "Building modpack version: $VERSION"

# Run Python build script
python3 scripts/build_modpack.py "$VERSION"

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Modpack build successful!"
    echo "Files created in ./deploy/"
    ls -la ./deploy/
else
    echo "✗ Modpack build failed!"
    exit 1
fi
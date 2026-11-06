#!/bin/sh
# Downloads the official TVVLCKit (VideoLAN, LGPLv2.1) used for movies and
# series, verifies its checksum, and puts the xcframework where the local
# LabbyVLC package expects it. The binary is too big for git, so it's
# git-ignored and fetched with this script instead.
#
# Version and checksum come from VideoLAN's official TVVLCKit 3.7.4 podspec.
set -eu

VERSION="3.7.4"
URL="https://download.videolan.org/cocoapods/prod/TVVLCKit-3.0-20260930-0854.tar.xz"
SHA256="07892cae8e59e95a23f1fcf11692f802eae106312aa5ad9782faa2556b2d65d5"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Packages/LabbyVLC/Frameworks"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [ -d "$DEST/TVVLCKit.xcframework" ]; then
    echo "TVVLCKit.xcframework already present in $DEST"
    exit 0
fi

echo "Downloading TVVLCKit $VERSION (~131 MB)…"
# The VideoLAN mirror sometimes drops long downloads; resume instead of restarting.
i=0
until curl -fSL --http1.1 -C - --retry 5 --retry-all-errors -o "$TMP/TVVLCKit.tar.xz" "$URL"; do
    i=$((i + 1))
    [ "$i" -ge 6 ] && { echo "Download failed"; exit 1; }
    echo "Resuming download ($i)…"
done

echo "$SHA256  $TMP/TVVLCKit.tar.xz" | shasum -a 256 -c -
tar -xJf "$TMP/TVVLCKit.tar.xz" -C "$TMP"

FRAMEWORK="$(find "$TMP" -maxdepth 4 -name 'TVVLCKit.xcframework' -type d | head -1)"
[ -n "$FRAMEWORK" ] || { echo "TVVLCKit.xcframework not found in archive"; exit 1; }

mkdir -p "$DEST"
mv "$FRAMEWORK" "$DEST/"
COPYING="$(find "$TMP" -maxdepth 4 -name 'COPYING*' -type f | head -1)"
[ -n "$COPYING" ] && cp "$COPYING" "$DEST/TVVLCKit-LICENSE.txt"
echo "Installed $DEST/TVVLCKit.xcframework"

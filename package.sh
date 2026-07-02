#!/bin/bash
set -euo pipefail

APP_NAME="Arch Gen"
BUNDLE_DIR="$APP_NAME.app"
DIST_DIR="dist/arch-gen"
TAR_NAME="ArchGen-macos-arm64.tar.gz"

echo "Building release binary..."
cargo build --release

echo "Assembling $BUNDLE_DIR..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

cp target/release/arch-gen "$BUNDLE_DIR/Contents/MacOS/arch-gen"
cp macos/Info.plist        "$BUNDLE_DIR/Contents/Info.plist"
cp macos/AppIcon.icns      "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"

echo "Creating $TAR_NAME..."
mkdir -p "$DIST_DIR"
tar -czf "$DIST_DIR/$TAR_NAME" "$BUNDLE_DIR"

rm -rf "$BUNDLE_DIR"

echo "Done: $DIST_DIR/$TAR_NAME ($(du -h "$DIST_DIR/$TAR_NAME" | cut -f1))"

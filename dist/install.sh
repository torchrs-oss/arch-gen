#!/bin/bash
set -euo pipefail

APP_NAME="Arch Gen"
URL="https://data.torch.rs/arch-gen/ArchGen-macos-arm64.tar.gz"
INSTALL_DIR="$HOME/Applications"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading Arch Gen..."
curl -fSL "$URL" -o "$TMP_DIR/ArchGen.tar.gz"

echo "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
tar -xzf "$TMP_DIR/ArchGen.tar.gz" -C "$INSTALL_DIR"

echo "Clearing quarantine flag..."
xattr -rd com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app"

echo "Done. Opening Arch Gen..."
open "$INSTALL_DIR/$APP_NAME.app"

#!/bin/bash
set -euo pipefail

BASE_URL="https://data.torch.rs/arch-gen"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        if [ "$ARCH" != "arm64" ]; then
            echo "Error: Only Apple Silicon (arm64) is supported." >&2
            exit 1
        fi

        URL="$BASE_URL/ArchGen-macos-arm64.tar.gz"
        INSTALL_DIR="$HOME/Applications"
        APP_NAME="Arch Gen"

        echo "Downloading Arch Gen for macOS..."
        curl -fSL "$URL" -o "$TMP_DIR/ArchGen.tar.gz"

        echo "Installing to $INSTALL_DIR..."
        pkill -f "Arch Gen" 2>/dev/null || true
        mkdir -p "$INSTALL_DIR"
        rm -rf "$INSTALL_DIR/$APP_NAME.app"
        tar -xzf "$TMP_DIR/ArchGen.tar.gz" -C "$INSTALL_DIR"

        echo "Clearing quarantine flag..."
        xattr -rd com.apple.quarantine "$INSTALL_DIR/$APP_NAME.app"

        echo "Done. Opening Arch Gen..."
        open "$INSTALL_DIR/$APP_NAME.app"
        ;;

    Linux)
        if [ "$ARCH" != "x86_64" ]; then
            echo "Error: Only x86_64 is supported on Linux." >&2
            exit 1
        fi

        URL="$BASE_URL/ArchGen-linux-x86_64.tar.gz"
        INSTALL_DIR="$HOME/.local/bin"

        echo "Downloading Arch Gen for Linux..."
        curl -fSL "$URL" -o "$TMP_DIR/ArchGen.tar.gz"

        echo "Installing to $INSTALL_DIR..."
        pkill -f arch-gen 2>/dev/null || true
        mkdir -p "$INSTALL_DIR"
        tar -xzf "$TMP_DIR/ArchGen.tar.gz" -C "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/arch-gen"

        echo "Done. Run with: arch-gen"
        if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            echo "(You may need to add $INSTALL_DIR to your PATH)"
        fi
        ;;

    *)
        echo "Error: Unsupported OS '$OS'. Arch Gen supports macOS (arm64) and Linux (x86_64)." >&2
        exit 1
        ;;
esac

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
        BIN_DIR="$HOME/.local/bin"
        ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
        DESKTOP_DIR="$HOME/.local/share/applications"

        echo "Downloading Arch Gen for Linux..."
        curl -fSL "$URL" -o "$TMP_DIR/ArchGen.tar.gz"

        echo "Installing binary to $BIN_DIR..."
        pkill -f arch-gen 2>/dev/null || true
        mkdir -p "$BIN_DIR"
        tar -xzf "$TMP_DIR/ArchGen.tar.gz" -C "$TMP_DIR"
        cp "$TMP_DIR/arch-gen" "$BIN_DIR/arch-gen"
        chmod +x "$BIN_DIR/arch-gen"

        echo "Installing desktop entry and icon..."
        mkdir -p "$ICON_DIR" "$DESKTOP_DIR"
        cp "$TMP_DIR/arch-gen.svg" "$ICON_DIR/arch-gen.svg"
        sed "s|__EXEC_PATH__|$BIN_DIR/arch-gen|" "$TMP_DIR/arch-gen.desktop" > "$DESKTOP_DIR/arch-gen.desktop"

        if command -v update-desktop-database &>/dev/null; then
            update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
        fi
        if command -v gtk-update-icon-cache &>/dev/null; then
            gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
        fi

        echo "Done. Arch Gen should appear in your app launcher."
        if ! echo "$PATH" | grep -q "$BIN_DIR"; then
            echo "(You may need to add $BIN_DIR to your PATH to run from terminal)"
        fi
        ;;

    *)
        echo "Error: Unsupported OS '$OS'. Arch Gen supports macOS (arm64) and Linux (x86_64)." >&2
        exit 1
        ;;
esac

#!/bin/bash
set -euo pipefail

DIST_DIR="dist/arch-gen"
mkdir -p "$DIST_DIR"

package_macos() {
    local APP_NAME="Arch Gen"
    local BUNDLE_DIR="$APP_NAME.app"
    local TAR_NAME="ArchGen-macos-arm64.tar.gz"

    echo "=== macOS (arm64) ==="
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
    tar -czf "$DIST_DIR/$TAR_NAME" "$BUNDLE_DIR"
    rm -rf "$BUNDLE_DIR"

    echo "Done: $DIST_DIR/$TAR_NAME ($(du -h "$DIST_DIR/$TAR_NAME" | cut -f1))"
}

package_linux() {
    local TAR_NAME="ArchGen-linux-x86_64.tar.gz"

    echo "=== Linux (x86_64) ==="
    echo "Building in Docker..."
    docker build --platform linux/amd64 -f Dockerfile.linux -t arch-gen-linux .

    local TMP_DIR
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' RETURN

    docker run --platform linux/amd64 --rm -v "$TMP_DIR:/output" arch-gen-linux

    cp linux/rs.torch.arch-gen.desktop "$TMP_DIR/"
    cp linux/arch-gen.svg "$TMP_DIR/"

    echo "Creating $TAR_NAME..."
    tar -czf "$DIST_DIR/$TAR_NAME" -C "$TMP_DIR" arch-gen rs.torch.arch-gen.desktop arch-gen.svg

    echo "Done: $DIST_DIR/$TAR_NAME ($(du -h "$DIST_DIR/$TAR_NAME" | cut -f1))"
}

case "${1:-all}" in
    macos)  package_macos ;;
    linux)  package_linux ;;
    all)    package_macos; package_linux ;;
    *)      echo "Usage: $0 [macos|linux|all]"; exit 1 ;;
esac

cp install.sh "$DIST_DIR/install.sh"
cp dist/arch-gen/index.html "$DIST_DIR/index.html" 2>/dev/null || true
echo "Synced install.sh → $DIST_DIR/"

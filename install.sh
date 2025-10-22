#!/usr/bin/env bash
#
# claude-tools installer script
# Usage: curl -sSL https://raw.githubusercontent.com/dlond/claude-tools/main/install.sh | bash

set -e

REPO="dlond/claude-tools"
INSTALL_DIR="${CLAUDE_TOOLS_INSTALL_DIR:-/usr/local/bin}"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="darwin" ;;
    *)          echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
    x86_64)     ARCH="x86_64" ;;
    arm64|aarch64)
        if [ "$PLATFORM" = "darwin" ]; then
            ARCH="aarch64"
        else
            echo "ARM Linux not yet supported"; exit 1
        fi
        ;;
    *)          echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TARGET="${ARCH}-${PLATFORM}"

echo "Installing claude-tools for $TARGET..."

# Get latest release
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_RELEASE" ]; then
    echo "Error: Could not determine latest release"
    exit 1
fi

# Download and extract
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST_RELEASE/claude-tools-${TARGET}.tar.gz"
TEMP_DIR="$(mktemp -d)"

echo "Downloading from $DOWNLOAD_URL..."
curl -L "$DOWNLOAD_URL" | tar xz -C "$TEMP_DIR"

# Install binaries
echo "Installing to $INSTALL_DIR..."
for tool in claude-ls claude-cp claude-mv claude-rm claude-clean; do
    if [ -f "$TEMP_DIR/$tool" ]; then
        if [ -w "$INSTALL_DIR" ]; then
            cp "$TEMP_DIR/$tool" "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/$tool"
        else
            echo "Need sudo access to install to $INSTALL_DIR"
            sudo cp "$TEMP_DIR/$tool" "$INSTALL_DIR/"
            sudo chmod +x "$INSTALL_DIR/$tool"
        fi
    fi
done

# Clean up
rm -rf "$TEMP_DIR"

echo "✅ claude-tools installed successfully!"
echo ""
echo "Test installation with:"
echo "  claude-ls --help"
echo ""
echo "For shell completions, see: https://github.com/$REPO#shell-completions"
#!/usr/bin/env bash
#
# Build release binaries for claude-tools
# This creates more portable binaries by statically linking OCaml runtime

set -e

echo "Building release binaries..."

# Build with dune in release mode
dune build --release

# Create dist directory
mkdir -p dist

# Copy binaries
for exe in _build/default/bin/*.exe; do
    name=$(basename "$exe" .exe)
    cp "$exe" "dist/$name"
    chmod +x "dist/$name"
    echo "✓ Built $name"
done

# Copy completions
mkdir -p dist/completions
cp completions/* dist/completions/

# Get platform name
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="darwin" ;;
    *)          PLATFORM="unknown" ;;
esac

case "$ARCH" in
    x86_64)     ARCH="x86_64" ;;
    arm64|aarch64) ARCH="aarch64" ;;
    *)          ARCH="unknown" ;;
esac

TARGET="${ARCH}-${PLATFORM}"

# Create tarball
echo "Creating tarball..."
tar czf "claude-tools-${TARGET}.tar.gz" -C dist .

echo ""
echo "✅ Release binary created: claude-tools-${TARGET}.tar.gz"
echo ""
echo "Contents:"
tar tzf "claude-tools-${TARGET}.tar.gz" | head -10

# Show binary info
echo ""
echo "Binary info:"
file dist/claude-ls
ldd dist/claude-ls 2>/dev/null || otool -L dist/claude-ls 2>/dev/null || true
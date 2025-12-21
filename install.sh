#!/bin/sh
set -e

REPO="clawscli/claws"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${VERSION:-}"

# Check dependencies
for cmd in curl tar mktemp; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: $cmd is required but not found" >&2
    exit 1
  fi
done

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
  linux|darwin) ;;
  *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# Get latest version if not specified
if [ -z "$VERSION" ]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
  if [ -z "$VERSION" ]; then
    echo "Failed to get latest version. Check network or GitHub API rate limit." >&2
    exit 1
  fi
fi

echo "Installing claws $VERSION for $OS/$ARCH..."

# Create temp directory (use template for BSD/macOS compatibility)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/claws.XXXXXX")
trap "rm -rf '$TMP'" EXIT

# Download binary and checksums
TARBALL="claws-${OS}-${ARCH}.tar.gz"
curl -fsSL "https://github.com/$REPO/releases/download/${VERSION}/${TARBALL}" -o "$TMP/$TARBALL"
curl -fsSL "https://github.com/$REPO/releases/download/${VERSION}/checksums.txt" -o "$TMP/checksums.txt"

# Verify checksum
cd "$TMP"
CHECKSUM_LINE=$(grep -F "$TARBALL" checksums.txt || true)
if [ -z "$CHECKSUM_LINE" ]; then
  echo "Error: checksum not found for $TARBALL" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  printf '%s\n' "$CHECKSUM_LINE" | sha256sum -c - >/dev/null
elif command -v shasum >/dev/null 2>&1; then
  printf '%s\n' "$CHECKSUM_LINE" | shasum -a 256 -c - >/dev/null
else
  echo "Warning: sha256sum/shasum not found, skipping checksum verification" >&2
fi

# Extract and install
tar xzf "$TARBALL"
mkdir -p "$INSTALL_DIR"
mv claws "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/claws"

echo "claws $VERSION installed to $INSTALL_DIR/claws"

# PATH warning
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "Warning: $INSTALL_DIR is not in your PATH. Add it to your shell config." ;;
esac

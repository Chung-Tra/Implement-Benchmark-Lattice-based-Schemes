#!/usr/bin/env bash
# =============================================================================
# cross_build_liboqs.sh - Cross-compile liboqs for aarch64 on an x86_64 host.
# Satisfies brief 7.3 alternative: "separate cross-compile scripts
# (aarch64-linux-gnu toolchain)". Follows the liboqs wiki example, which
# passes a CMake toolchain file and sets -DOQS_USE_OPENSSL=OFF for cross
# builds (no target-arch OpenSSL needed on the host).
# Output: $PQC_ROOT/liboqs-aarch64-cross  (copy to the ARM box to run).
# =============================================================================
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
source "$HERE/versions.env"

command -v aarch64-linux-gnu-gcc >/dev/null \
  || { echo "Missing cross compiler: sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu"; exit 1; }

# Download EXACTLY the pinned release (same convention as build_liboqs.sh).
mkdir -p "$SRC_ROOT"; cd "$SRC_ROOT"
[ -d liboqs ] \
  || git clone --depth 1 --branch "$LIBOQS_TAG" https://github.com/open-quantum-safe/liboqs.git
cd liboqs

cmake -GNinja -S . -B build-aarch64-cross \
  -DCMAKE_TOOLCHAIN_FILE="$REPO_ROOT/cmake/aarch64-toolchain.cmake" \
  -DCMAKE_INSTALL_PREFIX="$PQC_ROOT/liboqs-aarch64-cross" \
  -DBUILD_SHARED_LIBS=ON \
  -DOQS_DIST_BUILD=OFF -DOQS_OPT_TARGET=generic \
  -DOQS_USE_OPENSSL=OFF
ninja -C build-aarch64-cross
ninja -C build-aarch64-cross install
file "$PQC_ROOT/liboqs-aarch64-cross/lib/liboqs.so"* | head -2
echo "DONE: aarch64 binaries (verify above says 'ARM aarch64'). Copy to the ARM box."
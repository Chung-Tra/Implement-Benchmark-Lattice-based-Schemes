#!/usr/bin/env bash
# =============================================================================
# setenv.sh - Activate the custom OpenSSL (with PQC) for the CURRENT shell.
# Follows the official OpenSSL demos convention: libraries are found at run
# time via LD_LIBRARY_PATH (no rpath baked into binaries).
#
# IMPORTANT: source it, do NOT execute it:
#     source scripts/setenv.sh
# =============================================================================
_SETENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_SETENV_DIR/versions.env"
 
export PATH="$OSSL_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$OSSL_PREFIX/lib:$OSSL_PREFIX/lib64:${LD_LIBRARY_PATH:-}"
 
echo "Activated OpenSSL from: $OSSL_PREFIX"
"$OSSL_PREFIX/bin/openssl" version 2>/dev/null \
  || echo "(openssl not built yet at $OSSL_PREFIX - run scripts/build_openssl.sh)"
 

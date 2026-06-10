#!/usr/bin/env bash
# =============================================================================
# install_prereqs.sh - Install build + measurement tools (Ubuntu/Debian).
# The ONLY script that needs sudo. Tool list follows brief 8.2:
#   Build : CMake, GCC/Clang, pkg-config, Python, Docker(optional)
#   Measure: time, perf stat, wrk/ab, htop  (+ tshark for WP4 bytes-on-wire)
#   Data  : python pandas/matplotlib (processing & plotting)
# =============================================================================
set -eu
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

# --- Core build toolchain (required) -----------------------------------------
sudo apt-get install -y --no-install-recommends \
  build-essential git perl pkg-config cmake ninja-build \
  python3 python3-pip ca-certificates

# --- Measurement tools (brief 8.2; not fatal if a package is unavailable) ----
# linux-tools-$(uname -r): perf needs the package matching the RUNNING kernel;
# on cloud kernels (-aws/-oracle) linux-tools-generic alone is not enough.
sudo apt-get install -y --no-install-recommends \
  time htop apache2-utils wrk tshark \
  linux-tools-common linux-tools-generic "linux-tools-$(uname -r)" \
  || echo "WARNING: some measurement tools failed (install later as needed)."

# --- Data processing & plotting (brief 16: python/pandas/matplotlib) ---------
sudo apt-get install -y --no-install-recommends \
  python3-pandas python3-matplotlib \
  || echo "WARNING: pandas/matplotlib via apt failed (try: pip3 install pandas matplotlib)."

# --- OPTIONAL: cross toolchain for aarch64 (only if cross-compiling, WP3) ----
# sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

echo "Prerequisites installed."

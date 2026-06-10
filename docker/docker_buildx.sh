#!/usr/bin/env bash
# =============================================================================
# docker_buildx.sh - Build the reproducible image for BOTH amd64 and arm64
# with docker buildx (brief 7.3: "docker buildx multiarch").
# Docs: https://docs.docker.com/build/building/multi-platform/
# Note: cross-arch emulation may need: docker run --privileged --rm tonistiigi/binfmt --install all
# =============================================================================
set -eu
docker buildx create --name nt219builder --use 2>/dev/null || docker buildx use nt219builder
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f docker/Dockerfile.x86_64 \
  -t nt219-pqc:multi \
  --load .

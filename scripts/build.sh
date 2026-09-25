#!/bin/bash
# Build CraneBW/ninfer-ternary-bonsai-ada for RTX 5060 Ti (sm_120a, 36 SMs).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Deployed layout: git clone under /f/ninfer-Bonsai-2-5060/ninfer-Bonsai-2-5060,
# with repo/ + build/ as siblings under /f/ninfer-Bonsai-2-5060/.
if [[ -z "${REPO:-}" ]]; then
  if [[ -d "$ROOT/repo/.git" ]]; then
    REPO="$ROOT/repo"
  elif [[ -d "$ROOT/../repo/.git" ]]; then
    REPO="$(cd "$ROOT/../repo" && pwd)"
  else
    REPO="$ROOT/repo"
  fi
fi
if [[ -z "${BUILD:-}" ]]; then
  if [[ -d "$ROOT/build/apps" ]]; then
    BUILD="$ROOT/build"
  elif [[ -d "$ROOT/../build/apps" ]]; then
    BUILD="$(cd "$ROOT/../build" && pwd)"
  else
    BUILD="$ROOT/build"
  fi
fi
PATCH="$ROOT/patches/rtx5060ti-sm120a.patch"

export PATH=/usr/local/cuda/bin:${PATH:-}

if [[ ! -d "$REPO/.git" ]]; then
  echo "=== clone CraneBW/ninfer-ternary-bonsai-ada ==="
  git clone --depth 1 https://github.com/CraneBW/ninfer-ternary-bonsai-ada.git "$REPO"
fi

cd "$REPO"
if ! grep -q 'NINFER_SM120' src/core/device.h 2>/dev/null; then
  echo "=== apply $PATCH ==="
  git apply --whitespace=nowarn "$PATCH" || patch -p1 < "$PATCH"
fi

echo "=== configure (sm_120a) ==="
cmake -S "$REPO" -B "$BUILD" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_ARCHITECTURES=120a \
  -DCMAKE_CUDA_COMPILER="$(command -v nvcc)"

echo "=== build ==="
cmake --build "$BUILD" --config Release -j"$(nproc)"
ls -lah "$BUILD/apps/ninfer" "$BUILD/apps/ninfer-serve" "$BUILD/apps/ninfer-perplexity"
echo BUILD_OK

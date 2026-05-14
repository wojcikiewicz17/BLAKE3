#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/ci.yml"
BUILD_DIR="$ROOT_DIR/c/build"

SIMD_MATRIX=("x86-intrinsics" "amd64-asm")
TBB_MATRIX=("OFF" "ON")
if [[ "${1:-}" != "--full" ]]; then
  SIMD_MATRIX=("x86-intrinsics")
  TBB_MATRIX=("OFF")
fi

if ! command -v cmake >/dev/null; then
  echo "cmake não encontrado" >&2
  exit 1
fi
if ! command -v ninja >/dev/null; then
  echo "ninja não encontrado" >&2
  exit 1
fi

run_case() {
  local label="$1"
  shift
  echo "[RUN] $label"
  cmake --fresh -S "$ROOT_DIR/c" -B "$BUILD_DIR" -G Ninja "$@"
  cmake --build "$BUILD_DIR" --target test
  ctest --test-dir "$BUILD_DIR" --output-on-failure
}

printf "## Fonte de verdade (workflow)\n"
awk '/cmake_c_tests:/{flag=1} flag{print} /pkg_config_c_tests:/{exit}' "$WORKFLOW_FILE"

printf "\n## Execução local\n"
for simd in "${SIMD_MATRIX[@]}"; do
  run_case "SIMD=$simd baseline" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_SIMD_TYPE=$simd"
  run_case "SIMD=$simd NO_SSE2" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_SIMD_TYPE=$simd" -DBLAKE3_NO_SSE2=1
  run_case "SIMD=$simd NO_SSE2/NO_SSE41" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_SIMD_TYPE=$simd" -DBLAKE3_NO_SSE2=1 -DBLAKE3_NO_SSE41=1
  run_case "SIMD=$simd NO_SSE2/NO_SSE41/NO_AVX2" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_SIMD_TYPE=$simd" -DBLAKE3_NO_SSE2=1 -DBLAKE3_NO_SSE41=1 -DBLAKE3_NO_AVX2=1
  run_case "SIMD=$simd NO_SSE2/NO_SSE41/NO_AVX2/NO_AVX512" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_SIMD_TYPE=$simd" -DBLAKE3_NO_SSE2=1 -DBLAKE3_NO_SSE41=1 -DBLAKE3_NO_AVX2=1 -DBLAKE3_NO_AVX512=1
done

for tbb in "${TBB_MATRIX[@]}"; do
  run_case "TBB=$tbb" -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON "-DBLAKE3_USE_TBB=$tbb"
  echo "[RUN] EXAMPLE TBB=$tbb"
  cmake --fresh -S "$ROOT_DIR/c" -B "$BUILD_DIR" -G Ninja -DBLAKE3_TESTING=ON -DBLAKE3_TESTING_CI=ON -DBLAKE3_EXAMPLES=ON "-DBLAKE3_USE_TBB=$tbb"
  cmake --build "$BUILD_DIR" --target blake3-example
done

echo "Concluído. Para matriz completa use: tools/cmake_ci_compare.sh --full"

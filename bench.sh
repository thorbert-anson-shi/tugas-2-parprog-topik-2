#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <matrix_size> <num_iterations>"
  exit 1
fi

N="$1"
ITERS="$2"

BUILD_DIR="build"

run_bench() {
  local bin="$1"
  local label="$2"
  local trimmed

  trimmed=$("$BUILD_DIR/$bin" <<< "$ITERS
$N" 2>&1 | grep 'trimmed:' | awk '{print $2}')

  echo "$label $trimmed"
}

echo "=== Matmul Communication/Computation Breakdown ==="
echo "Matrix: ${N}x${N}  Iterations: ${ITERS}"
echo ""

printf "%-20s %12s %12s %12s\n" "Variant" "Total (ms)" "Comm (ms)" "Comp (ms)"
printf "%-20s %12s %12s %12s\n" "--------" "----------" "----------" "----------"

variants=("naive" "tiled" "sequential" "cublas")

for v in "${variants[@]}"; do
  read -r _ total <<< $(run_bench "matmul-${v}" "$v")
  read -r _ comm  <<< $(run_bench "matmul-${v}-comm" "$v-comm")
  comp=$(echo "$total - $comm" | bc -l)

  printf "%-20s %12.6f %12.6f %12.6f\n" "$v" "$total" "$comm" "$comp"
done

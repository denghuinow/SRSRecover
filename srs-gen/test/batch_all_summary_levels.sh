#!/usr/bin/env bash
# 依次执行 ultra_short、short、balanced、detailed 的生成+评估+统计
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "===== 1/4 ultra_short ====="
bash ultra_short.sh

echo "===== 2/4 short ====="
bash short.sh

echo "===== 3/4 balanced ====="
bash balanced.sh

echo "===== 4/4 detailed ====="
bash detailed.sh

echo "===== 全部完成 ====="

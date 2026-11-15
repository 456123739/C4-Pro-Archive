#!/usr/bin/env bash
# C4 Pro Archive — 快照恢复脚本
# 用法：
#   ./restore.sh              下载 + 校验 + 解压
#   ./restore.sh --check      只校验已有文件
#   ./restore.sh --no-world   不下载/解压测试存档
set -euo pipefail

REPO="${REPO:-456123739/C4-Pro-Archive}"
TAG="${TAG:-env-2026.11}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DL="$ROOT/downloads"
CHECK_ONLY=0
WITH_WORLD=1

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --no-world) WITH_WORLD=0 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) echo "未知参数: $arg" >&2; exit 2 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "缺少依赖: $1" >&2; exit 1; }; }
need curl
command -v zstd >/dev/null 2>&1 || echo "提示：解压 .tar.zst 需要 zstd（apt install zstd）" >&2
command -v sha256sum >/dev/null 2>&1 || { echo "缺少依赖: sha256sum" >&2; exit 1; }

download() {
  local name="$1"
  mkdir -p "$DL"
  if [[ -f "$DL/$name" ]]; then
    echo "[skip] 已存在 $name"
    return
  fi
  local url="https://github.com/$REPO/releases/download/$TAG/$name"
  echo "[get ] $name"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh release download "$TAG" -R "$REPO" -p "$name" -D "$DL" --clobber
  else
    curl -fL --retry 3 --connect-timeout 20 -o "$DL/$name" "$url"
  fi
}

verify_all() {
  echo "[chk ] SHA256SUMS.txt"
  ( cd "$ROOT" && sha256sum -c --quiet SHA256SUMS.txt )
  echo "[ok  ] 校验通过"
}

main() {
  verify_all || { echo "校验失败：快照可能损坏" >&2; exit 1; }
  [[ $CHECK_ONLY -eq 1 ]] && exit 0

  download server-runtime.tar.zst
  if [[ $WITH_WORLD -eq 1 ]]; then
    download c4pro-test-world-1.7.5.tar.zst
  fi

  echo "[x   ] server-runtime.tar.zst"
  mkdir -p "$ROOT/server-runtime"
  tar -I zstd -xf "$DL/server-runtime.tar.zst" -C "$ROOT/server-runtime"

  if [[ $WITH_WORLD -eq 1 && -f "$DL/c4pro-test-world-1.7.5.tar.zst" ]]; then
    echo "[x   ] c4pro-test-world-1.7.5.tar.zst"
    tar -I zstd -xf "$DL/c4pro-test-world-1.7.5.tar.zst" -C "$ROOT/server-runtime"
  fi

  cat <<'EOF'

完成。启动自检：

  cd server-runtime
  java -Dqis4c4.selftest=true -Xmx2G @user_jvm_args.txt \
       @libraries/net/minecraftforge/forge/1.20.1-47.4.16/unix_args.txt nogui

需要 JDK 17（Temurin 17.0.20.1+1 / Gradle 8.8 的确切来源见 README 第 3 节）。
EOF
}

main

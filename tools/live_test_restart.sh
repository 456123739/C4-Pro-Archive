#!/bin/bash
# 真实服务器重启测试：远处区块里的 C4 在重启后能否被 /c4clear 清掉
set -u
SRV=/home/admin/c4/server-test
cd "$SRV" || exit 1

run_server() {
  local log=$1 tag=$2
  shift 2
  rm -f /tmp/c4live2.fifo
  mkfifo /tmp/c4live2.fifo
  exec 9<>/tmp/c4live2.fifo
  /home/admin/c4/tools/jdk/bin/java -Xmx2048M @user_jvm_args.txt \
    @libraries/net/minecraftforge/forge/1.20.1-47.4.16/unix_args.txt nogui \
    < /tmp/c4live2.fifo > "$log" 2>&1 &
  JPID=$!
  for _ in $(seq 1 180); do
    grep -q 'Done (' "$log" && break
    sleep 1
  done
  grep -q 'Done (' "$log" || { echo "[$tag] SERVER DID NOT START"; exit 1; }
  echo "[$tag] server ready"
  for cmd in "$@"; do printf '%s\n' "$cmd" >&9; sleep 2; done
  printf 'stop\n' >&9
  for _ in $(seq 1 90); do kill -0 $JPID 2>/dev/null || break; sleep 1; done
  exec 9>&-
  kill -9 $JPID 2>/dev/null
  rm -f /tmp/c4live2.fifo
}

echo "=== phase A: summon a far C4 and save the world ==="
run_server /home/admin/c4/live-171-restart-a.log A \
  'summon qis4c4:c4 600 100 600 {TicksLeft:800}' \
  'scoreboard players get c4_condition'

echo "=== phase B: restart, clear immediately ==="
run_server /home/admin/c4/live-171-restart-b.log B \
  'c4clear' \
  'execute if entity @e[type=qis4c4:c4]' \
  'scoreboard players get c4_condition'
echo "[live] restart test done"

#!/bin/bash
# 真实服务器实机测试：/kill 与 /c4clear 是否真的能删掉 C4
set -u
SRV=/home/admin/c4/server-test
LOG=/home/admin/c4/live-171.log
FIFO=/tmp/c4live.fifo

cd "$SRV" || exit 1
rm -f "$LOG" /tmp/c4live.fifo
mkfifo /tmp/c4live.fifo

# 保持 FIFO 打开，避免服务器读到 EOF
exec 9<>/tmp/c4live.fifo

/home/admin/c4/tools/jdk/bin/java -Xmx2048M @user_jvm_args.txt \
  @libraries/net/minecraftforge/forge/1.20.1-47.4.16/unix_args.txt nogui \
  < /tmp/c4live.fifo > "$LOG" 2>&1 &

JPID=$!
say() { printf '%s\n' "$1" >&9; }

for _ in $(seq 1 180); do
  grep -q 'Done (' "$LOG" && break
  sleep 1
done
grep -q 'Done (' "$LOG" || { echo "SERVER DID NOT START"; kill $JPID; exit 1; }
echo "[live] server ready"

say 'gamerule sendCommandFeedback true'
say 'summon qis4c4:c4 8 -60 8 {TicksLeft:600}'
sleep 3
say 'execute if entity @e[type=qis4c4:c4,x=8,y=-60,z=8,distance=..4]'
sleep 1
echo "[live] --- kill test ---"
say 'kill @e[type=qis4c4:c4,x=8,y=-60,z=8,distance=..4]'
sleep 2
say 'execute if entity @e[type=qis4c4:c4,x=8,y=-60,z=8,distance=..4]'
sleep 1
say 'scoreboard players get c4_condition'
sleep 1

echo "[live] --- c4clear test ---"
say 'summon qis4c4:c4 8 -60 20 {TicksLeft:600}'
sleep 2
say 'summon qis4c4:c4 8 -60 28 {TicksLeft:600}'
sleep 2
say 'c4clear'
sleep 2
say 'execute if entity @e[type=qis4c4:c4]'
sleep 1
say 'scoreboard players get c4_condition'
sleep 1

echo "[live] --- stop ---"
say 'stop'
for _ in $(seq 1 60); do
  kill -0 $JPID 2>/dev/null || break
  sleep 1
done
exec 9>&-
kill -9 $JPID 2>/dev/null
rm -f /tmp/c4live.fifo
echo "[live] done"

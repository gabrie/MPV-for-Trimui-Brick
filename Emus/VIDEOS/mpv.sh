#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"
export LD_LIBRARY_PATH="/mnt/SDCARD/System/lib:/usr/trimui/lib:/lib:/lib64:/usr/lib:$LD_LIBRARY_PATH"

progdir=$(dirname "$0")
extension="${@##*.}"

cd "$progdir"

# 处理 .launch 脚本 (例如 "🔄 刷新 NAS 列表.launch")
if [ "$extension" = "launch" ]; then
  sh "$1"
  exit
fi

# 处理 7z 补丁包
if [ "$extension" = "7z" ]; then
  /mnt/SDCARD/System/bin/7zz x -aoa "$1" -o/mnt/SDCARD/
  if [ -x "/mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh" ]; then
    /mnt/SDCARD/System/usr/trimui/scripts/reset_list.sh "VIDEOS"
  fi
  sync
  exit
fi

# 启动按键映射与后台守护
if [ -f "/usr/lib/gamecontrollerdb.txt" ]; then
  cat "/usr/lib/gamecontrollerdb.txt" "$progdir/gamecontrollerdb.txt" > /tmp/gamecontrollerdb.txt 2>/dev/null
  export SDL_GAMECONTROLLERCONFIG_FILE="/tmp/gamecontrollerdb.txt"
else
  export SDL_GAMECONTROLLERCONFIG_FILE="$progdir/gamecontrollerdb.txt"
fi

"$progdir/gptokeyb2" -1 "mpv" -c "$progdir/keys.gptk" > "$progdir/gptokeyb2.log" 2>&1 &
sleep 0.4
if [ -f "thd.conf" ] && [ -e "/dev/input/event3" ]; then
  /mnt/SDCARD/System/bin/thd --triggers thd.conf /dev/input/event3 &
fi

echo 1 > /tmp/stay_awake

# 启动 mpv 播放器 (启用网络流媒体缓冲优化)
HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$@" \
  --fullscreen \
  --audio-buffer=1 \
  --cache=yes \
  --demuxer-max-bytes=100M \
  --demuxer-readahead-secs=15 \
  --terminal=no

rm -f /tmp/stay_awake
kill -9 $(pidof gptokeyb2) 2>/dev/null
kill -9 $(pidof thd) 2>/dev/null
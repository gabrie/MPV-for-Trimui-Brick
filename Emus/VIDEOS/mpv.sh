#!/bin/sh

PATH="/mnt/SDCARD/System/bin:$PATH"
progdir=$(dirname "$0")
extension="${@##*.}"

cd "$progdir"

# 处理 .launch 脚本 (例如 "刷新 NAS 列表.launch")
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

# 确保动态库搜索路径包含本目录及系统库 (使 gptokeyb2 能够加载 libinterpose.aarch64.so)
export LD_LIBRARY_PATH="$progdir:/mnt/SDCARD/System/lib:/usr/trimui/lib:/lib:/lib64:/usr/lib:$LD_LIBRARY_PATH"

# 启动按键映射守护进程
if [ -f "/usr/lib/gamecontrollerdb.txt" ]; then
  cat "/usr/lib/gamecontrollerdb.txt" "$progdir/gamecontrollerdb.txt" > /tmp/gamecontrollerdb.txt 2>/dev/null
  export SDL_GAMECONTROLLERCONFIG_FILE="/tmp/gamecontrollerdb.txt"
else
  export SDL_GAMECONTROLLERCONFIG_FILE="$progdir/gamecontrollerdb.txt"
fi

"$progdir/gptokeyb2" -1 "mpv" -c "$progdir/keys.gptk" > "$progdir/gptokeyb2.log" 2>&1 &
sleep 0.4

# 后台启动 thd 物理硬件事件监听 (MENU 长按安全退出机制)
if [ -f "$progdir/thd.conf" ]; then
  if [ -e "/dev/input/event3" ]; then
    /mnt/SDCARD/System/bin/thd --triggers "$progdir/thd.conf" /dev/input/event3 &
  else
    /mnt/SDCARD/System/bin/thd --triggers "$progdir/thd.conf" /dev/input/event* &
  fi
fi

echo 1 > /tmp/stay_awake

# 启动 mpv 播放器 (启用流媒体网络缓冲优化)
target_file="$1"
target_dir=$(dirname "$target_file")

# 自动将同目录下所有视频加入播放列表，使 L2 / R2 能够切换上一集 / 下一集
playlist_args=""
if [ -d "$target_dir" ]; then
  playlist_args="--playlist-start=$target_file"
  # 遍历同目录下所有受支持的媒体文件构建播放列表
  set -- "$target_dir"/*
fi

HOME="$progdir" /mnt/SDCARD/System/bin/mpv $playlist_args "$@" \
  --fullscreen \
  --audio-buffer=1 \
  --cache=yes \
  --demuxer-max-bytes=100M \
  --demuxer-readahead-secs=15 \
  --terminal=no

rm -f /tmp/stay_awake
kill -9 $(pidof gptokeyb2) 2>/dev/null
kill -9 $(pidof thd) 2>/dev/null

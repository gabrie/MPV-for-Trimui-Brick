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

# 查找同目录下前一个/后一个有效视频文件 (支持 R2/L2 切集)
find_sibling() {
  action="$1"
  file="$2"
  dir=$(dirname "$file")
  
  prev=""
  match_next=0
  target=""
  
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.mp4|*.mkv|*.avi|*.mpg|*.mpeg|*.wmv|*.asf|*.rm|*.rmvb|*.m4v|*.ts|*.m3u|*.m3u8|*.flv) ;;
      *) continue ;;
    esac
    
    if [ "$action" = "next" ]; then
      if [ "$match_next" -eq 1 ]; then
        target="$f"
        break
      fi
      if [ "$f" = "$file" ]; then
        match_next=1
      fi
    elif [ "$action" = "prev" ]; then
      if [ "$f" = "$file" ]; then
        target="$prev"
        break
      fi
      prev="$f"
    fi
  done
  echo "$target"
}

# 循环播放控制器：
# 正常退出 / 主动退出 (code 0 或非切集 code) -> 结束脚本返回系统界面
# L2 触发 quit 41 -> 切到上一集
# R2 触发 quit 42 -> 切到下一集
current_video="$1"
while [ -n "$current_video" ] && [ -f "$current_video" ]; do
  HOME="$progdir" /mnt/SDCARD/System/bin/mpv "$current_video"     --fullscreen     --audio-buffer=1     --cache=yes     --demuxer-max-bytes=100M     --demuxer-readahead-secs=15     --terminal=no
  ret=$?
  
  if [ "$ret" -eq 41 ]; then
    # L2: 上一个视频
    sibling=$(find_sibling prev "$current_video")
    if [ -n "$sibling" ]; then
      current_video="$sibling"
    else
      # 已经是第一集，不再循环，退出返回系统界面
      break
    fi
  elif [ "$ret" -eq 42 ]; then
    # R2: 下一个视频
    sibling=$(find_sibling next "$current_video")
    if [ -n "$sibling" ]; then
      current_video="$sibling"
    else
      # 已经是最后一集，退出返回系统界面
      break
    fi
  else
    # 正常播放完毕或用户主动按键 (q, MENU 长按, 摇杆下压) 退出
    break
  fi
done

rm -f /tmp/stay_awake
kill -9 $(pidof gptokeyb2) 2>/dev/null
kill -9 $(pidof thd) 2>/dev/null

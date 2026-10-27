# TrimUI Brick 原装系统 mpv 移植真机验收协议 (TEST.md)

本协议用于在 TrimUI Brick 真机（官方原装系统）上验证 mpv 播放器包的运行状态与硬件兼容性。
**请用户在实际机器上逐项执行测试，并将终端原文或实际观察结果如实回填至最后一列。**

> **测试准备**：
> 1. TrimUI Brick 开机并在「设置」中开启 **SSH** 服务（原装固件 v1.1.1+ 自带，账号：`root`，默认密码：`tina`）。
> 2. 电脑连接至同一局域网，通过终端 SSH 登录至设备：`ssh root@<设备IP>`。

---

## 真机验收协议表

| # | 测试动作 / 执行命令 | 期望结果 | 不符时排查指引 | 实际测试输出 / 结果记录（请回填） |
| :---: | :--- | :--- | :--- | :--- |
| **1** | SSH 终端执行：<br>`/mnt/SDCARD/System/bin/mpv --version` | 成功打印 mpv 版本信息（应为 `mpv 0.32.0`）。 | 若报 `error while loading shared libraries: xxx`，记录缺少的 `.so` 原名，从 CrossMix 的 `System/lib/` 或 PortMaster 的 `libs/` 补入 `mpv-stock/System/lib/`。 | <!-- [待回填] 粘贴终端打印的版本或报错信息 --> |
| **2** | SSH 终端执行：<br>`LD_LIBRARY_PATH=/mnt/SDCARD/System/lib ldd /mnt/SDCARD/System/bin/mpv` | 打印出所有动态库依赖，**没有任何一行包含 `not found`**。 | 若有 `not found`，记录缺库名称，回写进 `INSTALL.md` 补丁清单并在包内补充相应库文件。 | <!-- [待回填] 粘贴 ldd 输出或确认无 not found --> |
| **3** | 从掌机 MainUI 的「视频」分类中点击播放一个小的本地 H.264 mp4 视频 | 正常全屏显示画面、音频正常播放，画面不卡顿、无花屏。 | 若黑屏或无声：在 SSH 中手动运行带日志的命令并将输出重定向为 `log.txt` 保存：<br>`/mnt/SDCARD/Emus/VIDEOS/mpv.sh /mnt/SDCARD/Roms/VIDEOS/test.mp4 > /mnt/SDCARD/mpv_test.log 2>&1`。 | <!-- [待回填] 画面是否正常、声音是否正常、流畅度如何 --> |
| **4** | 键位逐个验证：<br>- **A / B / Start**：暂停 / 继续<br>- **左 / 右**：快退 / 快进 5 秒<br>- **下 / 上**：快退 / 快进 60 秒<br>- **L1 / R1**：上一集 / 下一集<br>- **X / Y**：音量增大 / 减小（新增映射）<br>- **Menu 键**：退出<br>- **Start + Select**：强制退出<br>- **Mode 键长按约 1.2 秒**：看门狗杀掉进程退出 | 各键位行为符合预期。<br>X/Y 键能够正常改变音量；Mode 键长按能够安全终止 mpv。 | 1. 记录 ENTER 键是执行 pause 还是 next。<br>2. 若 Mode 键无效：在 SSH 运行 `cat /proc/bus/input/devices` 确认 Brick 手柄的真实 event 节点，修正 `thd.conf` / `mpv.sh` 中的 `/dev/input/event3`。<br>3. 若手柄全局无响应：SSH 手动启动 `gptokeyb2 -v` 查看调试日志。 | <!-- [待回填] 各按键响应情况，特别是 X/Y 音量与 Mode 退出是否生效 --> |
| **5** | 芯片硬件解码与渲染后端摸底（取证）：<br>1. `/mnt/SDCARD/System/bin/mpv --vo=help`<br>2. `/mnt/SDCARD/System/bin/mpv --hwdec=help`<br>3. 测试 `--hwdec=auto-safe` 播放对比 | 取得 A133P 平台该构建实际编译进的 VO 与 hwdec 后端清单。 | 此步骤为纯取证：把两个 help 的完整文本原文回填，供后续评估是否需要固化特定 `--vo=` 或 `--hwdec=` 参数。 | <!-- [待回填] 粘贴 --vo=help 与 --hwdec=help 完整输出 --> |
| **6** | 网络播放能力测试：<br>1. SMB 直连测试：<br>`mpv "smb://<NAS-IP>/<共享目录>/test.mkv"`<br>2. HTTP 串流测试：<br>在 UI 点击改好地址的 `nas-http-example.m3u8` | - SMB 直连：预期失败（报 Protocol not found）。<br>- HTTP 串流：预期流畅播放。 | 1. 如实回填 SMB 报错原文，确认是否确实缺少 libsmbclient 支持。<br>2. 验证 HTTP 串流在 2.4GHz WiFi 下的缓冲稳定性。 | <!-- [待回填] 粘贴 SMB 报错原文与 HTTP 串流实测表现 --> |
| **7** | 音频格式与高规格编码压力测试：<br>1. 播放 AC3 音轨视频<br>2. 播放 1080p HEVC (H.265) 视频 | - AC3 音轨：正常解码发声。<br>- 1080p HEVC：记录帧率是否流畅（软解 vs 硬解）。 | 原装 TinaPlayer 不支持 AC3，若 mpv 能正常发声则证明软解补充成功；1080p HEVC 卡顿情况将决定是否必须探索硬解参数。 | <!-- [待回填] AC3 是否有声音；1080p HEVC 是否流畅及 CPU 表现 --> |

---

## 验收结论回填区
- **整体可用性**：[ ] 通过 / [ ] 需调整修复 / [ ] 不可用
- **测试人员**：
- **测试日期**：
- **固件版本**：TrimUI Brick Stock OS v_______
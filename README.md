# mpv for TrimUI Brick (Stock OS)

**[English](#english) | [中文说明](#chinese)**

[![Release](https://img.shields.io/github/v/release/gabrie/MPV-for-Trimui-Brick?color=blue)](https://github.com/gabrie/MPV-for-Trimui-Brick/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-TrimUI%20Brick%20(A133P)-orange.svg)]()
[![Install](https://img.shields.io/badge/Install-Zero--flash%20(SD%20Copy)-green.svg)]()

---

<a name="english"></a>
## English

### Overview
A standalone, zero-flashing port of the **mpv media player** extracted from [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) for the **TrimUI Brick Stock OS (Official Firmware)**.

Supports local video playback, seamless previous/next playlist navigation, aspect-ratio controls, hardware-friendly button mapping via `gptokeyb2`, and wireless LAN streaming from DLNA/UPnP media servers (Synology, QNAP, PC, routers).

### Key Features
- **Zero Flashing / No Firmware Modification**: Pure MicroSD card file overlay; leaves internal eMMC partitions completely untouched.
- **Native MainUI Integration**: Registers as a native `VIDEOS` system on the main menu. Browse, pick, and play files directly from the stock interface.
- **Full Gamepad Controls**: Dedicated gamepad-to-mpv input mapping via bundled `gptokeyb2`.
  - **D-Pad Left / Right**: Fast seek 5 seconds backward/forward (continuous auto-repeat when held).
  - **D-Pad Down / Up**: Single-shot 60 seconds backward/forward.
  - **L2 / R2**: Seamless switch to previous / next video in folder or DLNA playlist.
  - **L1 / R1**: Playback speed -10% / +10%.
  - **X / Y**: Aspect ratio & zoom controls (Vertical axis fill / Horizontal axis fill).
  - **A / B / Start**: Play / Pause.
  - **Select**: Mute / Unmute.
  - **Menu / Back**: Graceful quit with resume bookmark saved.
- **Resume Playback**: Remembers playback progress automatically.
- **Subtitles**: Bundled TrueType font (`subfont.ttf`) with complete ASS/SRT rendering support.
- **LAN DLNA / UPnP Streaming**: One-click scanner (`刷新 NAS 列表.launch`) crawls your media server folders (e.g., Synology Video Station / Media Server) and generates streaming playlists (`.m3u8`) with direct HTTP media URLs.

### Quick Start
1. Download `mpv-stock.zip` from [Releases](https://github.com/gabrie/MPV-for-Trimui-Brick/releases/latest);
2. Extract and copy the folders (`Emus`, `Roms`, `System`, etc.) to the root directory of your TrimUI Brick MicroSD card;
   > ⚠️ **IMPORTANT**: If prompted to overwrite `System/lib/`, select **MERGE** (do NOT delete existing stock OS libraries).
3. Place local videos in `/mnt/SDCARD/Roms/VIDEOS/` (or configure `nas_config.ini` for NAS streaming);
4. Insert SD card into TrimUI Brick, power on, press **Menu** button on the home screen -> select **Refresh Roms**;
5. Open the **VIDEOS** category and enjoy!

See [INSTALL.md](INSTALL.md) for complete details.

### Button Controls Reference
| Button | Action / mpv Command | Description |
| :--- | :--- | :--- |
| **A / B / Start** | `space` | Play / Pause |
| **D-Pad ← / →** | `left` / `right` | Seek -5s / +5s (Continuous auto-repeat when held) |
| **D-Pad ↓ / ↑** | `down` / `up` | Seek -60s / +60s (Single-shot) |
| **L2 / R2** | `<` / `>` | Previous video / Next video in playlist |
| **L1 / R1** | `[` / `]` | Speed down / Speed up by 10% |
| **X** | `x` (`set panscan 1.0`) | Vertical axis stretch / Fill screen (eliminates black bars) |
| **Y** | `y` (`set panscan 0.0`) | Horizontal axis stretch / Fit screen (original aspect ratio) |
| **Select** | `m` | Mute / Unmute |
| **Menu / Back** | `q` | Quit mpv (auto-saves playback position) |
| **Start + Select** | Combo Exit | Force terminate mpv via gptokeyb2 |
| **Mode (Hold 1.2s)** | `BTN_MODE` | Terminate mpv via `thd` watchdog daemon |

---

<a name="chinese"></a>
## 中文说明

### 项目简介
本项目将 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) 中的 mpv 视频播放器提取并打包为适用于 **TrimUI Brick 原装系统（官方 Stock OS）** 的免刷机扩展包。

支持本地全格式音视频播放、上下集无缝切片、画面画幅比例切换、掌机原生按键映射以及局域网 NAS (DLNA / UPnP) 无线流媒体串流播放。

### 核心亮点
- **零刷机、不碰固件**：纯 MicroSD 卡文件覆盖与注册，不修改任何 eMMC 原装系统分区。
- **模拟器系统原生选片**：注册为 MainUI 的「视频 / VIDEOS」系统，可在系统列表界面原生浏览、选择并播放视频文件。
- **完整掌机按键支持**：自包含 `gptokeyb2` 守护进程，支持完备的掌机物理按键操作：
  - **方向键 左 / 右**：快退 / 快进 5 秒（长按支持连续连发极速快进退）。
  - **方向键 下 / 上**：单次步进快退 / 快进 60 秒（单次精准跳过片头片尾）。
  - **L2 / R2 扳机键**：无缝切换同目录下或播放列表中的**上一个 / 下一个视频**。
  - **L1 / R1 侧键**：播放速度微调（-10% / +10% 倍速）。
  - **X / Y 键**：画幅与画面拉伸切换（X 轴铺满 / Y 轴铺满无黑边模式）。
  - **A / B / Start 键**：播放 / 暂停。
  - **Select 键**：静音 / 取消静音。
  - **Menu / 返回键**：安全退出并自动记忆保存断点播放进度。
- **断点续播**：自动记忆上次播放时间位置。
- **高清字幕支持**：内置 DejaVu/Subfont 矢量中文字体，支持 ASS/SRT 特效与常规字幕渲染。
- **局域网 NAS (DLNA / UPnP) 无线串流**：通过原生界面的【刷新 NAS 列表】一键扫描抓取 NAS（如群晖、威联通、PC、路由器等）视频目录，直接生成流媒体播放列表无线串流播放。

### 快速安装指南
1. 从 [Releases](https://github.com/gabrie/MPV-for-Trimui-Brick/releases/latest) 下载 `mpv-stock.zip`；
2. 将压缩包解压后复制覆盖到 TrimUI Brick 的 MicroSD 卡根目录；
   > ⚠️ **重要提示**：如果系统提示覆盖 `System/lib/`，请务必选择**合并（Merge）**，切勿删除原有系统库！
3. 将视频放入 `/mnt/SDCARD/Roms/VIDEOS/` 目录（或编辑 `nas_config.ini` 配置 NAS 串流）；
4. 插卡开机，在游戏主菜单按 **Menu 键** -> **Refresh Roms** 刷新列表；
5. 进入「视频」分类，点击片源即可开播。

详细说明请查阅 [INSTALL.md](INSTALL.md)。

---

## 许可证与开源合规 (License & Compliance)

- 本项目派生自 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS)（*Derived from CrossMix-OS*），致谢原作者 cizia64 及 CrossMix 社区、PortMaster 移植团队。
- 本项目整体遵循 **GPL-3.0** 许可证发布，完整条款见随包 [LICENSE](LICENSE)。
- 本项目聚合分发的各独立第三方组件（mpv、FFmpeg 共享库、gptokeyb2、inih）各自保留独立的开源协议：
  - **mpv**: GPL-2.0-or-later
  - **FFmpeg 共享库**: GPL-2.0-or-later
  - **gptokeyb2**: GPL-2.0（全文附于随包 [LICENSE.gpl-2.0](LICENSE.gpl-2.0)）
  - **inih**: New BSD License (3-Clause BSD)（版权声明与全文逐字载于 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)）
- 详细组件出处与对应源码归档链接见 [SOURCES.md](SOURCES.md)。

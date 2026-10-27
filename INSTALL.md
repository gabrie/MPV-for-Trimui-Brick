# mpv for TrimUI Brick Stock OS — Installation Guide / 安装与使用说明

**[English](#english) | [中文说明](#chinese)**

---

<a name="english"></a>
## English

### 1. Source and Upstream Origin
- **Source Code Base**: Based on the `CrossMix-OS-main` repository snapshot (upstream `cizia64/CrossMix-OS` main branch, v1.3.0 baseline).
- **Version Metadata**: Sourced from a downloaded snapshot without a `.git` commit hash.
- **Attribution**: This project is *Derived from CrossMix-OS*. Special thanks to cizia64, the CrossMix community, and the PortMaster development team.

### 2. Storage Requirements
- **`System/lib/` Shared Libraries**: ~159.7 MB (332 library files)
- **Extracted Size**: ~166.5 MB (Zip package: ~66.9 MB)
- **Free Space Required**: Ensure at least **200 MB** of free space on your MicroSD card.

### 3. Step-by-Step Installation
1. **Backup (Optional)**: If your MicroSD card already has `System/` or `Emus/` folders, backing them up is recommended.
2. **Copy Files**:
   - Extract `mpv-stock.zip` and copy all subdirectories (`Emus/`, `Roms/`, `Imgs/`, `System/`, `Icons/`, `Backgrounds/`) directly to the root of your MicroSD card.
   - **CRITICAL**: When asked about directory conflicts, choose **MERGE**. Never delete or completely overwrite existing files in `System/lib/`!
3. **Add Videos or Configure NAS**:
   - **Local Playback**: Place your video files (`.mp4`, `.mkv`, `.avi`, `.rmvb`, etc.) into `/mnt/SDCARD/Roms/VIDEOS/`.
   - **LAN NAS Streaming**: Edit `/mnt/SDCARD/Roms/VIDEOS/nas_config.ini`, set your NAS IP, port (default `50001` for Synology DLNA), and target folders.
4. **Refresh ROMs List**:
   - Insert the MicroSD card into your TrimUI Brick, power on, and press the **Menu** button on the home screen -> select **Refresh Roms**.
   - A **VIDEOS** icon will appear on the main system carousel.
5. **Start Playback**:
   - **Local Videos**: Open the VIDEOS category and select a video to play.
   - **NAS Streaming**: In the VIDEOS category, launch `刷新 NAS 列表.launch` (Refresh NAS List). It will scan your NAS and generate playlist entries (`.m3u8`) for instant wireless streaming.

### 4. Differences from CrossMix-OS Baseline
| Path | Type | Details |
| :--- | :--- | :--- |
| `Emus/VIDEOS/mpv.sh` | Bugfix | Fixed missing `$` in `LD_LIBRARY_PATH` export; auto-merges `/usr/lib/gamecontrollerdb.txt` if present. Implemented playlist loop handling. |
| `Emus/VIDEOS/mpv.sh` | Self-contained | Decoupled from external PortMaster paths; bundled `gptokeyb2` and `gamecontrollerdb.txt` inside `Emus/VIDEOS/`. |
| `Emus/VIDEOS/mpv.sh` | Cleanup | Removed orphan command-line options (`--script=...metadata_osd.lua` and showcqt) that do not exist in stock OS. |
| `Emus/VIDEOS/keys.gptk` | Controls | Added auto-repeat for left/right seeking, L2/R2 previous/next switching, X/Y aspect ratio toggle. |
| `Roms/VIDEOS/nas_config.ini` | New | Configuration file for LAN DLNA/UPnP streaming server. |
| `Emus/VIDEOS/sync_nas.sh` | New | Pure POSIX sh + curl DLNA ContentDirectory scanner and M3U8 generator. |
| `Roms/VIDEOS/刷新 NAS 列表.launch` | New | Stock UI shortcut to refresh NAS media playlists. |

---

<a name="chinese"></a>
## 中文说明

### 1. 源码与取材说明
- **代码来源**：基于本地提供的 `CrossMix-OS-main` 文件夹（取自 `cizia64/CrossMix-OS` main 分支下载快照，上游对应 v1.3.0 基线）。
- **版本标识**：下载快照目录中无 `.git` 版本库元数据，无 commit hash，所有组件以该快照内文件为准。
- **致谢与声明**：本项目派生自 CrossMix-OS（*Derived from CrossMix-OS*），致谢原作者 cizia64 及 CrossMix 社区、PortMaster 移植团队。

### 2. 空间占用与容量要求
- **`System/lib/` 共享库体积**：约 **159.7 MB**（332 个库文件）
- **本安装包总大小**：解压后约 **166.5 MB**，压缩包约 **66.9 MB**
- **安装前检查**：请确保 TrimUI Brick 的 MicroSD 卡至少有 **200 MB** 以上的剩余空间。

### 3. 安装步骤
1. **备份（可选但推荐）**：如果您的 SD 卡根目录已有 `System/` 或 `Emus/` 目录，建议先备份。
2. **复制文件**：
   - 将 `mpv-stock.zip` 解压，将其中的所有子文件夹（`Emus/`、`Roms/`、`Imgs/`、`System/`、`Icons/`、`Backgrounds/`）直接复制覆盖到 MicroSD 卡根目录。
   - **注意（极其重要）**：系统提示文件夹冲突时，选择**合并（Merge）**，绝对不要删除或整包替换 SD 卡上原有的 `System/lib/` 目录！
3. **放入视频或配置 NAS**：
   - **本地播放**：将视频文件（如 `.mp4`, `.mkv`, `.avi` 等）放入 SD 卡的 `/mnt/SDCARD/Roms/VIDEOS/` 目录中。
   - **局域网 NAS 播放**：在掌机连入 WiFi 后，直接编辑 `Roms/VIDEOS/nas_config.ini`，填写 NAS 的局域网 IP、端口与目标文件夹（群晖等标准 DLNA/UPnP 端口通常为 `50001`）。
4. **刷新视频列表**：
   - 将 SD 卡插回 TrimUI Brick，开机进入原装系统；
   - 在主界面按掌机 **Menu 键** -> 选择 **Refresh Roms**（刷新 ROM 列表）；
   - 刷新完成后，主系统列表会出现 **「视频 / VIDEOS」** 图标。
5. **开始播放**：
   - **本地视频**：直接选中视频文件点击播放。
   - **NAS 视频同步与播放**：进入「视频」分类，点击 **【刷新 NAS 列表】**。掌机将自动扫描局域网 NAS 并生成播放列表，完成后即可直接无线流媒体播放！

### 4. 控制键位说明
| 手柄按键 | 映射动作 | mpv 行为 |
| :--- | :--- | :--- |
| **A / B / Start** | Space | 播放 / 暂停 |
| **方向键 左 / 右** | Left / Right | 快退 5 秒 / 快进 5 秒（长按连续极速连发） |
| **方向键 下 / 上** | Down / Up | 快退 60 秒 / 快进 60 秒（单次跳跃） |
| **L2 / R2** | < / > | 无缝切换上一个视频 / 下一个视频 |
| **L1 / R1** | [ / ] | 播放速度减慢 / 加快 10% |
| **X** | x | 画面铺满竖轴（无黑边满屏裁切模式） |
| **Y** | y | 画面恢复原始比例（完整视野模式） |
| **Select** | m | 静音 / 恢复静音 |
| **Menu 键 / Back** | q | 退出播放器（自动保存断点位置） |
| **Start + Select** | 退出组合键 | gptokeyb2 内置强制终止 |
| **Mode 键长按 (1.2s)** | BTN_MODE | 通过 thd 守护进程强制终止 mpv 进程 |

---

## 5. 开源许可证 (License)
本项目整体遵循 **GPL-3.0** 发布，各第三方独立组件保留各自许可证，详见 `LICENSE`、`SOURCES.md` 与 `THIRD_PARTY_NOTICES.md`。

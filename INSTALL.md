# mpv for TrimUI Brick Stock OS — 安装与使用说明

本软件包将 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) 中的 mpv 视频播放器提取并打包为适用于 **TrimUI Brick 原装系统（官方 Stock OS）** 的免刷机扩展包。
遵循纯 SD 卡文件覆盖机制，**不刷机、不碰固件、不动 eMMC 分区**。支持本地视频与局域网 NAS (DLNA / UPnP) 无线串流播放。

---

## 1. 源码与取材说明
- **代码来源**：基于本地提供的 `CrossMix-OS-main` 文件夹（取自 `cizia64/CrossMix-OS` main 分支下载快照，上游对应 v1.3.0 基线）。
- **版本标识**：下载快照目录中无 `.git` 版本库元数据，无 commit hash，所有组件以该快照内文件为准。
- **致谢与声明**：本项目派生自 CrossMix-OS（*Derived from CrossMix-OS*），致谢原作者 cizia64 及 CrossMix 社区、PortMaster 移植团队。

---

## 2. 空间占用与容量要求
- **`System/lib/` 共享库体积**：约 **159.69 MB**（332 个库文件）
- **本安装包总大小**：解压后约 **166.5 MB**，压缩包约 **38 MB**
- **安装前检查**：请确保 TrimUI Brick 的 MicroSD 卡至少有 **200 MB** 以上的剩余空间。

---

## 3. 安装步骤（路线 B：模拟器媒体系统）

1. **备份（可选但推荐）**：如果您的 SD 卡根目录已有 `System/` 或 `Emus/` 目录，建议先备份。
2. **复制文件**：
   - 将 `mpv-stock/` 目录下的所有子文件夹（`Emus/`、`Roms/`、`Imgs/`、`System/`、`Icons/`、`Backgrounds/`）直接复制到 MicroSD 卡的根目录；
   - 或者直接将 `mpv-stock.zip` 解压到 MicroSD 卡的根目录。
   - **注意（重要）**：系统提示文件夹冲突时，选择**合并（Merge）**，绝对不要删除或整包替换 SD 卡上原有的 `System/lib/` 目录！
3. **放入视频或配置 NAS**：
   - **本地播放**：将视频文件（如 `.mp4`, `.mkv`, `.avi` 等）放入 SD 卡的 `/mnt/SDCARD/Roms/VIDEOS/` 目录中。
   - **局域网 NAS 播放**：在掌机连入 WiFi 后，直接编辑 `Roms/VIDEOS/nas_config.ini`，填写 NAS 的局域网 IP、端口与目标文件夹（群晖等标准 DLNA/UPnP 端口通常为 `50001`）。
4. **刷新视频列表**：
   - 将 SD 卡插回 TrimUI Brick，开机进入原装系统；
   - 在主界面按掌机 **Menu 键** -> 选择 **Refresh Roms**（刷新 ROM 列表）；
   - 刷新完成后，主系统列表会出现 **「视频 / VIDEOS」** 图标。
5. **开始播放**：
   - **本地视频**：直接选中视频文件点击播放。
   - **NAS 视频同步与播放**：进入「视频」分类，点击 **【🔄 刷新 NAS 列表】**。掌机将自动扫描局域网 NAS 并生成播放列表，完成后即可直接无线流媒体播放！

---

## 4. 本包与 CrossMix 原版的差异清单

| 相对路径 | 改动类型 | 改动细节与原因 |
| :--- | :--- | :--- |
| `Emus/VIDEOS/mpv.sh` | 修正 Bug | 修复第 3 行环境变量 `export LD_LIBRARY_PATH=...:LD_LIBRARY_PATH` 丢失 `$` 的笔误，改为 `:$LD_LIBRARY_PATH`；启动前若存在系统 `/usr/lib/gamecontrollerdb.txt` 则自动合并，确保 TrimUI 专用手柄映射生效。 |
| `Emus/VIDEOS/mpv.sh` | 解耦自包含 | 移除对外部 `/mnt/SDCARD/Apps/PortMaster/...` 的依赖，将 `gptokeyb2` 与 `gamecontrollerdb.txt` 移入 `Emus/VIDEOS/` 自包含，并输出 `gptokeyb2.log` 以便排错。 |
| `Emus/VIDEOS/mpv.sh` | 清理孤儿行 | 删除原版末尾未生效且无法执行的孤儿参数行（`--script=...metadata_osd.lua` 与 showcqt 音频可视化，原版 scripts/ 并不存在该 lua 脚本），启动命令简化为稳定单行。 |
| `Emus/VIDEOS/keys.gptk` | 修正与补齐 | 修复 `up_down`/`down_down` 等旧语法为标准 `up`/`down`，快进快退立即生效；修正暂停键为 `space`；补齐 X/Y 音量（0/9）、L1/R1 播放倍速调整（[/]）以及 Select 静音（m）。 |
| `Roms/VIDEOS/nas_config.ini` | 新增 | 局域网 NAS (DLNA/UPnP) 播放配置文件（位于视频目录下，方便直接填入 IP、端口与目标文件夹）。 |
| `Emus/VIDEOS/sync_nas.sh` | 新增 | 纯 POSIX sh + curl DLNA 内容目录扫描脚本，支持递归抓取视频流并生成 m3u8。 |
| `Roms/VIDEOS/🔄 刷新 NAS 列表.launch` | 新增 | 原生界面一键同步 NAS 视频列表快捷方式。 |
| `Roms/VIDEOS/README_ROMS.txt` | 新增 | 本地与 NAS 片源目录使用指引。 |
| `INSTALL.md` / `TEST.md` | 新增 | 完整的安装使用指南与真机 7 步验收协议表格。 |
| `LICENSE` / `LICENSE.gpl-2.0` / `SOURCES.md` / `THIRD_PARTY_NOTICES.md` | 新增/齐备 | 遵循 GPL-3.0、GPL-2.0 及 New BSD 协议的完整开源合规文件。 |

---

## 5. 控制键位说明

| 手柄按键 | 映射动作 | mpv 行为 |
| :--- | :--- | :--- |
| **A / B / Start** | Space | 播放 / 暂停 |
| **方向键 左 / 右** | Left / Right | 快退 5 秒 / 快进 5 秒 |
| **方向键 下 / 上** | Down / Up | 快退 60 秒 / 快进 60 秒 |
| **L1 / R1** | [ / ] | 播放速度减慢 / 加快 10% |
| **L2 / R2** | { / } | 播放速度减半 / 翻倍 (0.5x / 2.0x) |
| **X** | 0 | 音量 + |
| **Y** | 9 | 音量 - |
| **Select** | m | 静音 / 恢复静音 |
| **Menu 键 / Back** | q | 退出播放器（自动保存断点位置） |
| **Start + Select** | 退出信号 | gptokeyb2 内置强制退出组合键 |
| **Mode 键长按 (1.2s)** | BTN_MODE | 通过 thd 守护进程强制终止 mpv 进程 |

---

## 6. 开源许可
本安装包按 **GPL-3.0** 许可证聚合发布。
各独立组件许可证与源码链接详见 `SOURCES.md` 与 `THIRD_PARTY_NOTICES.md`。
# mpv for TrimUI Brick (Stock OS)

将 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) 中的 mpv 视频播放器提取并打包为适用于 **TrimUI Brick 原装系统（官方 Stock OS）** 的免刷机扩展包。

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-TrimUI%20Brick%20(A133P)-orange.svg)]()
[![Install](https://img.shields.io/badge/Install-Zero--flash%20(SD%20Copy)-green.svg)]()

---

## 特性亮点

- **零刷机、不碰固件**：纯 MicroSD 卡文件覆盖与注册，不修改任何 eMMC 原装系统分区。
- **模拟器系统原生选片**：注册为 MainUI 的「视频 / VIDEOS」系统，可在系统列表界面原生浏览、选择并播放视频文件。
- **完整掌机按键支持**：自包含 `gptokeyb2` 守护进程，支持手柄按键控制（快进、快退、暂停、上下集切换、音量调节及 Mode 键安全退出）。
- **断点续播**：自动记忆上次播放时间位置。
- **字幕支持**：内置 DejaVu/Subfont 字幕字体，支持 ASS/SRT 字幕渲染。
- **NAS HTTP 串流**：支持通过 `.m3u8` 播放列表串流播放局域网 NAS 或 Web 服务器上的影片。

---

## 快速安装

1. 从 [Releases](../../releases) 下载 `mpv-stock.zip`；
2. 将压缩包解压后复制覆盖到 TrimUI Brick 的 MicroSD 卡根目录；
   > ⚠️ **注意**：如 SD 卡已有 `System/lib/` 目录，请选择**合并（Merge）**，切勿删除原有系统库！
3. 将视频放入 `/mnt/SDCARD/Roms/VIDEOS/` 目录；
4. 插卡开机，在游戏主菜单按 **Menu 键** -> **Refresh Roms** 刷新列表；
5. 进入「视频」分类，点击片源即可开播。

详细安装与目录结构说明请参阅 [INSTALL.md](INSTALL.md)。

---

## 控制键位

| 按键 | 功能 |
| :--- | :--- |
| **A / B / Start** | 播放 / 暂停 |
| **方向键 左 / 右** | 快退 5 秒 / 快进 5 秒 |
| **方向键 下 / 上** | 快退 60 秒 / 快进 60 秒 |
| **L1 / R1** | 上一个视频 / 下一个视频 |
| **X / Y** | 音量增大 / 减小 |
| **Menu 键** | 退出播放器（自动记录播放进度） |
| **Start + Select** | 强制终止播放器 |
| **Mode 键长按 (1.2s)** | 通过看门狗守护进程退出 |

---

## 真机验收协议 (TEST)

如果您是真机测试者，请参考 [TEST.md](TEST.md) 进行 7 步标准化验收测试，并如实记录输出结果。

---

## 开源许可与致谢

- 本项目派生自 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS)（*Derived from CrossMix-OS*），致谢原作者 cizia64 及 CrossMix 社区。
- 遵循 **GPL-3.0** 许可证发布，完整条款见 [LICENSE](LICENSE)。
- 各第三方独立组件（mpv、FFmpeg、gptokeyb2、inih）的许可证及上游源码出处详见 [SOURCES.md](SOURCES.md) 与 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
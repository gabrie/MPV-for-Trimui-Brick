# Sources and Component Licenses / 源码出处与开源组件清单

**[English](#english) | [中文说明](#chinese)**

---

<a name="english"></a>
## English

This distribution package (**mpv for TrimUI Stock OS**) is extracted and adapted from the `main` branch of [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) (downloaded snapshot, upstream v1.3.0 baseline) for the TrimUI Brick official Stock OS.

In compliance with the GNU General Public License and respective open-source licenses, each bundled third-party binary and library retains its independent license, copyright notices, and upstream source information as detailed below:

### 1. mpv
- **Component**: mpv
- **Files**: `System/bin/mpv`
- **Version**: 0.32.0
- **Purpose**: Core media player CLI application
- **License**: GPL-2.0-or-later
- **Upstream Source**: [mpv v0.32.0 Release](https://github.com/mpv-player/mpv/releases/tag/v0.32.0)
  - Source archive: https://github.com/mpv-player/mpv/archive/refs/tags/v0.32.0.tar.gz

### 2. FFmpeg Shared Libraries
- **Component**: FFmpeg (Libraries: `libavcodec`, `libavformat`, `libavutil`, `libswscale`, `libswresample`, `libavfilter`, etc.)
- **Files**: `System/lib/libav*.so*`, `System/lib/libsw*.so*`
- **Version**: 4.4 series (ABI: `libavcodec.so.58`, `libavformat.so.58`, `libavutil.so.56`, etc.)
- **Purpose**: Demuxing, decoding, and filtering audio/video streams
- **License**: GPL-2.0-or-later (Distributed under GPL terms for maximum compliance)
- **Upstream Source**: [FFmpeg n4.4.4 Release](https://github.com/FFmpeg/FFmpeg/releases/tag/n4.4.4)
  - Source archive: https://ffmpeg.org/releases/ffmpeg-4.4.4.tar.xz

### 3. gptokeyb2
- **Component**: gptokeyb2
- **Files**: `Emus/VIDEOS/gptokeyb2`, `Emus/VIDEOS/gamecontrollerdb.txt`
- **Version**: PortMaster adapted version
- **Purpose**: Gamepad input mapping daemon for handheld controls
- **License**: GPL-2.0 (Full text provided in `LICENSE.gpl-2.0`)
- **Copyright**: Copyright (c) PortMaster Contributors / kloptops
- **Upstream Source**: [kloptops/gptokeyb](https://github.com/kloptops/gptokeyb)
  - Releases: https://github.com/kloptops/gptokeyb/releases

### 4. inih
- **Component**: inih (Simple INI file parser in C)
- **Purpose**: INI parser library used by `gptokeyb2`
- **Version**: r53
- **License**: New BSD License (3-Clause BSD)
- **Copyright**: Copyright (c) 2009, Ben Hoyt
- **Third-Party Notice**: Verbatim license text included in `THIRD_PARTY_NOTICES.md`
- **Upstream Source**: [benhoyt/inih r53 Tag](https://github.com/benhoyt/inih/tree/r53)
  - Source archive: https://github.com/benhoyt/inih/archive/refs/tags/r53.tar.gz

### 5. CrossMix-OS Integration Scripts & Configuration
- **Component**: CrossMix-OS Media Integration Scripts & Configuration
- **Files**: `Emus/VIDEOS/mpv.sh`, `Emus/VIDEOS/config.json`, `System/bin/thd`, etc.
- **Version**: main branch snapshot
- **Purpose**: MainUI integration, process supervisor, and video launcher
- **License**: GPL-3.0 (Full text provided in `LICENSE`)
- **Copyright**: Copyright (c) cizia64 and CrossMix-OS contributors
- **Upstream Source**: https://github.com/cizia64/CrossMix-OS

---

<a name="chinese"></a>
## 中文说明

本安装包（mpv for TrimUI Stock OS）基于 [CrossMix-OS](https://github.com/cizia64/CrossMix-OS) 仓库 main 分支（无 .git，本地下载快照，上游版本基线 v1.3.0）提取并适配 TrimUI Brick 原装系统。

依据 GPL 规范与开源许可要求，包内各二进制与库组件各自保留独立许可证与版权声明，组件源码出处与许可信息逐项列明如下：

### 1. mpv
- **组件名称**：mpv
- **包含文件**：`System/bin/mpv`
- **版本**：0.32.0
- **用途**：核心媒体播放器命令行程序
- **许可证**：GPL-2.0-or-later
- **上游源码**：[mpv v0.32.0 Release](https://github.com/mpv-player/mpv/releases/tag/v0.32.0)
  - 源码包归档：https://github.com/mpv-player/mpv/archive/refs/tags/v0.32.0.tar.gz

### 2. FFmpeg 共享库
- **组件名称**：FFmpeg (Libraries: libavcodec, libavformat, libavutil, libswscale, libswresample, libavfilter 等)
- **包含文件**：`System/lib/libav*.so*`, `System/lib/libsw*.so*`
- **版本**：4.4 系列 (ABI: libavcodec.so.58, libavformat.so.58, libavutil.so.56 等)
- **用途**：音频与视频格式解复用及软硬件编解码
- **许可证**：GPL-2.0-or-later（本包按最严格稳妥的 GPL 口径处理与分发，不赌 LGPL 编译选项例外）
- **上游源码**：[FFmpeg n4.4.4 Release](https://github.com/FFmpeg/FFmpeg/releases/tag/n4.4.4)
  - 源码包归档：https://ffmpeg.org/releases/ffmpeg-4.4.4.tar.xz

### 3. gptokeyb2
- **组件名称**：gptokeyb2
- **包含文件**：`Emus/VIDEOS/gptokeyb2`, `Emus/VIDEOS/gamecontrollerdb.txt`
- **版本**：PortMaster 适配版 gptokeyb2
- **用途**：掌机原生手柄按键到键盘输入的映射守护进程
- **许可证**：GPL-2.0（全文附于随包 `LICENSE.gpl-2.0`）
- **版权声明**：Copyright (c) PortMaster Contributors / kloptops
- **上游源码**：[kloptops/gptokeyb 仓库](https://github.com/kloptops/gptokeyb)
  - 发行版归档：https://github.com/kloptops/gptokeyb/releases

### 4. inih
- **组件名称**：inih (Simple INI file parser in C)
- **用途**：gptokeyb2 使用的 INI 配置文件解析库
- **版本**：r53
- **许可证**：New BSD License（3-Clause BSD）
- **版权声明**：Copyright (c) 2009, Ben Hoyt
- **第三方声明**：完整许可证原文已逐字载入随包 `THIRD_PARTY_NOTICES.md`
- **上游源码**：[benhoyt/inih r53 Tag](https://github.com/benhoyt/inih/tree/r53)
  - 源码包归档：https://github.com/benhoyt/inih/archive/refs/tags/r53.tar.gz

### 5. CrossMix-OS 脚本与系统集成
- **组件名称**：CrossMix-OS Media Integration Scripts & Configuration
- **包含文件**：`Emus/VIDEOS/`、`System/bin/thd`、`System/usr/trimui/scripts/` 等
- **版本**：main 分支（快照）
- **用途**：MainUI 模拟器系统注册、启动脚本、防休眠、进程看门狗及状态重置
- **许可证**：GPL-3.0（全文附于随包 `LICENSE`）
- **版权声明**：Copyright (c) cizia64 and CrossMix-OS contributors
- **上游源码**：https://github.com/cizia64/CrossMix-OS

---
注：本包为聚合分发集合，改动文件清单与修改说明见 `INSTALL.md`。

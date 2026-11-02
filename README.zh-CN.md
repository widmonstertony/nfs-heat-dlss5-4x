# 极品飞车 Heat 画面 Mod：DLSS5/MFG 与 FSR/XeFG 双方案

[English](README.md) · [下载预发布安装包](https://github.com/widmonstertony/nfs-heat-dlss5-4x/releases) · [处理原理](docs/PIPELINE.md)

这是给 **Need for Speed Heat / 极品飞车：热度** 使用的非官方画面 Mod：整合社区 DLSS5 ReShade AIO 神经渲染、DLSS 超分辨率和 RTX 4090 Laptop 上的实验性 DLSS-G 4× 插帧，并加入 Heat 专用的加载、运行库和调度修复。Heat 本身没有这些原生功能。

**项目构想与整合方向：Xinpei Tan / [@widmonstertony](https://github.com/widmonstertony)。** Heat 的超分/插帧整合，以及“电影 NR 放在超分前并执行两次”的处理要求，由 Xinpei 提出并推动。这里署名的是项目想法和整合要求；FSR、XeFG、DLSS 及社区框架仍归各自原作者，许可证与致谢继续保留。

## 两套方案，选择其一

| 方案 | 超分 / 神经处理 | 插帧 | 安装入口 |
| --- | --- | --- | --- |
| DLSS5 / DLSS-G | 捕获画面 → 电影 NR 2-pass → DLSS SR | 实验性私有 DLSS-G 4× | 根目录 `INSTALL.cmd` |
| FSR / XeFG | 截取游戏 TAA 输入 → FSR 3.1 或另备的 FSR4 运行库 | Intel XeFG | `variants/fsr-xefg/INSTALL.cmd` |

你之前提出并发布的 [Heat FSR/XeFG 项目](https://github.com/widmonstertony/nfs-heat-fsr4-xefg) 已连同源码、编译桥、安装器、原许可和中英说明收录至 [`variants/fsr-xefg`](variants/fsr-xefg)。使用要求和切换步骤见[方案说明](docs/EDITIONS.md)。**两套方案一次只安装一个。** FSR 版不包含电影 NR，也不能沿用 NVIDIA 版的 4× 结论；此前验证平台是 Radeon Pro 5600M，本次没有在当前笔记本上重新跑分。

**实验性预发布，参考平台为 Windows x64 + RTX 40 系。** 安装包不包含 NVIDIA 专有运行库，使用者必须自行取得 `runtime-requirements.json` 指定的兼容文件。仅下载源码无法自动获得这些文件。本项目不保证所有道路、显卡和版本都无残影或达到 120 FPS。

## 功能

- 电影风格，`Model=3`、`Style=2`；每个处理帧执行 **两次实际 NR 计算**。
- NR 工作分辨率 **1920×1200**，随后用 DLSS SR 重建为 **3840×2400**。
- 每个处理后的真实帧加三张生成帧，组成 **4× 输出**。
- 参考配置使用 576×360 的 NVIDIA 硬件光流。
- NR/SR 和 FG 分离队列、异步显示、识别 4× 倍率的源帧压力限流器。
- ReShade 启动注入；修复 OptiScaler 将私有 NGX 桥和 DriverStore 核心误重定向的问题。
- **Insert** 打开 ReShade/AIO 面板，**F8** 打开 OptiScaler 诊断面板；OptiScaler 自身的 FG 明确关闭，由独立插件负责插帧。

## 原理与画面路径

```text
Heat 渲染 3D 并绘制游戏 HUD，得到捕获画面
  → 将捕获画面缩至 1920×1200
  → Movie NR 第一次处理 → 第二次处理
  → DLSS SR 重建至 3840×2400
  → 私有 DLSS-G 生成三张中间帧 + 一张真实处理帧
  → 异步显示，参考目标 120 Hz
```

当前走的是捕获画面和估计光流的独立通路，**尚未可靠提取游戏原生无 HUD 场景、深度和逐物体运动矢量**。HUD 也可能与场景一起被 NR/插帧处理。这与引擎内部的“无 UI 超分 → 无 UI 插帧 → 每帧重绘 UI”不是同一条路径，也与[之前的 Motorsport UI 修复](https://github.com/widmonstertony/forza-motorsport-dlssg-ui-fix)不同。

1920×1200 是从捕获画面缩小后的神经输入，不代表已经在游戏引擎内拿到了原生低分辨率 DLSS 接口。游戏内另设 50% 渲染比例可以减少 3D 渲染负担。“4K 输出”指这台 16:10 屏幕上的 3840×2400 重建输出，**不是原生 4K 着色**。

## 实测依据与限制

参考环境：Steam 游戏版本 `1.0.60.7040`、RTX 4090 Laptop 16 GB、Windows 11、驱动 `621.1`、3840×2400 / 120 Hz 屏幕、ReShade `6.8.0.2155`、本机 NVIDIA 提供器 `310.9.16.0`。

日志确认了两次 NR、SR、FG 均成功创建和计算；4× 显示器已经工作，120 Hz 屏幕对应约 30 个真实源帧目标。预热后，**标题/菜单中的输出遥测约 96–110 FPS，这不是道路驾驶跑分**。源帧限流启动后，神经重建的 GPU 时间从无上限压力下约 20 ms 降至约 12–14 ms。

车辆、轮毂及 HUD 的残影，发灰/色彩变化、切屏、长时间稳定性与输入延迟仍需要进一步道路验证。日志仍有间隔波动、偶发尖峰和明显排队延迟，部分样本达几十至超过 100 ms。插帧输出帧数高，不等于输入延迟低。**本次发布不宣称这些问题已全部解决。** 详见 [VALIDATION.md](docs/VALIDATION.md)。

## 安装

1. 完全退出 Heat。到 Releases 下载 **`Heat-Graphics-v0.1.1-experimental-kit.zip`** 并解压。以下步骤针对根目录 DLSS5 版，FSR/XeFG 使用上方独立安装入口。
2. 自行取得适用授权下的 NVIDIA NR、SR、FG 运行库和支持 add-on 的 ReShade，放入自己的运行库文件夹。安装器会核对已测试的 SHA-256，不能随便混用其他版本。FG 文件可以叫 `nvngx_dlssg.dll`，哈希正确时会复制成私有名称。来源及版本见 [DEPENDENCIES.md](docs/DEPENDENCIES.md)。
3. 双击 `INSTALL.cmd`，填写包含 `NeedForSpeedHeat.exe` 的游戏目录和运行库目录。若游戏目录权限不足，使用管理员运行。
4. 游戏内按参考配置选择 3840×2400、50% 渲染比例、关闭垂直同步，进入 **Solo / 单人** 测试。安装不改桌面刷新率、NVIDIA 全局设置或系统 NGX OTA。
5. 按 **Insert**，在 add-on 页检查 standalone AIO 状态。初次启动可能编译着色器；日志应出现两次 NR 和私有 FG 握手成功。

PowerShell 用法：

```powershell
.\Install.ps1 -GameDir 'D:\Games\Need for Speed Heat' -RuntimeSource 'D:\MyRuntime' -ValidateOnly
.\Install.ps1 -GameDir 'D:\Games\Need for Speed Heat' -RuntimeSource 'D:\MyRuntime'
```

添加 `-ConfigureGameProfile` 可以备份并自动修改上述四个游戏画面字段；Documents 重定向时用 `-ProfilePath` 指定文件。默认安装只写选定的游戏目录。

安装器会备份被替换文件，将游戏根目录其他 `.addon64` / `.asi` 暂存至备份，防止多个图形管线同时工作。已有 ReShade/OptiScaler 配置也会先备份，再应用本包配置。`scripts` 等子目录中的其他注入器需要自行停用。不要与旧 FSR4/XeFG Heat 桥混装。

本配置针对 16:10 / 3840×2400。3840×2160 屏幕需要在 AIO 与游戏里选择相匹配的 16:9 输入、输出，此组合尚未验证。限流器工作时真实源帧目标约为屏幕刷新率除以 4，60 Hz 屏幕不属于本次实测环境。生成帧不会产生新输入响应。

## 卸载与恢复

退出游戏后运行 `UNINSTALL.cmd`，输入相同目录。恢复依据是游戏中的 `Heat-DLSS5-4x.install.json` 和 `_HeatDLSS5Backups`。安装文件移至恢复文件夹，原文件及其他 add-on 恢复，备份保留可取回。若安装后的文件或已配置游戏画面文件又被修改，恢复会停止并提示检查，避免覆盖新改动。安装中断也可用同一脚本恢复。

## 源码与构建

见 [BUILD.md](docs/BUILD.md)。仓库包含实际修改的完整 AIO 源文件、参与构建的 MIT midpoint/provider 源码、Heat gate 源码、OptiScaler 完整替换文件和针对固定上游提交的补丁。上游版本记录在 `source-pins.json`。SDK 与上游依赖按各自许可另行取得。

`payload/` 提供编译好的开源 Mod 文件。**不发布 NVIDIA 运行库/模型、游戏程序、存档、截图、个人日志、访问令牌或 ReShade 二进制**。其中小文件 `dlss5_nvngx.dll` 是开源调用桥，并非 NVIDIA 专有运行库。

## 致谢与许可证

本项目修改并整合 kibblerz 的 [DLSS5 ReShade AIO](https://github.com/kibblerz/DLSS5-Reshade-AIO)（Apache-2.0）、[DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder)（MIT）、OptiScaler（GPL-3.0）、Michael Robles 的 Universal MFG Unlocker 1.7.0 组件（MIT）、Ultimate ASI Loader（MIT）、MinHook 和 ReShade 接口。底层神经模型和上述框架不属于本项目原创。请保留 `licenses/` 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 的声明。

独立社区项目，未经 NVIDIA、EA、Ghost Games、ReShade 或 OptiScaler 背书。在线/反作弊环境兼容性未经验证，建议单人使用。

# Runtime dependencies / 运行依赖

The kit includes no NVIDIA proprietary runtime or model. Obtain those separately under applicable terms. The pinned hashes in `runtime-requirements.json` describe the exact tested files, not a promise that every upstream download provides them. If you do not have these files, **this release alone cannot enable DLSS5 + 4×**. Do not use arbitrary DLL-download sites.

本包不提供 NVIDIA 专有运行库或模型，需依适用许可自行取得。`runtime-requirements.json` 是已测试文件哈希，不保证上游任意下载包都包含相同文件。没有这些文件时，本包不能独立开启 DLSS5 + 4×，请勿使用来源不明的 DLL 下载站。

| Input filename | Tested version | Source / licensing information |
| --- | --- | --- |
| `ReShade64.dll` | 6.8.0.2155 with add-on support | [ReShade](https://reshade.me/) / [source](https://github.com/crosire/reshade) |
| `nvngx_dlss.dll` | 310.9.16.0 | [NVIDIA DLSS](https://developer.nvidia.com/rtx/dlss) / [SDK](https://github.com/NVIDIA/DLSS) |
| `nvngx_dlssnr.dll` | Local provider 310.9.16.0 | Separately obtained NR provider; availability and use governed by NVIDIA terms |
| `nvngx_dlssg.dll` or `nvngx_dlssg_standalone.dll` | Local provider 310.9.16.0 | Separately obtained FG provider; must match pinned hash |

All four files are supplied through `-RuntimeSource`. The installer copies FG to its private basename, leaving your source folder untouched. The tiny `dlss5_nvngx.dll` bundled in `payload` is the Apache-licensed caller bridge compiled from this repository, not a redistributed NVIDIA library.

Four open-source components are installed: patched OptiScaler as `dxgi.dll`, patched AIO as `standalone-dlssnr.addon64`, Heat's `HeatMfgGateOnly.asi`, and Ultimate ASI Loader as `d3d11.dll`. The loader starts the gate helper. ReShade is loaded by OptiScaler at startup. The AIO module locates the installed driver NGX core; no driver files are copied, modified on disk or published.

The supplied binaries require the x64 Visual C++ runtime. No driver, global OTA, Windows security or firmware settings are modified by the installer.

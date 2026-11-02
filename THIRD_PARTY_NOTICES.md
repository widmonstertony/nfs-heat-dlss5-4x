# Third-party notices / 第三方声明

This distribution is an aggregate of independently licensed components. No license here relicenses NVIDIA runtimes, game code or models.

| Component | Origin / notices | License |
| --- | --- | --- |
| AIO add-on + caller bridge | kibblerz, DLSS5 ReShade AIO; pinned source and modifications in `src/aio`; see `NOTICE` | Apache-2.0 |
| Feeder interface headers | Jean-Laurent ROUZIES; portions attributed to NIGos | MIT |
| Midpoint/provider code | Michael Robles, Universal MFG Unlocker 1.7.0; exact used source closure in `src/mfg` | MIT |
| Patched OptiScaler | OptiScaler contributors; base commit and complete modified files in `src/optiscaler-overrides` | GPL-3.0 |
| Ultimate ASI Loader | ThirteenAG, unmodified `payload/d3d11.dll` | MIT |
| MinHook statically linked into AIO | Tsuda Kageyu and contributors | BSD-style |
| NVIDIA Optical Flow interface headers | Original notices retained in `src/aio/addon/include/nvOpticalFlow*.h` | Original permissive header license |
| New Heat gate, installer and packaging scripts | 2026 widmonstertony | MIT, see `licenses/Heat-MIT.txt` |

Changes in this fork: Heat-specific proxy/interop and private-NGX loading handling, startup hidden-window compatibility, multiple NR passes and private FG integration, four-output scheduling, split queues and adaptive source-pressure pacing. This is not an original implementation of NVIDIA neural rendering or the upstream frameworks.

The ReShade interfaces, ImGui, Vulkan, NVIDIA NGX declarations and other SDK/build dependencies are externally supplied. Their own licenses and notices apply. ReShade binaries and NVIDIA NR/SR/FG runtime DLLs/models are **not included**. No game executable, shader dump, save, user log or private configuration snapshot is included.

Chinese: 本发行包由多个独立许可组件组成。请分别遵守 `licenses/` 中 Apache、GPL、MIT、BSD 及源文件保留的接口声明。Heat 修复属于对已有开源工程的修改和整合，不主张 NVIDIA 模型或原框架的著作权。运行库、游戏文件和个人数据不在发布内容中。

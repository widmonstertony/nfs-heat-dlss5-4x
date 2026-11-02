# Pipeline / 处理路径

The reference implementation captures Heat's D3D11 backbuffer after the game's rendering. It downsamples that captured image, estimates screen-space motion using NVIDIA Optical Flow, runs two NR passes, performs DLSS SR, and uses a private DLSS-G provider for three generated frames plus one real processed frame.

当前实现从 Heat 的 D3D11 后备缓冲捕获画面，缩小后通过 NVIDIA Optical Flow 估计屏幕空间运动，再执行两次 NR、DLSS 超分及私有 DLSS-G 4× 输出。游戏 HUD 可能已经在捕获画面里。

The change set addresses:

1. Hard-coded 2× real-frame admission and FG expiry assumptions in a 4× presenter. The real-frame budget is refresh / 4; the generated-frame deadline window is four output intervals, capped at 40 ms.
2. A 1×1 OptiScaler bootstrap window that could cause ReShade runtime initialization failures. The hidden client is 64×64; AIO ignores helper swapchains.
3. Late ReShade injection missing OptiScaler's existing wrapped DXGI factory. ReShade is loaded at startup instead.
4. OptiScaler's suffix matching redirecting `dlss5_nvngx.dll` and an explicitly selected DriverStore `_nvngx.dll` to its own proxy. The two precise cases are exempted; ordinary game NGX requests still follow the proxy.
5. Duplicate FG initialization: the published OptiScaler profile uses `FGInput=NoFG`, `FGOutput=NoFG`, `Enabled=false`. AIO owns FG.
6. An old governor maximum of refresh / 2, replaced with refresh / (generated frames + 1). This reduces pointless source submissions when the standalone processor is overloaded.
7. Ada provider gate and midpoint handling, reused from MIT community implementations. This is experimental community compatibility work, not official RTX 40 MFG support.

这些修改解决了接管、误重定向、重复初始化和部分排队问题，不能补齐游戏原生深度、逐物体运动矢量或无 HUD 输入。轮毂、遮挡切换与 UI 残影仍可能出现。

Two passes mean two NR evaluations, not two independent complete renderings of the physical game world. 4× means an output ratio, not four times the responsiveness or four times the scene information.

2-pass 是连续两次神经处理，不是把整个物理场景真实渲染两遍。4× 是输出帧倍率，不意味着输入响应或场景信息翻四倍。

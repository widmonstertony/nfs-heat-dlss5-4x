# Build / 构建

Use Visual Studio 2022 with x64 MSVC v143, C++20 support, a Windows SDK and an x64 Developer PowerShell. Build dependencies must be obtained under their own licenses. This is source plus build instructions, not a bundled SDK distribution.

## AIO + Heat gate

`src/aio/addon/src` contains the complete source used by the published add-on, not just a diff. `src/mfg` contains the complete quoted-include closure for the midpoint/provider implementation. `src/aio/external/DLSS5-Feeder/src` preserves the two MIT feeder headers used by AIO.

Obtain the pinned Feeder checkout in `source-pins.json` and provision its `external/ngx`, `external/reshade/include`, `external/imgui`, `external/vulkan` and `external/minhook` dependencies. Then:

```powershell
.\tools\Build-AIO.ps1 -FeederRoot 'D:\Source\DLSS5-Feeder'
```

Outputs are placed in `build/`. This compiles the add-on, caller bridge and Heat gate. Source file paths and SDK paths are parameters, with no developer home-directory dependency. The shipped public add-on source is byte-for-byte the local source used for the tested binary, except an added modification notice comment.

## OptiScaler

1. Obtain OptiScaler commit `941ce6a1c12f16fec5dfec2898a027fdce06dd2c` from [upstream](https://github.com/optiscaler/OptiScaler/tree/941ce6a1c12f16fec5dfec2898a027fdce06dd2c), including pinned submodules and the SDK/build libraries required by its solution. Preserve its GPL and dependency licenses.
2. Copy the entire `src/optiscaler-overrides/OptiScaler` tree over the checkout's `OptiScaler` directory. This includes the otherwise-untracked `DxgiFactory_SkipState.h`. `src/optiscaler-changes.patch` documents tracked changes against that exact commit.
3. Build `OptiScaler.sln`, **Release | x64**. Use the solution rather than building the `.vcxproj` directly, because dependency paths rely on `SolutionDir`.
4. The linked DLL is `x64/Release/OptiScaler.dll`; install it as `dxgi.dll`.

The upstream post-build packaging commands do not consistently quote paths. If packaging reports errors after a successful linker result, inspect the produced DLL; fix/disable only that packaging event in your local checkout. Do not confuse packaging failure with compiler or linker failure. Publicly redistributing a rebuilt DLL requires publishing the matching source changes and preserving GPL notices.

## Provenance and source availability

`source-pins.json` fixes upstream revisions; `src/*-changes.patch` and full replacement files contain the local changes. The modified OptiScaler is GPL-3.0. The AIO/bridge sources derive from Apache-2.0 AIO; feeder and MFG components retain MIT notices. No NVIDIA implementation or model source is claimed or supplied. The Ultimate ASI Loader binary is unmodified, hash-pinned in the payload manifest; its corresponding MIT source is [upstream](https://github.com/ThirteenAG/Ultimate-ASI-Loader).

中文：AIO、Heat gate 和参与编译的 MFG 代码均提供完整源文件；OptiScaler 提供固定上游提交、完整替换文件和补丁。构建需自行配置相应 SDK。OptiScaler 应从 `.sln` 构建，避免缺少 `SolutionDir`；路径含空格时，上游打包事件可能报错，请区分链接结果与打包结果。运行库不在源码包中。

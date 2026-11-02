# Editions and switching / 方案选择与切换

Project idea and integration direction / 项目构想及整合方向：
**Xinpei Tan / @widmonstertony**.

| | DLSS5 / MFG edition | FSR / XeFG edition |
| --- | --- | --- |
| Source | Root `src/` | `variants/fsr-xefg/src/` |
| Install | Root `INSTALL.cmd` | `variants/fsr-xefg/INSTALL.cmd` |
| Restore | Root `UNINSTALL.cmd` | `variants/fsr-xefg/RESTORE.cmd` |
| Neural style | Movie NR, 2 passes | No NR/Movie processing |
| Upscaler | NVIDIA DLSS SR | FSR 3.1 or local FSR4 INT8 runtime |
| FG backend | Experimental private NVIDIA DLSS-G 4× | Intel XeFG, not AMD FSR FG |
| Reference hardware | RTX 4090 Laptop | Radeon Pro 5600M, MacBookPro16,4 under Windows |
| Dependencies | Root `runtime-requirements.json` | Variant `manifest.json` |
| Compatibility | Reference profile only | Original hardware restriction retained |

The FSR edition comes from the author's earlier public project:
[nfs-heat-fsr4-xefg](https://github.com/widmonstertony/nfs-heat-fsr4-xefg),
commit `63784d89717ca0c7ddbd4204c3cb72cea7a946a9`.
Its original compiled bridge hash is
`D45249B2D70DCD300F3CB7025A47687A47DE255E34414EA30DDB87373BA50EAB`.
The bundled loader and bridge match the original published manifest. The only
activation change is adding an OptiScaler ASI-plugin path so its loader calls
the bridge's guarded `InitializeASI` export. The prior extra-plugin LoadLibrary
route is retained; duplicate initialization is blocked in the bridge. The source
and binary have not been replaced with the later, uncommitted DLSS experiments.

旧 FSR 方案从原公开提交收录，保留原编译桥及其哈希。仅补充 OptiScaler 调用
`InitializeASI` 的加载配置，没有混入后来尚未提交的 DLSS 调试版本，也没有声称
在当前笔记本上重新验证了画面、帧率和稳定性。

## Switching / 切换

1. Exit Heat completely / 完全退出游戏。
2. Run the currently installed edition's restore tool / 运行当前版本的恢复工具。
3. Confirm the existing injector files and `HeatTemporalBridge` installation are
   no longer active; preserve the generated backup directories / 确认旧注入文件和
   `HeatTemporalBridge` 安装已停用，保留备份目录。
4. Run the other edition's installer with that edition's separately obtained,
   hash-matching runtime folder / 使用另一方案的安装器及其匹配运行库。

The FSR installer refuses existing `dxgi.dll`, `d3d11.dll`, configuration files
and `HeatTemporalBridge` rather than replacing an active mod. If restoring the
DLSS edition brings back pre-existing injector files, those must also be
reviewed/restored before the FSR installer can proceed. Both editions own the
same proxy filenames and cannot be layered as two independent frame generators.

FSR 安装器会拒绝覆盖已有注入文件；若 DLSS 卸载恢复了更早的 Mod，先检查并恢复
那些文件。两套方案使用相同代理 DLL 名称，不能直接叠加。此处收录是提供选择，
不是在 FSR 管线后再叠加 DLSS5 或两套插帧。

The original FSR hardware guard remains in place. `-AllowUntestedHardware`
only bypasses detection and does not establish compatibility. F9 is the FSR
bridge's session-disable key; the root NVIDIA AIO panel uses Insert.

FSR 版仍保留原硬件检测；`-AllowUntestedHardware` 只跳过检测，不代表兼容。
FSR 桥按 F9 关闭本次效果；根目录 NVIDIA AIO 面板按 Insert。

# Validation / 验证记录

Local reference session: 2026-11-01. This file contains hand-reviewed aggregate measurements only, with no personal paths, raw logs, screenshots or account data.

| Item / 项目 | Observed / 结果 |
| --- | --- |
| NR model/style | Model 3 / style 2 (Movie) |
| NR evaluations | Two successful feature-18 passes |
| Neural input / output | 1920×1200 → 3840×2400 |
| Private provider | Gate handshake ready, Ada midpoint ready |
| FG | Successful creation; 3 generated outputs then real output (4×) |
| Target display | 120 Hz; governor 30 real FPS |
| Warm title/menu output | Approximately 96–110 FPS; later samples varied |
| Reconstruction GPU time | About 12–14 ms with source governor; about 20 ms before |
| Remaining problems | Uneven intervals and spikes; variable queue latency, sometimes >100 ms |
| Road benchmark | Not completed for this published build |
| Ghosting / HUD / color | Not certified eliminated |
| Alt-Tab / long sessions / other GPUs | Not validated |

The reference has an intentionally constrained real-frame source. A 100 FPS output counter can coexist with roughly 30 source frames per second. Count generated frames separately when comparing latency or native rendering performance.

参考配置限制真实源帧，100 FPS 输出可以与约 30 个真实源帧同时存在。比较原生性能与延迟时，请区分生成帧。不得用标题菜单的帧数当驾驶性能保证。

Before reporting an issue, record game/runtime versions, output/source resolution, whether NR and FG are enabled, and the symptom. Remove usernames, local paths and other personal data before sharing logs. The mod never uploads diagnostics automatically.

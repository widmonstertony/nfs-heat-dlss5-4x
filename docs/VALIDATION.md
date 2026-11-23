# Validation / 验证记录

## v0.1.2 road test / v0.1.2 三分钟实驾

Recorded on November 22, 2026. Steam Heat `1.0.60.7040`, Windows 11, RTX 4090 Laptop 16 GB, 3840×2400 at 120 Hz, ReShade `6.8.0.2155` and NVIDIA runtime `310.9.16.0`. The game's saved settings were 2560×1600 borderless, 75% render scale and VSync off. The add-on logged 1920×1200 NR input and 3840×2400 presenter output. Movie (Model 3 / Style 2), both NR passes, DLSS SR and 4× DLSS-G were all active.

2026 年 11 月 22 日实测。Steam 游戏版本 `1.0.60.7040`、Windows 11、RTX 4090 Laptop 16 GB、3840×2400 / 120 Hz 屏幕、ReShade `6.8.0.2155`、NVIDIA 运行库 `310.9.16.0`。游戏保存设置为 2560×1600 无边框、75% 渲染比例、垂直同步关闭。插件实际记录的 NR 输入为 1920×1200、呈现输出为 3840×2400。电影风格（Model 3 / Style 2）、两遍 NR、DLSS 超分和 4× DLSS-G 均已生效。

| Measure / 测量项 | Result / 结果 |
| --- | --- |
| Duration and log samples / 时长与日志采样 | 180 s; 36 samples at 5 s intervals / 180 秒，每 5 秒一条，共 36 条 |
| New output timeouts / 新增输出超时 | **0** (cumulative 151 → 151 / 累计计数未变); 15 in the previous roughly 195 s drive / 上次约 195 秒实驾新增 15 次 |
| FG submissions / FG 提交 | +5,334; zero queue-pressure bypasses or deadline drops / 增加 5,334 次，队列压力绕过与截止丢帧均为 0 |
| Add-on output FPS / 插件输出帧率 | 110–122 FPS, median / 中位数 118 FPS |
| Real source frames / 真实源帧 | 30 FPS; mean per-sample source interval / 各段源帧时间均值 33.31–33.35 ms |
| Source frame time P99 / 源帧时间 P99 | Per-sample / 各段 36.71–42.40 ms; median of sample P99s / 各段 P99 中位数 38.82 ms |
| Highest recorded source interval / 日志所见最长源帧间隔 | 55.87 ms |

The earlier timeout-driven stalls did not recur during this road test. Output scheduling still registered 96 presentations arriving at the pacing step more than a quarter of a 120 Hz frame interval late (about 2.08 ms). The FPS samples come from the add-on's short-window present counter. This run did not capture display scanout intervals, quantify ghosting or color, or validate alt-tabbing, long sessions or other GPUs. The game reached the drive after a startup retry on this setup.

本轮实驾没有复现先前由输出超时导致的短顿。调度器仍记录了 96 次到达呈现节拍步骤偏晚，判定阈值为 120 Hz 单帧间隔的四分之一（约 2.08 毫秒）。帧率来自插件的短窗口呈现计数。本次未抓取屏幕逐帧刷新时间，也未量化残影或颜色变化、验证切屏、长时间运行或其他显卡。这台机器重试启动一次后进入实驾。

## Earlier title/menu reference / 此前的标题与菜单参考

Local reference session / 本机参考测试：2026-11-01.

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
| Road benchmark | Outside the scope of this earlier session / 此前这轮未做道路测试 |
| Ghosting / HUD / color | Not certified eliminated |
| Alt-Tab / long sessions / other GPUs | Not validated |

The reference has an intentionally constrained real-frame source. A 100 FPS output counter can coexist with roughly 30 source frames per second. Count generated frames separately when comparing latency or native rendering performance.

参考配置限制真实源帧，100 FPS 输出可以与约 30 个真实源帧同时存在。比较原生性能与延迟时，请区分生成帧。不得用标题菜单的帧数当驾驶性能保证。

Before reporting an issue, record game/runtime versions, output/source resolution, whether NR and FG are enabled, and the symptom. Remove usernames, local paths and other personal data before sharing logs. The mod never uploads diagnostics automatically.

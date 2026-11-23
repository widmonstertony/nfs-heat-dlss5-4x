# 0.1.2-experimental

Heat's presenter keeps its refresh phase through small scheduling delays. When
the GPU has not released any output command slots, the presenter makes a short,
interruptible wait before giving up. The capture worker also retries pending
work when an output slot becomes available after its last wake signal.

修正 Heat 输出计时累积误差。输出缓冲临时用满时，显示线程会短暂等待 GPU
释放可用槽位。捕获线程会重查尚未处理的帧，避免在缓冲腾空后继续停帧。

# 0.1.1-experimental

Includes the earlier Heat FSR3.1/FSR4 + Intel XeFG edition, its published source,
original bridge binary, installer and bilingual documentation. Both editions
are packaged separately within the kit and must not run together. Credits now
explicitly identify Xinpei Tan / @widmonstertony as the originator of the Heat
project concept and integration direction, preserving all upstream attribution.

FSR installer activation now asks OptiScaler to call InitializeASI; the bridge
binary and its reference hardware/runtime requirements are unchanged. This is
a packaging/activation update, not a new in-game performance certification.

# 0.1.0-experimental

First public Heat integration of Movie NR 2-pass, 1920×1200 working input,
3840×2400 reconstructed output and experimental 4× DLSS-G on the reference
RTX 4090 Laptop. Includes startup ReShade compatibility, private NGX loader
exceptions, single FG ownership, 4× scheduling/governor corrections, source,
hash-checked install/restore tools, and English/Chinese documentation.

Initial title/menu validation only. Driving quality, input latency and
long-session stability remain experimental. NVIDIA runtimes not included.

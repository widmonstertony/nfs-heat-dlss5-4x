# NFS Heat — DLSS5 Movie 2-pass + experimental 4× MFG

[简体中文](README.zh-CN.md) · [Download prerelease](https://github.com/widmonstertony/nfs-heat-dlss5-4x/releases) · [How it works](docs/PIPELINE.md)

An unofficial **Need for Speed Heat** graphics mod integrating the community DLSS5 ReShade AIO neural-rendering pipeline, DLSS Super Resolution and experimental 4× DLSS-G on an RTX 4090 Laptop. It adds features Heat does not expose natively, with Heat-specific loader, provider and scheduling fixes.

**Experimental prerelease — Windows x64, RTX 40-series reference path.** The release is a mod kit, not a self-contained NVIDIA runtime distribution. You must separately obtain the exact compatible runtime files listed in `runtime-requirements.json`. Source archives alone cannot supply those files. There is no guarantee of zero ghosting or 120 FPS on every road, GPU or game version.

## What this version does

- Movie style (`Model=3`, `Style=2`), **two actual NR evaluations per processed frame**.
- 1920×1200 neural working resolution, followed by DLSS SR to **3840×2400**.
- Three generated frames plus one processed real frame: **4× output**.
- NVIDIA hardware optical flow at 576×360 for the 16:10 reference profile.
- Separate reconstruction and FG queues, asynchronous presentation, and a source-pressure governor aware of the 4× multiplier.
- Startup ReShade injection; private NGX caller bridge and DriverStore core are exempted from OptiScaler's generic redirection.
- **Insert** opens the ReShade/AIO panel. **F8** opens the optional OptiScaler diagnostic panel. OptiScaler's own frame generation is explicitly off to avoid duplicate ownership.

## What it actually processes

```text
Heat 3D rendering + game HUD in the captured backbuffer
  -> downsample capture to 1920×1200
  -> NR Movie pass 1 -> NR Movie pass 2
  -> DLSS SR to 3840×2400
  -> private DLSS-G provider, 3 generated outputs + real output
  -> asynchronous presenter, reference target 120 Hz
```

This standalone route consumes captured frames and estimated optical flow. It **does not currently extract a reliable native HUDless scene, game depth or per-object motion vectors**. The HUD may be processed and interpolated together with the scene. It is not the native engine-integrated “SR → HUDless FG → fresh UI recomposition” pipeline, and is different from the [Motorsport UI fix](https://github.com/widmonstertony/forza-motorsport-dlssg-ui-fix).

The 1920×1200 neural input is a downsample of the captured output; it is not proof of a native 1920×1200 DLSS engine injection. Selecting 50% render scale in Heat reduces its 3D rendering workload independently. “4K output” means 3840×2400 reconstructed output on the tested 16:10 display, **not native-resolution shading**.

## Evidence and current limits

Reference setup: Steam Heat executable `1.0.60.7040`, RTX 4090 Laptop 16 GB, Windows 11, driver `621.1`, 3840×2400 / 120 Hz display, ReShade `6.8.0.2155`, local NVIDIA providers `310.9.16.0`.

The local session logs confirmed successful creation/evaluation of both NR passes, SR and FG, an active 4× presenter, and a 30-real-FPS governor target for the 120 Hz display. **Title/menu output telemetry was approximately 96–110 FPS** after warmup; these are not driving benchmark results. Neural reconstruction GPU time decreased from roughly 20 ms under uncapped source pressure to 12–14 ms after the governor activated.

Limitations still needing road testing include moving-car and wheel trails, HUD ghosting, grey/color shifts, focus changes, long-session stability and latency. Telemetry still showed variable frame intervals, occasional spikes and substantial queue latency (tens to over 100 ms in some samples). High output FPS does not mean low input latency. This release does not claim all of those problems are fixed. See [VALIDATION.md](docs/VALIDATION.md).

## Install

1. Exit Heat completely. Download the **`Heat-DLSS5-4x-v0.1.0-experimental-kit.zip`** asset from Releases and extract it.
2. Obtain the separately licensed NVIDIA NR, SR and FG runtimes plus add-on-enabled ReShade. Put them in your own runtime folder. The installer checks the tested SHA-256 hashes; an arbitrary newer DLL is not interchangeable. `nvngx_dlssg.dll` may be supplied instead of `nvngx_dlssg_standalone.dll` if its hash matches. Runtime links and requirements are in [DEPENDENCIES.md](docs/DEPENDENCIES.md).
3. Run `INSTALL.cmd`. Enter the folder containing `NeedForSpeedHeat.exe` and your runtime folder. If Windows denies access to the selected game directory, rerun as administrator.
4. In Heat select 3840×2400 output, 50% render scale and VSync off for the reference profile. Use **Solo** for testing. The mod does not change your desktop refresh rate, global NVIDIA settings or global NGX OTA policy.
5. Press **Insert**, select the standalone AIO add-on and inspect its status. ReShade can compile effects during first startup. Two NR passes and the private FG handshake should report success in the log.

PowerShell options:

```powershell
.\Install.ps1 -GameDir 'D:\Games\Need for Speed Heat' -RuntimeSource 'D:\MyRuntime' -ValidateOnly
.\Install.ps1 -GameDir 'D:\Games\Need for Speed Heat' -RuntimeSource 'D:\MyRuntime'
```

To configure the four reference game profile fields automatically, add `-ConfigureGameProfile`; use `-ProfilePath` if your Documents folder is redirected. This optional step backs up the profile. The default installation only writes inside the selected game directory.

Installation backs up replaced files and temporarily moves other root `.addon64`/`.asi` graphics add-ons into the backup, preventing duplicate pipelines. Existing ReShade/OptiScaler profiles are replaced by the supplied profile after backup. Additional injectors in `scripts` or other subfolders should be disabled separately. Do not mix this kit with the older FSR4/XeFG Heat bridge.

This profile is specifically 16:10 / 3840×2400. For a 3840×2160 display choose a matching 16:9 neural source/output in AIO and Heat; that configuration has not been validated here. The source governor targets approximately display refresh / 4 when active, so a 60 Hz display is not the tested setup. The governor does not make generated frames respond to new input.

## Restore

Exit Heat, run `UNINSTALL.cmd` and enter the same game folder. Restoration uses `Heat-DLSS5-4x.install.json` and the `_HeatDLSS5Backups` folder. Installed files are moved into a recovery folder and original files/add-ons are restored; backups remain recoverable. If a file or configured game profile changed after installation, restoration stops for review instead of overwriting those changes. The same procedure supports recovery from partial installation.

## Build and source

See [BUILD.md](docs/BUILD.md). The repository includes complete modified AIO source, the MIT midpoint/provider source used by that build, the Heat gate source, exact OptiScaler override files and a patch against a pinned OptiScaler commit. Upstream commit pins are in `source-pins.json`. SDK headers and upstream dependencies must be obtained under their own licenses.

`payload/` contains the compiled open-source mod components. No NVIDIA runtime/model, game executable, savegame, screenshot, private log, access token or ReShade binary is published. The small `dlss5_nvngx.dll` is our caller bridge; it is not an NVIDIA runtime DLL.

## Credits and licenses

This is an integration and modification of [DLSS5 ReShade AIO](https://github.com/kibblerz/DLSS5-Reshade-AIO) by kibblerz (Apache-2.0), [DLSS5-Feeder](https://github.com/jlrouzies-fr/DLSS5-Feeder) (MIT), OptiScaler (GPL-3.0), Universal MFG Unlocker 1.7.0 components by Michael Robles (MIT), Ultimate ASI Loader (MIT), MinHook, and ReShade interfaces. It does not claim authorship of their underlying neural models or rendering frameworks. Preserve the licenses and notices in `licenses/` and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Independent community project; not endorsed by NVIDIA, EA, Ghost Games, ReShade or OptiScaler. Avoid online/anti-cheat use; compatibility with online policies is unverified.

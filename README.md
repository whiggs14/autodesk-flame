# Autodesk Flame tools — Higgins Post

Native OFX plugins for Autodesk Flame that run AI models locally on the workstation.
No ComfyUI, no shared folders, no cloud.

> **21 Oct evening re-upload (all engine kits, same version numbers):** the engine refused every job on a Mac / Linux box without Matte LTX Native installed (`No module named 'ltx_matte'`). Re-download the kit and run its installer again - it only re-copies the engine files. If you would rather not re-download: in `engine/engine_server.py` under the engine folder, move the line `from ltx_matte import LTXMatteEngine` at the top of `_process` down to just above `_engine = LTXMatteEngine(`, then stop the engine (`pkill -f engine_server.py`).

> **22 Oct - jobs from files, no Flame needed (every engine kit, same version numbers, re-uploaded):** the engine takes `analyze_files` - an EXR sequence on disk plus a job a node made as the template for the settings - and `tools/aifx_queue.py` (installed next to the engine) queues it from any shell or script; the node collects the result through its Analysis Job field. See `tools/ANALYZE_FILES.md` in the engine folder.

> **23 Oct - path translation (every engine kit + Camera Track):** the Render Folder and the Analysis Job folder a node stores are now
> translated through Flame's own path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`, Flame Setup > Path Translation) on the
> machine the node runs on, so a setup saved on one workstation finds its renders and jobs on another. An optional `~/.aifx/path_map.json`
> adds rules of its own and a `<jobs>` token for the Render Folder - see `tools/PATH_MAP.md` next to the engine.

> **23 Oct evening re-upload (Background, Camera Track, Depth, Face UV, Matte LTX, Motion Vectors, Upscale - same version numbers):** the installers no longer run
> `curl https://astral.sh/uv/install.sh | sh`. They download uv 0.13.5 as a pinned release from github.com/astral-sh/uv, check it against its
> published SHA-256 and keep it inside the engine folder (`bin/uv`). The Python packages are pinned to the versions the kits were tested with
> (torch 2.14.1, torchvision 0.29.1, transformers 5.14.1, diffusers 0.41.0, ...; on Linux the CUDA wheel index follows the driver: cu130 on 580+, cu126 below).
> Engine: every checkpoint is loaded with `torch.load(weights_only=True)` and SeedVR2's config `eval` resolver only does arithmetic.
> Nothing changes for an existing install - re-download only if you are installing fresh.

> **24 Oct - setup file (every engine kit + Camera Track):** Flame menu **Python > Higgins Post > Setup...** sets a Render Root for the
> machine; every node whose Render Folder is left at its default renders there, and a read-only **Renders To** line under Render Folder
> shows where a run lands and why. The Render Folder stays a per-node override, so setups move between machines. Path translation
> follows Flame's own table (shown in the dialog). File: `~/.aifx/setup.json`; `tools/SETUP.md` next to the engine.

> **26 Oct - Render Monitor + optional cloud rendering (every engine kit + Camera Track):** a Flame-style progress window now opens
> by itself with every render (collect, upload, render, result) with a Stop Render button; collect is ~10x faster; every node's last
> tab is Setup (Render Location + Duplicates + Diagnostics). The Setup dialog's **Render Root takes tokens** - `<project>` `<shot>`
> `<batch>` `<clip>` `<user>` - so `/projects/<project>/shots/<shot>/ml/output/video` lands every render in its shot folder.
> **Cloud rendering is optional:** Python > Higgins Post > Setup... >
> Render Backend > Cloud sends the heavy nodes to a GPU on Runpod (serverless, billed per second, or a pod) or to an Azure VM;
> `tools/RUNPOD_SETUP.md` next to the engine walks through the Runpod setup step by step. Local rendering stays the default and
> needs nothing new. Linux installers gained an unattended worker mode (`AIFX_WORKER=1`) and the numpy/OpenCV pin. Older kits:
> `FlameHooks-Hotfix-1.3.zip` installs the hooks (Setup dialog, Render Monitor) on their own.

> **30 Oct - per-node rendering routes, LAN rendering, offline engine (every engine kit + Camera Track); Denoise 0.4, Camera Track 0.3
> (first Linux kit), Lens Blur 0.9.11, UV Wrap 0.3.2; two new nodes - Optics Native and Screen Comp Native:** Python > Higgins Post >
> Setup... has one **Local / LAN / Cloud** choice per node. **LAN rendering** sends a node's jobs to another Mac or Linux machine that
> has the engine installed - nothing is uploaded, the job folder lives on a shared disk, workers are found by themselves (Bonjour) and
> several make a pool (`tools/CLOUD.md`, section "LAN rendering"). The engine runs **offline** (no library may download at run time;
> first-use model downloads are pinned to a SHA-256). The auto-refresh hook no longer reloads a node's setup while Flame renders it
> (a Flame 2027.2 crash). A kit installed on its own, without Matte LTX Native, could stall every render since the 26 Oct kits
> ("No module named cloud") - fixed. Older kits: `FlameHooks-Hotfix-1.4.zip` installs the current hooks on their own.

> **31 Oct - every kit updated after a full code audit; Check for Updates in Setup:** **Python > Higgins Post > Check for
> Updates...** (also a button in Setup) lists every kit with the version on this machine and the latest release, and installs
> what you tick. **Anamorphic plates** work across the nodes (sizes in square pixels, engine frames desqueezed and mapped back).
> Engine: **models stay loaded between jobs**, LAN workers only read and write their own folders unless you allow others, and a
> round of fixes (Cancel stops every task, a crafted FLAME .pkl could run code, LAN request limits...). In the nodes: Lens Blur's
> ray-traced **Lens Model**, Colour Match / Paint Carry / Face UV's wrap **on the GPU**, Regrain's **shared grain profiles**,
> Denoise's Ghost Guard fix for big moving foregrounds. Installers restart the engine only when it is idle. Older kits:
> `FlameHooks-Hotfix-1.5.zip` installs the current hooks on their own (the 1.3 / 1.4 Mac installer only replaced two of them).

## Install or update everything in one go

**macOS:** download [`Higgins Post Updater.command`](../../raw/main/Higgins%20Post%20Updater.command), double-click it (right-click > Open the first time). It asks GitHub for the latest release of every plugin, shows what you have against what is published, and installs or updates what you pick - each plugin's own installer runs, so the shared engine and models are handled the same way as a manual install.

**Linux (and macOS from a terminal):**
```
curl -fsSL https://raw.githubusercontent.com/whiggs14/autodesk-flame/main/hp-update.sh -o hp-update.sh
bash hp-update.sh              # interactive menu
bash hp-update.sh --check      # just the table
bash hp-update.sh --all --yes  # install / update everything, answering the installers' prompts with their defaults
bash hp-update.sh --only lensblur,faceuv
bash hp-update.sh --uninstall lensblur,faceuv     # or: --uninstall all [--purge]   (--purge also deletes the shared engine and the models)
```
Run it again whenever you like: it only downloads what is newer than what you have. Restart Flame afterwards.

## Matte LTX Native

Pulls a soft, hair-detailed matte from a plate with Lightricks' **LTX-2.5 Alpha Gen** model.
Optional selection: draw a box around one person and/or type what to keep
("hands, pants, green bag") — body parts and clothing go to Meta's Sapiens2, anything else to Meta's SAM3.
Crop (ROI) mattes only a travelling window around the subject (from a matte or the selection box) for ~3x faster
runs on small subjects, and a built-in Track Box tracker drives that box without keyframes.
**Motion Detail** (x2 / x4 / x8 / Auto) repeats frames inside LTX's 8-frame latents so fast motion keeps its matte
and its motion blur; Auto picks the repeat per frame from a quick motion analysis and only spends the time on fast frames.

**0.9.14:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.9.13:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.9.12:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.9.11:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.9.10:** Output group on the first tab, Render Location on Setup (tab layout fix); **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.9.9:** **Free Engine Memory** button + automatic release after a render; linear plates no longer clipped.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `MatteLTXNative-Tester-0.9.14.zip` | Apple Silicon Mac, 128 GB recommended (64 GB minimum), Flame 2026/2027 |
| Linux | `MatteLTXNative-Linux-0.9.14.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB+ VRAM (60 GB+ runs fully on the GPU), Flame 2027 |

Each zip contains the plugin, the Python engine and an installer; the installer downloads the models
(~56 GB) under your own Hugging Face account. Read `Read Me First.txt` / `README.txt` inside the zip.

The kit also installs a small Flame Python hook (`aifx_autorefresh.py`): Flame only re-renders an OFX node when a
parameter changes, so without it the viewer keeps showing the pass-through until Refresh Status is pressed; the hook
notices when the engine has finished and nudges the node, so the stored result appears on its own. Restart Flame
once after installing. (Shared by all the engine-backed nodes here.)

> **Hooks hotfix 1.2** — the aifx auto-refresh hook now makes at most two refresh passes per finished job (20 s apart)
> and the nodes say "Refresh Status to check" while a job runs, so the hook no longer keeps resetting the Media Panel
> selection (clips deselecting themselves on the Desktop / in a Library). Every kit on this page from today's versions on
> includes it; for older kits install `FlameHooks-Hotfix-1.3.zip` from the Releases page (Mac and Linux, one zip).

All the engine-backed nodes share a few things as of the current kits:
- **Follow Duplicates** (Render Location): an on/off button, off by default. Turn it on, duplicate the node and set each
  copy's Output to another pass (matte, normals, gain map…): press Generate on any copy and the others show the new result
  when it is done. One compute, as many passes as you want. Only results made from the same plate are followed (the engine
  compares the plates), so a copy moved onto another clip keeps its own. It replaces the Link Key text field; setups saved
  with a key keep working.
- **Output colour tags**: each node answers OpenFX 1.5's `GetOutputColourspace`, so Flame 2027 tags the output clip
  with what the pass is — colour passes carry the Front's colour space, data passes (mattes, depth, normals, UV, gain
  map) are `Raw`, HDR Native reports Linear Rec.709 or ACEScg. No view transform on data, no guessing downstream.
- Results appear in the viewer by themselves when the engine finishes (the `aifx_autorefresh` hook), and the hook
  leaves Flame alone otherwise.
- **Gemma text encoder**: Matte LTX Native leaves out the 26 GB Gemma-4 prompt encoder (it never needs a prompt). The
  nodes that send LTX a prompt — Element, Background (Moving mode), Relight, Object Removal — download it in their own
  installers from the current kits on (it was missing before: their first render stopped).
- **natten**: the LTX engine log used to suggest installing natten. Don't: it is NVIDIA-only (on a Mac it breaks every LTX
  render) and on Linux it is pinned to a PyTorch / CUDA build that can replace the engine's own. The current engine log
  says so instead.
- **Node icons**: every node shows its Higgins Post tile in the node bin and schematic (on macOS from the current kits:
  earlier kits installed the icon readable by root only, so Flame could not load it). Those releases also carry the current shared engine server and hooks, so
  installing any kit after another never rolls the shared engine back.

### Models and licences
The plugin downloads models that carry their own terms — check they fit your use, especially paid client work:
- LTX-2.5 and the Alpha Gen IC-LoRA — Lightricks LTX-2 Community License (free below the revenue threshold stated in the licence).
- SAM3 — Meta's SAM licence.
- Sapiens2 — Meta's Sapiens2 licence (royalty-free; no surveillance, biometric ID, deepfakes or military use).

## Upscale Native

Video upscale / restoration with ByteDance's **SeedVR2** (3B, 7B and 7B Sharp models).
Flame cannot change a node's resolution, so: Resize the plate to the final size, set Factor to match
(2x, 3x, 4x) and the node regenerates it with SeedVR2; Factor 1x restores at the plate's own size.
Input Colour is read from the clip's colour-space tag automatically on Flame 2026.1+ (S-Log3, ARRI LogC3/LogC4,
scene-linear) so log plates are converted for the model and back.

**0.5.5:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle. Scene-linear plates are no longer clipped at 1.0.

**0.5.4:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.5.3:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.5.2:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.5.1:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.5.0:** **Free Engine Memory** button + automatic release after a render.

**0.4.9:** engine only - pressing Upscale again while a run is going restarts it with the new frames (the old run no longer finishes into the new job); status from the first second instead of Queued 0% for minutes.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `UpscaleNative-Tester-0.5.5.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for the 7B models), Flame 2026/2027 |
| Linux | `UpscaleNative-Linux-0.5.5.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB+ for 7B), Flame 2027 |

The installer downloads SeedVR2 3B + VAE (7 GB; the 7B models are optional, 16.5 GB each) — Apache-2.0, no
Hugging Face account needed. If Matte LTX Native is installed, Upscale Native shares its engine folder and
Python environment.

### Models and licences
- SeedVR2 weights — ByteDance Seed, Apache-2.0 (packaged by numz/SeedVR2_comfyUI); inference code vendored
  from ComfyUI-SeedVR2_VideoUpscaler (Apache-2.0).

## Depth Native

Depth maps with ByteDance Seed's **Depth Anything 3** (Large: best edges and geometry, relative depth, frames processed in
overlapping windows so a shot hangs together; Metric: the same in real-world metres) or **Video Depth Anything Small**
(fast, flicker-free; also the one-click Preview). Press Analyze once — the depth is stored with the node and renders
instantly, with live Auto Range / Near / Far / Gamma / Invert. A flow-guided Stabilize filter removes the shimmer DA3
leaves between windows. Input Colour is read from the clip's colour-space tag on Flame 2026.1+. Built to feed
Lens Blur Native's Input3, but it is a plain grey depth pass (near = black) you can use anywhere.
DA3 Metric depth comes out in real metres (scaled by the field of view DA3-Large estimates), and Output: Raw Depth feeds
Lens Blur Native's Physical Camera.

**0.3.4:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.3.3:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.3.2:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.3.1:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.3.0:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.2.9:** **Free Engine Memory** button + automatic release after a render; linear plates no longer clipped.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `DepthNative-Tester-0.3.4.zip` | Apple Silicon Mac, 16 GB minimum (32 GB recommended), Flame 2026/2027 |
| Linux | `DepthNative-Linux-0.3.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 8 GB+ VRAM (16 GB for DA3 at 1008 px), Flame 2027 |

The installer downloads DA3 Large (1.6 GB) and Video Depth Anything Small (0.1 GB); DA3 Metric (1.3 GB) is optional —
all Apache-2.0, no Hugging Face account needed. Shares the engine folder with Matte LTX Native / Upscale Native if present.

### Models and licences
- Depth Anything 3 (code, Large and Metric weights) — ByteDance Seed, Apache-2.0.
- Video Depth Anything (code and Small weights) — Apache-2.0. (The Large weights are CC BY-NC 4.0 and are not part of
  the public build.)

## Background Native

Generates a background or clean plate inside a matte: plate in, matte (white = the area to build) on the Matte socket (or
nothing / all white = generate the entire picture),
an optional reference image and a prompt, press Generate — the result is stored with the node and composited over the
plate. Local engines: Alibaba's **Qwen-Image-Edit-2511** with the Lightning 8-step LoRA (best quality) or Black Forest
Labs' **FLUX.2 Klein 4B** (lighter, faster). Cloud engine: Google's **Nano Banana Pro**, using your own Google API key
(the installer asks for it, or add it to the engine's `settings.json` afterwards — the Read Me explains how; nothing
leaves the workstation unless that engine is selected). Moving mode propagates the still through a shot with LTX
in/outpainting when Matte LTX Native is installed alongside. Variations, seed, reference strength, Matte Area
(chroma screen / paint grey), Input Colour from the clip's colour-space tag on Flame 2026.1+.

**0.3.4:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.3.3:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.3.2:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.3.1:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.3.0:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.2.9:** **Free Engine Memory** button + automatic release after a render; ACEScg / linear plates no longer clipped.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `BackgroundNative-Tester-0.3.4.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for Qwen-Image-Edit), Flame 2026/2027 |
| Linux | `BackgroundNative-Linux-0.3.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB for Qwen-Image-Edit), Flame 2027 |

The installer downloads the local model(s) you choose — Qwen-Image-Edit-2511 + Lightning (55 GB) and/or FLUX.2 Klein 4B
(15 GB), both Apache-2.0, no Hugging Face account needed — and offers the gated LTX In/Outpainting IC-LoRA for Moving
mode when a Matte LTX Native engine is present, together with the Gemma-4 12B text encoder (26 GB) Moving mode needs for
its prompt. Shares the engine folder with the other Higgins Post plugins.

### Models and licences
- Qwen-Image-Edit-2511 — Alibaba Qwen, Apache-2.0; Lightning 8-step LoRA — lightx2v, Apache-2.0.
- FLUX.2 Klein 4B — Black Forest Labs, Apache-2.0.
- LTX In/Outpainting IC-LoRA (Moving mode, optional) — Lightricks LTX-2 Community License.
- Nano Banana Pro — Google's Gemini API terms apply to your own account; images are generated on Google's servers.

## Element Native

Generates a stock element — smoke, steam, dust, fog, rain, snow, embers, sparks, fire, birds, leaves, bubbles, or
anything you describe — with Lightricks' **LTX-2.5** (text-to-video on black), keys it off its black background and
places it inside a matte on the plate: draw a matte where the element should live (it can move), pick a preset, add to
the prompt, press Generate. The node stores the element with its own alpha and outputs it premultiplied + alpha for your
own comp, or a quick Over / Screen / Add in place. Fit to matte (stretch / inside / cover), plate colour match, fade at
the matte edge, luminance key with threshold / softness / grow, Input Colour from the clip's tag on Flame 2026.1+.

**0.4.6:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.4.5:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.4.4:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.4.3:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.4.2:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.4.1:** **Free Engine Memory** button + automatic release after a render; linear plates no longer clipped.

**0.4:** **Motion** controls - Wind Direction / Strength, Turbulence, Vortex, Density, Speed, Detail Scale, Lighting - with a draggable wind icon in the viewer; a full-frame white matte is accepted; the comp is done in linear light.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ElementNative-Tester-0.4.6.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2027, **Matte LTX Native 0.8+ installed** |
| Linux | `ElementNative-Linux-0.4.6.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

It uses the LTX-2.5 model and Python engine that Matte LTX Native installs, plus the **Gemma-4 12B text encoder** (26 GB,
from the same gated Lightricks/LTX-2.5 repository) that LTX needs for the prompt — Matte LTX Native does not install it, so
the installer downloads it under your login or links a copy you already have. It also adds the Element engine files and
the plugin, and updates the Flame hooks.

### Models and licences
- LTX-2.5 — Lightricks LTX-2 Community License (installed by Matte LTX Native under your own Hugging Face account).

## HDR Native

SDR to HDR: reconstructs the highlights an SDR plate clipped — sun, practicals, windows, chrome, flames — with Lightricks'
**LTX-2.5 SDR-To-HDR IC-LoRA** (the reference `HDRICLoraPipeline`: distilled 8 steps, seam keyframes, keyframe-aware
DiffVAE decode), and outputs scene-linear **Rec.709 or ACEScg**, tagged for Flame. The model's HDR becomes a per-channel
gain map against the SDR at the working resolution and is multiplied into the full-resolution plate, so the plate keeps
all its detail; mid-tones are normalised so the plate's exposure is untouched. **Range = Highlights only** (default) applies
the gain above a chosen SDR level and never darkens; Whole image gives the model's full tonal re-interpretation. Highlight
Start, HDR Strength and Range are live; Gain map and SDR-linearised outputs for checking. A matte on the Front limits where
it applies. Optional **Depth**, **Normals** and **Hero Matte** passes (Depth Anything 3, LTX Alpha Gen) come out of the same
Generate as extra Output choices — with Follow Duplicates, one compute feeds an HDR / depth / normals / matte set of nodes.

**0.3.4:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle. The Depth / Normals / Hero Matte outputs work (they never loaded the job); log plates are linearised first.

**0.3.3:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.3.2:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.3.1:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.3.0:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.2.9:** **Free Engine Memory** button + automatic release after a render; linear plates no longer clipped.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `HDRNative-Tester-0.3.4.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2027, **Matte LTX Native 0.8+ installed** |
| Linux | `HDRNative-Linux-0.3.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

Uses the LTX-2.5 model and Python engine that Matte LTX Native installs, plus a 1.3 GB LoRA that is gated on Hugging Face:
accept the licence on the model page, and the installer downloads it under your login.

### Models and licences
- LTX-2.5 and the SDR-To-HDR IC-LoRA — Lightricks LTX-2 Community License (gated; accepted under your own account).

## Colour Match Native

Matches one clip's colour to another — black / white point, tone (luminance curve), contrast and colour
statistics — in pure C++ inside Flame, no models to download. Stages with their own amounts: Levels, Tone (the Front's luminance
distribution remapped onto the Reference's), Covariance (Monge-Kantorovich transform fitted in a YCbCr basis, so it
matches means and channel relationships without rotating hues) and **Distribution (3D)**, which moves the whole colour
distribution onto the Reference's through a smoothed 33³ grid. Up to 12 frames of each clip are pooled so the match holds over a shot, or the match follows the
current frame; Reference Frame locks the reference to one frame, and **Anchor** mode makes a still or paint that already
matches the plate at that frame follow the plate's lighting over the shot. The Front's matte limits where it is measured
and applied; Input Colour follows the clip's colour-space tag on Flame 2026.1+. The transform is deterministic,
keyframeable and exports as a 33³ `.cube` LUT.

**0.6:** **on the GPU** (Metal / Vulkan: UHD ~20 ms, with Selectives 21-31 ms), the Tone stage no longer blows up the chroma near black, code-audit fixes (a NaN crash on Linux, Selectives with keyframes / AI Look, the covariance gain capped, Export LUT at the current frame), anamorphic Selectives.

**0.5:** **Distribution (3D)** match, **Selectives** (up to five Front / Reference box pairs in the viewer whose matches blend across the frame - match a part of the element to the part of the plate it will sit over, then move it downstream), shadows / mids / highlights amounts with Protect Skin, Output views (Reference, Compare wipes, Difference, Match Error), Match Keyframes along the shot, a 3-frame AI Look, and a fix for Tone double-correcting after Covariance / Levels.

Optional **AI Look** target: when the Higgins Post engine from Background Native (Qwen-Image-Edit-2511 + Lightning)
is installed, the engine recolours the analysis frame once and the plugin measures that instead of the Reference — for
references of a different scene. The installer offers to download the colour-grade-transfer LoRA (236 MB). Without an
engine the plugin works fully on Reference statistics.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ColourMatchNative-Tester-0.6.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `ColourMatchNative-Linux-0.6.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

### Models and licences (AI Look only)
- Qwen-Image-Edit-2511 and Qwen-Image-Lightning — Apache-2.0 (installed by Background Native).
- QIE-2511-Color-Grade-Transfer-LoRA — ovi054 / piczify.com; no licence stated on the model page, check with the
  author before commercial use. Not bundled; the installer downloads it on request.

## Additive Key Native

An additive keyer in the spirit of the crok_additive_key Matchbox, re-implemented in C++ with more control.
Instead of punching a hole and comping, it adds the background back into the edges, hair and transparency where
the despill removed the screen colour. Inputs: **Front** (the original screen plate, its matte socket = the key
matte), **FG Despilled**, **Back** (its matte socket = optional holdout, so a core matte stops the FG being punched
through in the darks). Two methods — Spill Difference (luminance / max / green / blue difference matte with levels,
gamma, gain, blur, clamp and an edge-only limit; background prep with blur, saturation, gamma, gain, offset, tint +
tint mix; Add / Screen / Lighten with RGB gain and mix) and Pixel Spread (screen colour estimated by spreading the
matte outside inwards, subtracted, with global / darks / highlights restore). Output modes for the comp, the additive
FG on its own, the added layer, the spill matte and the processed Back. No models, no engine; runs on the GPU (Metal on the
Mac, Vulkan on Linux; Use GPU checkbox), else all CPU cores. New in 0.5: **Working Space** (S-Log3 / LogC3 / LogC4 / ACEScct — the add
is done in linear), **Add Beyond the Matte** (unmixes soft and defocused edges against the Background; with a despill it
clears the light despilled-screen line on blue / green screen) and **Screen Sample Inset** for Pixel Spread.

**0.7.2:** an unreadable Front left the output unwritten - fixed; Beyond sizes right at proxy; anamorphic plates; the CPU prep runs outside the GPU lock.

**0.7.1:** **Light-Limited Matte** (the add is capped by the light the Front has, black floor read from the picture - no hard black rims), **Unmix Strength**, Matte Output **Key (light-limited)**, hard input ranges, scene-linear negatives handled.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `AdditiveKeyNative-Tester-0.7.2.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `AdditiveKeyNative-Linux-0.7.2.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Lens Blur Native

Depth-of-field / lens defocus with real bokeh, native inside Flame, no engine. The depth layers and their FFT convolutions run on the GPU (Metal on the Mac,
Vulkan on Linux with the NVIDIA driver; Use GPU checkbox), about 4x faster than the CPU path, so it scrubs at half res;
without a usable GPU it runs on all CPU cores. Feed it
a Z depth from Depth Native or any depth pass. The image is split into depth layers by circle of confusion, each layer
is convolved with the iris at its own radius and the layers are accumulated near to far, so out-of-focus foreground
spills over the background and sharp foreground occludes what is behind it; highlights are boosted before the blur so
out-of-focus point lights bloom into iris-shaped discs (in-focus highlights stay as the plate). Iris: blades, rounding, angle, anamorphic aspect, soft edge, bright rim,
centre darkening, or your own aperture image, with presets (and Star / Heart). Chroma Warp adds longitudinal and
lateral colour fringing. Focal Distance animates for rack focus, Pick Focal Distance reads it off the Z under
the Pick Point (a cyan crosshair you drag in the viewer), Focus Follows Pick Point tracks the depth under an animated point
for a rack focus, or Lock Focus Depth holds the distance under the crosshair for the whole shot through a camera move; Show > Depth / Focus Overlay draw the focal plane as a green line through the shot (yellow lines mark
the DOF band; Focus Line Width sets their thickness). Two-plate comp: Front + matte at its Z
over a Background at its own Z, defocused together as one scene. The Front matte is a Flame-style blur mask by default (white = defocus,
black = untouched — the matte itself defocuses with the picture, and with a Background connected the element is comped over
it premultiplied), or the foreground alpha for the comp, or — with no Z at all — the blur amount itself (white = full Radius,
for painted ramps and tilt-shift). Inputs: **Front** (+ matte), **Back** (Background),
**Input3** Z Depth, **Input4** Back Z Depth, **Input5** Iris image. An input shorter than the plate (a one-frame Z, a still
iris image) is held on every frame.
**Physical Camera** mode turns a metric Z (Depth Native, DA3 Metric, Output: Raw Depth) into a real lens — sensor, focal
length, f-stop and focus distance in metres on a Camera tab, with Analyze Camera to estimate the field of view and optional
focus breathing. A Focus Pull tab keys a rack focus between two picked points, Refine Z to Plate snaps a low-res Z onto the
picture's edges, and out-of-focus foreground edges stay soft over a sharp background.

**0.9.12:** **Lens Model page - a ray-traced lens**: real rays through a lens prescription (Double Gauss, wide, tele, fisheye or your own PBRT `.dat`) scaled to the Camera page's focal length - cat's eye from the glass, coma / astigmatism towards the corners, bright-rim far bokeh and soft near bokeh, dispersion fringes; Optical Errors, Front Filter (dirt, scratches, rain, shimmer), Hood. Faster FFT path (HD GPU 89 -> 56 ms), anamorphic plates (round bokeh after the desqueeze), proxy = full res, code-audit fixes.

**0.9.11:** iris presets of the named lenses from published specs (Cooke S4/i 8 leaves, Master Prime 9 and round at every stop, Ultra Prime 9, Super Speed 7, K-35 15, Summilux-C 10, Petzval round plates, Hawk 1.3x squeeze 0.77...) - the same values as Optics Native; **Linux kit** of the Inpaint Behind Matte build.

**0.9.10:** **Inpaint Behind Matte** - the plate behind a matted element is filled (Push-Pull / Diffusion / Texture, Inpaint Grow) before the defocus, so no sharp halo along the foreground edge; Focus & Inpaint on one tab.

**0.9.9:** 17 **named lens presets** in the Iris menu - Cooke S4 / Speed Panchro, Zeiss Super Speed / Master Prime / Ultra Prime, Canon K-35, Leica Summilux-C, Panavision Primo / C-series / E-series, Lomo-Kowa, Hawk V-Lite, Helios 44-2, Petzval, Meyer Trioplan, a catadioptric and a modern zoom - each setting the iris, cat's eye and chromatic aberration together.

**0.9.8:** **Input Colour** - log plates (Auto from Flame's tag, S-Log3, LogC3/4, ACEScct) are defocused in linear light, so highlights bloom into proper bokeh.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `LensBlurNative-Tester-0.9.12.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `LensBlurNative-Linux-0.9.12.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Denoise Native

Motion-compensated video denoise inside Flame, on the GPU (**Metal** on the Mac, **Vulkan** on Linux; about 0.12 s per 4K
frame on an M2 Ultra, ~10x the CPU path, so it scrubs in the viewer) or on all CPU cores - no engine. Neighbour frames stay
on the GPU between renders, so scrubbing or changing a slider re-uses them.
It measures the plate's noise per channel, detail size and brightness (on every frame, or once with **Analyze Noise**),
aligns the neighbour frames by motion - refined at every pixel so hair strands and edges line up - and averages them in
where they truly match. **Ghost Guard** rejects slightly misaligned neighbours, so moving people, hair and hands stay
crisp with no soft double edges. What is left is removed per detail size, gently on brightness shading and harder on
colour noise; **Strand Detail** smooths along hair, lashes and wires (never across them) and **Recover Detail** puts back
softened texture. **Noise Level (%)** shifts the whole profile in one move. Also: noise-gated sharpen, Mix Original,
global or zoned **Deflicker**, inside / outside the Front matte, and QC views (Compare wipe, Removed Noise, Detail Loss,
Temporal Coverage, Measure Sharpness). Input: **Front** (the plate).

**0.4.2:** **colour kept** - the colour-noise filter took a little real colour along bright / dark edges (warm highlights lost 1-2% of their saturation, blonde hair came out less yellow); now only noise leaves. **Less mid-size grain** - the block filter no longer groups a block with its own 1-2 px shifted copies, so flat areas keep Neat's level of 2-8 px noise or less, as finer grain; Fine Keep rebalanced so hair and skin texture hold (existing setups get it as is).

**0.4.1:** **Ghost Guard fix** - on shots where a large part of the frame moves (a foreground head or body) it switched itself off and a faint copy of the moving edge was averaged in; it is now judged against the median (static shots unchanged). Renders from several threads run at once.

**0.4:** **hair, fabric and fine texture kept** - Normal quality is two stages of grouped 8x8 block filtering on the luma (hard-threshold pilot, then an empirical Wiener on the same groups) instead of a wavelet shrink that flattened faint strands; the temporal pass no longer fits the noise (15x15 patch match, Per-Pixel Motion off by default); the temporal result is profiled too so Recover / Strand Detail stop putting mottle back; Fine Keep, a structure map, a line test in the strand gate; the Fine / Medium / Coarse / Luma strengths work in Normal quality (they were dead). Measured against Neat Video on a 4K S-Log3 plate: less noise left at every scale with the hair's curls kept. Fixes: half-float input, hosts that prefetch frames, a cache that could keep an old picture, NaN pixels, a profile seen half-updated by a render, the GPU cache never released, Analyze of a long shot without feedback (now a progress bar), GPU out-of-memory faulting instead of falling back; Linux kernels fixed. Speed: GPU busy ~205 -> ~135 ms per UHD frame. Analyze no longer sets sharpening (older setups: set Sharpen Fine / Medium to 0 if highlights show pixel hits). *(Mac zip re-uploaded 30 Oct evening: the first upload fell back to the CPU inside Flame - a GPU kernel Flame's Metal compiler refuses - so scrubbing was slow. Re-download if you installed it earlier.)*

**0.3.1:** the noise profile's sensor curve is a real sensor model now (no term can go negative): whole-frame profiles on log plates no longer under-read the mid-tones by 2-3x, which left grain on walls and shadows. Press Analyze Noise again on saved profiles.

**0.3:** Analyze Noise with a resizable, auto-rated Sample Box and keyframed profiles along the shot, a Profile Library, Spatial settings auto-populated from the analysis (Noise Map), Sharpen, Dead Pixels, cut / duplicate skip, Input Colour (log plates denoised in linear light), and **Matte Output = Grain profile for Regrain** - wire the blue matte out to Regrain Native's blue Grain Profile input and the grain that goes back on is the noise that came off.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `DenoiseNative-Tester-0.4.2.zip` | Apple Silicon Mac, Flame 2026/2027 (GPU: Metal) |
| Linux | `DenoiseNative-Linux-0.4.2.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 (GPU: NVIDIA driver with Vulkan; CPU otherwise) |

## Optics Native

Lens light in scene-linear, native inside Flame (Metal on the Mac with Use GPU, all CPU cores otherwise - no engine). **Glow**
with a core / mid / halo profile and per-channel spread (drag the profile graph in the viewer), **glare**, **film halation**,
**light wrap** (the plate onto the element's edge), **spill** (the element onto the plate), coherent **flicker / shimmer**,
**glints and streaks** from the lens's iris (the same named-lens presets as Lens Blur Native, with Rounded), Z depth and
lens dirt. Front (+ matte) = the element, Back = the plate; **Apply To** Front / Back / Both makes the comp. Pick Threshold
then click a light to set where the glow starts; Match Light / Match Position fit it to a reference. First tester build.


**0.1.1:** Match Lens during a render could crash - fixed; render races fixed; anamorphic plates (glows round after the desqueeze).

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `OpticsNative-Tester-0.1.1.zip` | Apple Silicon Mac, Flame 2026/2027 (GPU: Metal) |
| Linux | `OpticsNative-Linux-0.1.1.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 (CPU) |

## Screen Comp Native

Screen replacement inside Flame (Metal on the Mac with Use GPU, all CPU cores otherwise - no engine). Front = the plate (its
matte = hands, a mug - whatever is in front of the screen), Back = the content, Input3 = an optional reflection plate.
**Corner Pin** in the node (drag the four corners and the bezel in the viewer, or load the corners a Camera Track Native
card / points export wrote) or **Tracked in Action** (the Back already placed by Action, its matte = the screen). Display
models **LCD / OLED / CRT / LED Wall / Phone**: the pixel structure and the moire come out of the sampling (RGB stripe,
PenTile, aperture grille, shadow mask), backlight falloff and viewing angle, scanlines, curvature, bloom, rolling bar,
flicker, chroma bleed, noise, shutter motion blur. Glass: reflection with Fresnel and smudges, Keep Plate Glass / Grain,
light spill on the bezel and desk, **defocus with a tilt** (Measure Plate Focus reads it off the plate's edges), bezel,
corner radius, Power On / Off looks by era, Trim Content Bars. Outputs: Result / Screen Layer / Screen Matte / ST Map /
Emission Only. First tester build.


**0.1.1:** fixes (dragging after Load Corners, an unreadable Front, point-track bounds, a degenerate Metal projection); the CPU blurs 3-8x faster on Linux; anamorphic plates.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ScreenCompNative-Tester-0.1.1.zip` | Apple Silicon Mac, Flame 2026/2027 (GPU: Metal) |
| Linux | `ScreenCompNative-Linux-0.1.1.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 (CPU) |

## Regrain Native

Puts the plate's grain back on a comp — the job of Flame's Match Grain and Nuke's DasGrain — native inside Flame, no engine:
on the GPU (Metal on the Mac, Vulkan on Linux; Use GPU checkbox), else all CPU cores. Connect the comp, the degrained plate and the original plate and press **Analyze**: it measures the
grain's strength per channel across the brightness range (RGB response curves, drawn in the viewer, with points you can
drag). Where the comp is unchanged the plate's own grain comes back exactly; where it changed (paint, CG, set extensions,
removals — found automatically, from a matte, or both) new grain is built from the plate's own grain in a **Sample Box**
(Voronoi cells re-shuffled every frame, draggable in the viewer) and matched to the comp's brightness, so nothing of what
was removed shows through. Modes for plate grain only or new grain everywhere; grain size, softness and gain per channel.
**Grain profiles** save the curves, settings and the grain itself to reuse on CG, clean plates or other shots (drop-down,
Previous / Next, delete with a week to undo), in a folder every machine can share (Python > Higgins Post > Setup... > Grain Profiles). QC views: the grain on grey, the changed-area key, and result vs original x10.
Inputs: **Front** (comp), **Back** (Degrained), **Input3** Original, **Input4** Matte, **Input5** Grain from another Regrain.

**0.4:** **shared grain profiles** (Setup > Grain Profiles: a folder every Flame / Burn machine sees; setups find their profile by name), the Profile menu shows the profile in use after a restart, highlights follow the sensor's noise curve (they were up to +58% too strong), Scale / Blur / Soften fixes (a true Gaussian - setups with Blur or Soften change slightly), Fix Curve Spikes fixes colour points, half-float input, atomic saves, an Analyze progress bar.

**0.3:** blue **Grain Profile** input for Denoise Native's matte output (Analyze takes the curves from it); newly saved profiles show in the Profile menu without a restart.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `RegrainNative-Tester-0.4.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `RegrainNative-Linux-0.4.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Camera Track Native

A 3D camera tracker for Flame, running locally: Depth Anything 3 initialises the solve, feature tracks are bundle-adjusted
on the GPU (camera path, 3D points, focal length and lens distortion), movers are held out (a Front matte and / or SAM3
finding people and cars itself). **Solve Mode** Auto / 3D / Tripod — a pan is solved as a rotation-only camera when that
fits better. **Consistent Depth** fuses each frame's depth with its neighbours through the solved cameras, so the depth
stops shimmering. Points (check) shows every point coloured by error with trails, **Residual Arrows**, box / click select,
Select Worst (%), Delete / Re-solve Without; the Error Graph carries the numbers. **Set Ground** / Set X Axis / Set Origin
line the scene up with the set; **cards** and **surfaces** (a thin-plate spline through chosen points) get Flame-style
ring gizmos for tilt / roll / spin / offset. **Projection** puts paint done on one frame back on every frame through the
depth, a card or the whole set, with occlusion — from up to three paint frames, morphing between them with an optical
flow over a Blend Width. **Stabilize** to a point, a card or the camera's rotation and **Unstabilize** the paint back.
Lens & Scale: solved or typed distortion, Undistort / Redistort and ST maps, Lens Grid check, **lens presets** per
focal + sensor, scale from a measured distance. Outputs: depth (near..far and metric metres, for Lens Blur Native's
Physical Camera), world position, normals, the 3D Scene viewer with a dense cloud. Export: **FBX** camera + points +
cards straight into an Action in the Batch, **GMask Tracer** from points (axis / shape / both), a **corner pin** from a
card. Engine jobs can be queued from EXR sequences on disk (`tools/aifx_queue.py`).

**0.3.1:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.3:** **first Linux kit.** **Lens library** (Lens Name, Save / Load Lens Preset, **Lock Lens on Solve** - focal and distortion fixed through every adjustment: solve the lens on a shot with a move, lock it on the pans), **Read Clip Metadata** (focal, sensor, focus from the plate clip, done by itself on a new node), **Markers 3D (check)** (a 3D arrow on every point - a sliding point shows), Points / Markers drawn only on the frames that saw a point (the "floating points" were extrapolations; Show Unobserved Points restores them), solve accuracy round (depth at the solve's scale, near-nodal choice on held-out tracks, full-res refinement, readout search, movers excluded, Re-solve keeps the focal), **Consistent Depth** default 8 and the actors' depth following the optical flow, FBX keys from Range Start with no tilt flips, Normals facing the camera, corners written for Screen Comp Native, the Points view refreshing by itself after a re-solve, projection paint resident on the GPU, no upstream render for outputs that never read the plate. Plus the 30 Oct engine / hooks changes (per-node routes, LAN, offline).

**0.2.3:** engine sync for the 26 Oct batch

**0.2.2:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.2.1:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `CameraTrackNative-Tester-0.3.1.zip` | Apple Silicon Mac, 32 GB minimum, Flame 2026/2027 |
| Linux | `CameraTrackNative-Linux-0.3.1.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 16 GB+ VRAM, Flame 2027 (projection outputs on the CPU) |

The installer shares the engine folder of any other Higgins Post engine node already installed, adds SciPy and
Depth Anything 3 (Large, 1.6 GB, Apache-2.0 — no Hugging Face account needed) and the Flame hooks. Isolate (SAM3) uses
Matte LTX Native's model when that kit is installed; flow-guided tracking uses Motion Vectors Native's SEA-RAFT when that kit is installed. Depth Anything 3 Metric (optional download) gives the solve real-world scale.

### Models and licences
- Depth Anything 3 (code, Large and Metric weights) — ByteDance Seed, Apache-2.0.
- SAM3 (optional, via Matte LTX Native) — Meta's SAM licence.
- SEA-RAFT (optional, via Motion Vectors Native) — Princeton, BSD-3-Clause.

## Pixel Spread Native

Fills the hole in a matte from the picture around it — pure C++ inside Flame, no engine. Connect the plate with the
matte of the hole on its matte socket (white = fill) and pick a **Method**: **Pixel Spread** (the pixels along one
direction smeared in — Flame's Pixel Spread, with Spread From / Distance / Softness), **Push-Pull** (the surroundings
averaged inward at every scale — smooth, for sky, walls and soft backgrounds), **Diffusion** (the smoothest fill,
gradients run through the hole) or **Texture** (PatchMatch: the surrounding texture rebuilt inside the hole, Draft /
Normal / Fine). **Width** limits the fill to a band in from the matte's edge, as in Flame. **From Other Frames**: with
Motion Vectors Native's Forward Vectors on Input3, every hole pixel is followed through the motion to the nearest frame
where that part of the picture is uncovered and taken from there (tone-matched); only what no frame ever shows gets the
spatial fill. On the Mac the fill runs on the GPU (Metal); Linux runs on every core.


**0.4.1:** GPU = CPU in Texture (a GPU bug left stale values in the match field - fills up to 1.0 off), memory bounded (a UHD render could take 13.5 GB), a stale-cache fix, anamorphic plates.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `PixelSpreadNative-Tester-0.4.1.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `PixelSpreadNative-Linux-0.4.1.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Motion Vectors Native

Dense optical flow with Princeton's **SEA-RAFT** (Small or Medium), put to work inside Flame. Press Analyze once — forward
and backward motion and an ST map chained from a Reference Frame are stored with the node and render instantly:
- **Motion vectors** in Flame's convention (pixels, y up) for Action's Motion Vectors map, Motion Blur, Pixel Spread and
  Timewarp, a **confidence** matte (forward/backward consistency x the model's own uncertainty) and a flow-colour check.
- **ST map** from the Reference Frame, and **Paint Carry**: paint the Reference Frame (Paint node into the Paint / Shape
  input, its matte on that input's matte socket) and the strokes follow the shot over the plate, fading where the motion
  is unreliable so they never smear.
- **Export Tracks**: up to four points followed through the shot, written as one Flame Stabilizer file (`<run>_tracks.stabilizer`,
  one tracker per point — Load it in Action Axis, 2D Transform or GMask; two points give rotation and scale) plus per-point
  `.ascii` files. It also builds a **GMask Tracer** next to the node: a tracked axis to parent your GMasks to, or a corner-pin
  shape from points 1-4. A point that gets covered can keep following, stop, or be carried by the other points (default).
  Place the points by dragging them in the viewer (Output: Tracks (check)); the
  tracks show there as soon as Analyze is done.
- **Export GMask**: outline a shape on the Reference Frame (a GMask's matte into Paint / Shape) and every region becomes
  its own animated GMask in one **GMask Tracer** setup (`<run>_shapes.mask`), keyed every frame; covered vertices follow
  the rest of the shape. The `aifx_autorefresh` hook adds a GMask Tracer node loaded with it to the Batch, wired to the
  same clip. GMask (check) previews the shapes, and follows the GMask by itself while you edit it.

**0.2.4:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle. **Paint Carry on the GPU** (UHD 80 -> 43 ms; with Motion Blur ~120 -> ~50 ms); Off-Frame Paint = Clamp works (it rendered like Fade out); the vector / ST outputs render in float.

**0.2.3:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders. Paint Carry **Motion Blur** (shutter in degrees: 0 = off, 180 = a normal shutter) blurs the carried paint along the frame's motion.

**0.2.2:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.2.1:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.2.0:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.1.9:** Export GMask **Keyframes On** - shape vertices, the GMask's axis, or axis + residual vertices; **Free Engine Memory** + release after a render; linear plates. *(Mac installer re-uploaded 21 Oct evening: it now finds / installs `uv` itself - the first upload failed with "No module named pip" on a Mac where `uv` was not on the PATH.)*

**0.1.8:** Paint Carry's **matte output** is the carried paint's matte again (it rendered solid white with Over Front on); engine re-submit / Delete Result handling.

**0.1.7:** **Off-Frame Paint** (Inpaint / Fade out / Clamp) - Paint Carry no longer streaks where the carried frame has left the picture; GMask shapes track both ways from the Reference Frame when a matte touches the frame edge.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `MotionVectorsNative-Tester-0.2.4.zip` | Apple Silicon Mac, 16 GB minimum, Flame 2026.1/2027, **a Higgins Post engine kit installed** (Depth Native is the lightest) |
| Linux | `MotionVectorsNative-Linux-0.2.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 8 GB+ VRAM, Flame 2027, **a Higgins Post engine kit installed** |

No downloads: the SEA-RAFT weights (Small 34 MB, Medium 75 MB) ship in the kit. The installer finds the engine folder of
an installed Higgins Post kit, adds the flow engine files and the weights, installs the plugin and updates the Flame hooks.

### Models and licences
- SEA-RAFT code and weights — Princeton Vision & Learning Lab, BSD-3-Clause.

## Relight Native

Relights a shot with Lightricks' LTX relighting IC-LoRAs on the LTX-2.5 base. **Sun Direction** (exteriors): put the sun
where you want it — rotation around the subject and elevation — in one of the 12 looks the model was trained on (hard
directional, low golden side sun, soft overcast, strong backlight with rim…), with the shadows recast. **Day To Night**:
daylight to night, with an optional description. The Front's matte limits where it applies (Blend mixes it in), Input
Colour follows the clip's tag on Flame 2026.1+, and a Z depth on Input3 gives a Normals output. Press Generate once — the
result is stored with the node and renders instantly.

**0.1.13:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.1.12:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.1.11:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.1.10:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.1.9:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.1.8:** **Free Engine Memory** button + automatic release after a render; linear plates no longer clipped.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `RelightNative-Tester-0.1.13.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2026.1/2027, **Matte LTX Native 0.8+ installed** |
| Linux | `RelightNative-Linux-0.1.13.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

Uses the LTX-2.5 model and Python engine that Matte LTX Native installs, plus two LoRAs (Relight, Day-To-Night) and the
Gemma-4 12B text encoder for the prompt (26 GB; Matte LTX Native does not install it), all gated on Hugging Face: accept
the licences on the model pages, and the installer downloads them under your login (or links copies you have).

### Models and licences
- LTX-2.5, the Relight (LTX-2.3) and Day-To-Night IC-LoRAs — Lightricks LTX-2 Community License (gated; accepted under your own account).

## Object Removal Native

Removes objects from a shot: matte what has to go (the matte can move), press Remove, and the area is filled with what
should be behind it, consistent over time, by **LTX-2.5 with the In/Outpainting IC-LoRA** — the plate outside the matte is
untouched. For static backgrounds it can first paint the object out of the first frame with Qwen-Image-Edit or FLUX.2 Klein
(when Background Native's models are installed) and lock LTX to it; **Clean Plate** mode uses Lightricks' Clean Plate
IC-LoRA to remove every person and vehicle (and their shadows) by prompt, the matte limiting where it is used. Matte grow /
feather, optional notes about what is behind the object, Input Colour from the clip's tag on Flame 2026.1+.

**0.2.4:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle.

**0.2.3:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders.

**0.2.2:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.2.1:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands.

**0.2.0:** **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.1.9:** Qwen / Flux fill that invented a person is caught and regenerated (prompt reworded too); **Free Engine Memory** + release after a render; linear plates.

**0.1.8:** engine only - pressing Remove again while a run is going restarts it with the new settings; Delete Result stops a run.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ObjectRemovalNative-Tester-0.2.4.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2026.1/2027, **Matte LTX Native 0.8+ installed** |
| Linux | `ObjectRemovalNative-Linux-0.2.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

Uses the LTX-2.5 model and Python engine that Matte LTX Native installs, plus the In/Outpainting and Clean Plate IC-LoRAs
and the Gemma-4 12B text encoder for the prompt (26 GB; Matte LTX Native does not install it) — all gated on Hugging Face;
files Background Native already downloaded are reused.

### Models and licences
- LTX-2.5, the In/Outpainting (LTX-2.3) and Clean Plate IC-LoRAs — Lightricks LTX-2 Community License (gated).
- Qwen-Image-Edit-2511 / FLUX.2 Klein (optional, via Background Native) — Apache-2.0.
- The ComfyUI version's MiniMax-Remover and ProPainter are non-commercial and are not part of the public build.

## Face UV Native

Automatic face track to a UV pass: a face detector (RetinaFace or BlazeFace) finds the face on every frame and MediaPipe's
478-point face mesh is fitted to it — or the **FLAME** head model (ears, neck, scalp; identity solved once over the clip,
expression and pose per frame). Outputs a **UV pass** (R = U, G = V, alpha = face matte), a face matte, or the plate
**unwrapped** into UV space: paint once on the unwrap and wrap it back with Flame's UV tools so it follows the skin.
Optional **BootsTAPIR** dense-track refine nudges the mesh onto tracked skin points between the landmarks. Track once —
the mesh per frame is stored with the node and the passes are drawn at plate resolution, instantly.

**0.2.7:** **anamorphic plates** (frames go to the engine desqueezed, results map back over the plate's width), **models stay loaded** in the engine between jobs (as many as fit), LAN worker **Allowed folders**, a code-audit round of engine fixes (shutdown refused while rendering, Cancel stops every task, a crafted FLAME .pkl can no longer run code, LAN request limits), Flame hooks 1.5 (**Check for Updates** in Setup); the installer restarts the engine only when it is idle. Texture wrap **on the GPU**; **pins solved exactly** (close pins no longer land short); the viewer no longer freezes during a render; edge-ring / hold-frame / motion-blur fixes.

**0.2.6:** **Where each node renders** (Local / LAN / Cloud per node), **LAN rendering** (worker pool on your own network, `tools/CLOUD.md`), offline engine with pinned model downloads, hooks crash fix; a kit installed without Matte LTX Native no longer stalls its renders. Erode / dilate passes parallel (shared with UV Wrap Native).

**0.2.5:** **Render Monitor** (Flame-style progress window, opens with every render), collect 10x faster, standard Setup tab, Render Root **tokens** (`<project>` `<shot>` ...), optional **cloud rendering** (Runpod serverless / pod, Azure VM - `tools/RUNPOD_SETUP.md`).

**0.2.4:** **Setup file:** Python > Higgins Post > Setup... sets this machine's Render Root; nodes with the default Render Folder render there, and a **Renders To** line shows where a run lands. (Renders To sits in Diagnostics here)

**0.2.3:** controls back on their own tabs (Adjust & Texture / Duplicates); **Path translation:** Render Folder and Analysis Job honour Flame's path translation table (`/opt/Autodesk/cfg/pathTranslation.cfg`), plus an optional `~/.aifx/path_map.json` (`tools/PATH_MAP.md`).

**0.2.2:** refine no longer fails on a missing `dm-tree` (installer adds it; the track carries on without refine and says so); **Free Engine Memory** + release after a render; linear plates. *(Mac installer re-uploaded 21 Oct evening: it now finds / installs `uv` itself - the first upload failed with "No module named pip" on a Mac where `uv` was not on the PATH.)*

**0.2.1:** Unwrap Margin direction fixed in the Texture wrap (the paint landed smaller than its unwrap); engine re-submit / Delete Result handling.

**0.2:** **Show Mesh** overlay with **Nudge** (move / scale / rotate, keyframed), **Pins** (click a vertex, drag it, falloff) and **Snap** (fix one frame, then the node finds that frame's eyes / nose / mouth / jaw on the others and pins them) to fix a track by hand; a **Texture** input wrapped and comped in the node (paint on the Unwrap, or straight on the plate at one frame); dense FLAME head refit on all 468 landmarks; Detect Res to 4096 with accurate defaults; installer fix (einshape for the BootsTAPIR refine).

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `FaceUVNative-Tester-0.2.7.zip` | Apple Silicon Mac, 16 GB minimum, Flame 2026.1/2027, **a Higgins Post engine kit installed** (Depth Native is the lightest) |
| Linux | `FaceUVNative-Linux-0.2.7.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, Flame 2027, **a Higgins Post engine kit installed** |

The face models (RetinaFace, BlazeFace, MediaPipe mesh) and FLAME 2023 Open ship in the kit; the installer adds uniface and
ONNX Runtime to the engine's Python and downloads the BootsTAPIR checkpoint (200 MB) from Google DeepMind.

### Models and licences
- uniface and the RetinaFace weights — MIT; MediaPipe Face Landmarker and BlazeFace — Google, Apache-2.0.
- FLAME 2023 Open — MPI for Intelligent Systems, CC BY 4.0 (Li, Bolkart, Black, Li, Romero, *Learning a model of facial
  shape and expression from 4D scans*, SIGGRAPH Asia 2017); FLAME / MediaPipe correspondence from SMIRK — MIT.
- BootsTAPIR — Google DeepMind, Apache-2.0.
- SCRFD (InsightFace research weights) and CoTracker3 (CC BY-NC) are not part of the public build.

## UV Wrap Native

Wraps a texture painted in UV space (Face UV Native's Unwrap, or any UV / ST map's texture) back onto the picture through a UV pass and comps it over the plate: the other half of Face UV Native - Unwrap, paint, UV Wrap. Front = the painted texture (+ its matte), Back = the plate (+ holdout), Input3 = the UV pass (+ face matte). Nearest / bilinear / bicubic with supersampling, a texture transform to slide the patch, matte erode / feather, Over / Add / Screen in linear light, Hold Frame for a painted still. Pure C++ on the GPU (Metal / Vulkan), no engine.

**0.3.3:** code-audit fixes (an edge ring in the corner texel's colour, the hold frame outside the track, motion blur interpolates the mesh, the output size follows the Plate, Edge Softness at proxy), anamorphic plates.

**0.3.2:** the erode / dilate passes go parallel (vertical passes over bands of columns).

**0.3.1:** Unwrap no longer mirrors / stretches across the nose and jaw silhouettes (matches Face UV's unwrap).

**0.3:** **Unwrap** output (any UV pass: the picture flattened into UV space - paint, then wrap back), **Edge Extend** (no halo round a patch), **Light Follow** (the patch takes on the face's shading as it turns), **Motion Blur** along the UV motion, a **UV Check** grid, **Anisotropic** sampling by default, and an **ST map** mode (distort / undistort through a lens map).

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `UVWrapNative-Tester-0.3.3.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `UVWrapNative-Linux-0.3.3.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

These are test builds from Higgins Post, provided as-is, no warranty.

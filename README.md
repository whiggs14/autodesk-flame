# Autodesk Flame tools — Higgins Post

Native OFX plugins for Autodesk Flame that run AI models locally on the workstation.
No ComfyUI, no shared folders, no cloud.

## Matte LTX Native

Pulls a soft, hair-detailed matte from a plate with Lightricks' **LTX-2.5 Alpha Gen** model.
Optional selection: draw a box around one person and/or type what to keep
("hands, pants, green bag") — body parts and clothing go to Meta's Sapiens2, anything else to Meta's SAM3.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `MatteLTXNative-Tester-0.4.zip` | Apple Silicon Mac, 128 GB recommended (64 GB minimum), Flame 2026/2027 |
| Linux | `MatteLTXNative-Linux-0.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB+ VRAM (60 GB+ runs fully on the GPU), Flame 2027 |

Each zip contains the plugin, the Python engine and an installer; the installer downloads the models
(~56 GB) under your own Hugging Face account. Read `Read Me First.txt` / `README.txt` inside the zip.

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `UpscaleNative-Tester-0.1.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for the 7B models), Flame 2026/2027 |
| Linux | `UpscaleNative-Linux-0.1.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB+ for 7B), Flame 2027 |

The installer downloads SeedVR2 3B + VAE (7 GB; the 7B models are optional, 16.5 GB each) — Apache-2.0, no
Hugging Face account needed. If Matte LTX Native is installed, Upscale Native shares its engine folder and
Python environment.

### Models and licences
- SeedVR2 weights — ByteDance Seed, Apache-2.0 (packaged by numz/SeedVR2_comfyUI); inference code vendored
  from ComfyUI-SeedVR2_VideoUpscaler (Apache-2.0).

These are test builds from Higgins Post, provided as-is, no warranty.

# Autodesk Flame tools — Higgins Post

Native OFX plugins for Autodesk Flame that run AI models locally on the workstation.
No ComfyUI, no shared folders, no cloud.

## Matte LTX Native

Pulls a soft, hair-detailed matte from a plate with Lightricks' **LTX-2.5 Alpha Gen** model.
Optional selection: draw a box around one person and/or type what to keep
("hands, pants, green bag") — body parts and clothing go to Meta's Sapiens2, anything else to Meta's SAM3.
Crop (ROI) mattes only a travelling window around the subject (from a matte or the selection box) for ~3x faster
runs on small subjects, and a built-in Track Box tracker drives that box without keyframes.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `MatteLTXNative-Tester-0.8.zip` | Apple Silicon Mac, 128 GB recommended (64 GB minimum), Flame 2026/2027 |
| Linux | `MatteLTXNative-Linux-0.8.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB+ VRAM (60 GB+ runs fully on the GPU), Flame 2027 |

Each zip contains the plugin, the Python engine and an installer; the installer downloads the models
(~56 GB) under your own Hugging Face account. Read `Read Me First.txt` / `README.txt` inside the zip.

The kit also installs a small Flame Python hook (`aifx_autorefresh.py`): Flame only re-renders an OFX node when a
parameter changes, so without it the viewer keeps showing the pass-through until Refresh Status is pressed; the hook
notices when the engine has finished and nudges the node, so the stored result appears on its own. Restart Flame
once after installing. (Shared by all the engine-backed nodes here.)

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
| macOS | `UpscaleNative-Tester-0.3.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for the 7B models), Flame 2026/2027 |
| Linux | `UpscaleNative-Linux-0.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB+ for 7B), Flame 2027 |

The installer downloads SeedVR2 3B + VAE (7 GB; the 7B models are optional, 16.5 GB each) — Apache-2.0, no
Hugging Face account needed. If Matte LTX Native is installed, Upscale Native shares its engine folder and
Python environment.

### Models and licences
- SeedVR2 weights — ByteDance Seed, Apache-2.0 (packaged by numz/SeedVR2_comfyUI); inference code vendored
  from ComfyUI-SeedVR2_VideoUpscaler (Apache-2.0).

## Colour Match Native

Matches one clip's colour to another — black / white point, tone (luminance curve), contrast and colour
statistics — in pure C++ inside Flame, no models to download. Three stages with their own amounts:
Levels, Tone (the Front's luminance distribution remapped onto the Reference's) and Covariance
(Monge-Kantorovich transform fitted in a YCbCr basis, so it matches means and channel relationships without
rotating hues). Up to 12 frames of each clip are pooled so the match holds over a shot, or the match follows the
current frame; Reference Frame locks the reference to one frame, and **Anchor** mode makes a still or paint that already
matches the plate at that frame follow the plate's lighting over the shot. The Front's matte limits where it is measured
and applied; Input Colour follows the clip's colour-space tag on Flame 2026.1+. The transform is deterministic,
keyframeable and exports as a 33³ `.cube` LUT.

Optional **AI Look** target: when the Higgins Post engine from Background Native (Qwen-Image-Edit-2511 + Lightning)
is installed, the engine recolours the analysis frame once and the plugin measures that instead of the Reference — for
references of a different scene. The installer offers to download the colour-grade-transfer LoRA (236 MB). Without an
engine the plugin works fully on Reference statistics.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ColourMatchNative-Tester-0.4.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `ColourMatchNative-Linux-0.4.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

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
FG on its own, the added layer, the spill matte and the processed Back. No models, no engine.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `AdditiveKeyNative-Tester-0.3.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `AdditiveKeyNative-Linux-0.3.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Lens Blur Native

Depth-of-field / lens defocus with real bokeh, pure C++ inside Flame (FFT convolution on all cores, no engine). Feed it
a Z depth from Depth Native or any depth pass. The image is split into depth layers by circle of confusion, each layer
is convolved with the iris at its own radius and the layers are accumulated near to far, so out-of-focus foreground
spills over the background and sharp foreground occludes what is behind it; highlights are boosted before the blur so
point lights bloom into iris-shaped discs. Iris: blades, rounding, angle, anamorphic aspect, soft edge, bright rim,
centre darkening, or your own aperture image, with presets (and Star / Heart). Chroma Warp adds longitudinal and
lateral colour fringing. Focal Distance animates for rack focus, Pick Focal Distance reads it off the Z at a point in
the viewer, and Show > Depth / Focus Overlay draw the focal plane as a green line through the shot (yellow lines mark
the DOF band; Focus Line Width sets their thickness). Two-plate comp: Front + matte at its Z
over a Background at its own Z, defocused together as one scene. The Front matte is a Flame-style blur mask by default (white = defocus,
black = untouched — the matte itself defocuses with the picture, and with a Background connected the element is comped over
it premultiplied), or the foreground alpha for the comp, or — with no Z at all — the blur amount itself (white = full Radius,
for painted ramps and tilt-shift). Inputs: **Front** (+ matte), **Back** (Background),
**Input3** Z Depth, **Input4** Back Z Depth, **Input5** Iris image. An input shorter than the plate (a one-frame Z, a still
iris image) is held on every frame.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `LensBlurNative-Tester-0.8.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `LensBlurNative-Linux-0.8.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

These are test builds from Higgins Post, provided as-is, no warranty.

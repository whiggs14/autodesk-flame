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
| macOS | `MatteLTXNative-Tester-0.9.4.zip` | Apple Silicon Mac, 128 GB recommended (64 GB minimum), Flame 2026/2027 |
| Linux | `MatteLTXNative-Linux-0.9.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB+ VRAM (60 GB+ runs fully on the GPU), Flame 2027 |

Each zip contains the plugin, the Python engine and an installer; the installer downloads the models
(~56 GB) under your own Hugging Face account. Read `Read Me First.txt` / `README.txt` inside the zip.

The kit also installs a small Flame Python hook (`aifx_autorefresh.py`): Flame only re-renders an OFX node when a
parameter changes, so without it the viewer keeps showing the pass-through until Refresh Status is pressed; the hook
notices when the engine has finished and nudges the node, so the stored result appears on its own. Restart Flame
once after installing. (Shared by all the engine-backed nodes here.)

> **Hooks hotfix 1.1** — the hook shipped with Matte LTX 0.8, Upscale 0.3, Depth 0.1 and Background 0.1 polled the
> batch every 5 s, which resets the Media Panel selection (clips deselect themselves on the Desktop). The current
> kits (Matte LTX 0.9.1, Upscale 0.4.1, Depth 0.2.1, Background 0.2.1, Element 0.3.1, HDR 0.2.1, Motion Vectors 0.1) include the fix; for the older
> ones install `FlameHooks-Hotfix-1.1.zip` from the Releases page (Mac and Linux, one zip).

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `UpscaleNative-Tester-0.4.4.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for the 7B models), Flame 2026/2027 |
| Linux | `UpscaleNative-Linux-0.4.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB+ for 7B), Flame 2027 |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `DepthNative-Tester-0.2.4.zip` | Apple Silicon Mac, 16 GB minimum (32 GB recommended), Flame 2026/2027 |
| Linux | `DepthNative-Linux-0.2.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 8 GB+ VRAM (16 GB for DA3 at 1008 px), Flame 2027 |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `BackgroundNative-Tester-0.2.4.zip` | Apple Silicon Mac, 32 GB minimum (64 GB for Qwen-Image-Edit), Flame 2026/2027 |
| Linux | `BackgroundNative-Linux-0.2.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 12 GB+ VRAM (24 GB for Qwen-Image-Edit), Flame 2027 |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ElementNative-Tester-0.3.4.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2027, **Matte LTX Native 0.8+ installed** |
| Linux | `ElementNative-Linux-0.3.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `HDRNative-Tester-0.2.4.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2027, **Matte LTX Native 0.8+ installed** |
| Linux | `HDRNative-Linux-0.2.4.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

Uses the LTX-2.5 model and Python engine that Matte LTX Native installs, plus a 1.3 GB LoRA that is gated on Hugging Face:
accept the licence on the model page, and the installer downloads it under your login.

### Models and licences
- LTX-2.5 and the SDR-To-HDR IC-LoRA — Lightricks LTX-2 Community License (gated; accepted under your own account).

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
| macOS | `ColourMatchNative-Tester-0.4.4.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `ColourMatchNative-Linux-0.4.4.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

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
| macOS | `AdditiveKeyNative-Tester-0.3.2.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `AdditiveKeyNative-Linux-0.3.2.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Lens Blur Native

Depth-of-field / lens defocus with real bokeh, pure C++ inside Flame (FFT convolution on all cores, no engine). Feed it
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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `LensBlurNative-Tester-0.9.4.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `LensBlurNative-Linux-0.9.4.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Regrain Native

Puts the plate's grain back on a comp — the job of Flame's Match Grain and Nuke's DasGrain — pure C++ inside Flame (all
cores, no engine). Connect the comp, the degrained plate and the original plate and press **Analyze**: it measures the
grain's strength per channel across the brightness range (RGB response curves, drawn in the viewer, with points you can
drag). Where the comp is unchanged the plate's own grain comes back exactly; where it changed (paint, CG, set extensions,
removals — found automatically, from a matte, or both) new grain is built from the plate's own grain in a **Sample Box**
(Voronoi cells re-shuffled every frame, draggable in the viewer) and matched to the comp's brightness, so nothing of what
was removed shows through. Modes for plate grain only or new grain everywhere; grain size, softness and gain per channel.
**Grain profiles** save the curves, settings and the grain itself to reuse on CG, clean plates or other shots (drop-down,
Previous / Next, delete with a week to undo). QC views: the grain on grey, the changed-area key, and result vs original x10.
Inputs: **Front** (comp), **Back** (Degrained), **Input3** Original, **Input4** Matte, **Input5** Grain from another Regrain.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `RegrainNative-Tester-0.1.zip` | Apple Silicon Mac, Flame 2026/2027 |
| Linux | `RegrainNative-Linux-0.1.zip` | Rocky Linux 8.10 / 9.x, Flame 2027 |

## Motion Vectors Native

Dense optical flow with Princeton's **SEA-RAFT** (Small or Medium), put to work inside Flame. Press Analyze once — forward
and backward motion and an ST map chained from a Reference Frame are stored with the node and render instantly:
- **Motion vectors** in Flame's convention (pixels, y up) for Action's Motion Vectors map, Motion Blur, Pixel Spread and
  Timewarp, a **confidence** matte (forward/backward consistency x the model's own uncertainty) and a flow-colour check.
- **ST map** from the Reference Frame, and **Paint Carry**: paint the Reference Frame (Paint node into the Paint / Shape
  input, its matte on that input's matte socket) and the strokes follow the shot over the plate, fading where the motion
  is unreliable so they never smear.
- **Export Tracks**: up to four points followed through the shot, written as Flame Stabilizer `.ascii` files (absolute and
  relative) to import into any tracker — Action Axis, 2D Transform, GMask. Lost points stay lost instead of following
  whatever covered them. Place the points by dragging them in the viewer (Output: Tracks (check)); the
  tracks show there as soon as Analyze is done.
- **Export GMask**: outline a shape on the Reference Frame (a GMask's matte into Paint / Shape) and every region becomes
  its own animated GMask in one **GMask Tracer** setup (`<run>_shapes.mask`), keyed every frame; covered vertices follow
  the rest of the shape. The `aifx_autorefresh` hook adds a GMask Tracer node loaded with it to the Batch, wired to the
  same clip. GMask (check) previews the shapes, and follows the GMask by itself while you edit it.

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `MotionVectorsNative-Tester-0.1.3.zip` | Apple Silicon Mac, 16 GB minimum, Flame 2026.1/2027, **a Higgins Post engine kit installed** (Depth Native is the lightest) |
| Linux | `MotionVectorsNative-Linux-0.1.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 8 GB+ VRAM, Flame 2027, **a Higgins Post engine kit installed** |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `RelightNative-Tester-0.1.3.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2026.1/2027, **Matte LTX Native 0.8+ installed** |
| Linux | `RelightNative-Linux-0.1.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `ObjectRemovalNative-Tester-0.1.3.zip` | Apple Silicon Mac, 64 GB recommended, Flame 2026.1/2027, **Matte LTX Native 0.8+ installed** |
| Linux | `ObjectRemovalNative-Linux-0.1.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB VRAM, Flame 2027, **Matte LTX Native 0.8+ installed** |

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

**Download:** see the [Releases](../../releases) page.

| Build | File | Requirements |
|---|---|---|
| macOS | `FaceUVNative-Tester-0.1.3.zip` | Apple Silicon Mac, 16 GB minimum, Flame 2026.1/2027, **a Higgins Post engine kit installed** (Depth Native is the lightest) |
| Linux | `FaceUVNative-Linux-0.1.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, Flame 2027, **a Higgins Post engine kit installed** |

The face models (RetinaFace, BlazeFace, MediaPipe mesh) and FLAME 2023 Open ship in the kit; the installer adds uniface and
ONNX Runtime to the engine's Python and downloads the BootsTAPIR checkpoint (200 MB) from Google DeepMind.

### Models and licences
- uniface and the RetinaFace weights — MIT; MediaPipe Face Landmarker and BlazeFace — Google, Apache-2.0.
- FLAME 2023 Open — MPI for Intelligent Systems, CC BY 4.0 (Li, Bolkart, Black, Li, Romero, *Learning a model of facial
  shape and expression from 4D scans*, SIGGRAPH Asia 2017); FLAME / MediaPipe correspondence from SMIRK — MIT.
- BootsTAPIR — Google DeepMind, Apache-2.0.
- SCRFD (InsightFace research weights) and CoTracker3 (CC BY-NC) are not part of the public build.

These are test builds from Higgins Post, provided as-is, no warranty.

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
| macOS | `MatteLTXNative-Tester-0.3.zip` | Apple Silicon Mac, 128 GB recommended (64 GB minimum), Flame 2026/2027 |
| Linux | `MatteLTXNative-Linux-0.3.zip` | Rocky Linux 8.10 / 9.x, NVIDIA driver 560+, 24 GB+ VRAM (60 GB+ runs fully on the GPU), Flame 2027 |

Each zip contains the plugin, the Python engine and an installer; the installer downloads the models
(~56 GB) under your own Hugging Face account. Read `Read Me First.txt` / `README.txt` inside the zip.

### Models and licences
The plugin downloads models that carry their own terms — check they fit your use, especially paid client work:
- LTX-2.5 and the Alpha Gen IC-LoRA — Lightricks LTX-2 Community License (free below the revenue threshold stated in the licence).
- SAM3 — Meta's SAM licence.
- Sapiens2 — Meta's Sapiens2 licence (royalty-free; no surveillance, biometric ID, deepfakes or military use).

These are test builds from Higgins Post, provided as-is, no warranty.

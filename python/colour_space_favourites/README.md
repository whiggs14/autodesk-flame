# Colour Space Favourites

A Flame Python hook for tagging imports with the colour spaces you use most, without scrolling the MediaHub dropdown.

- **MediaHub > Files > right-click > Colour Space...** lists your favourites (S-Log3, Rec.709, ACEScg to start) plus **From File or Rules**. Picking one sets the MediaHub colour management to **Tag Only** with that colour space for every import after it.
- **Flame main menu > Higgins Post > Colour Space Favourites...** opens the editor: filter and double-click any colour space in the project's OCIO config to add it, double-click a label to rename, Move Up / Move Down / Remove, Save. The menu updates straight away.

- **Media Panel / Desktop > right-click clips or sequences > Tag Colour Space...** tags clips already in Flame: a **Source Colour Mgmt** Timeline FX in Tag Only mode on every segment. One already there in Tag Only is reused; one that converts (Input Transform etc.) is left alone and reported.
- **Timeline > right-click segments > Tag Colour Space...** does the same for the selected segments.
- **Batch > right-click nodes > Tag Colour Space...** inserts a **Colour Mgmt** node (Tag Only) after each selected node and re-wires what its main output fed (matte connections from a clip's matte output stay where they are).

Favourites are saved to `config/colour_space_favourites.json` next to the script, so updating the script keeps them.

## Install

```
mkdir -p /opt/Autodesk/shared/python/colour_space_favourites
cp colour_space_favourites.py /opt/Autodesk/shared/python/colour_space_favourites/
```
Then **Python > Refresh Python Hooks** in Flame (or restart Flame).

## Notes

- Flame 2023.2+ (PySide6 or PySide2). Tested with Flame 2027.2's Python and its shipped OCIO configs.
- Flame's Python API only sets **Tag Only** for MediaHub imports - Auto Convert, View Transform and Use LUT stay manual.
- Colour-space names differ between OCIO configs. The starting favourites are matched against the project's config on first run (e.g. "S-Log3 S-Gamut3.Cine" in the ACES configs, "SLog3 / SGamut3" in the legacy ones). If a favourite is missing from a project's config, picking it shows a message pointing to the editor.

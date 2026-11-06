#!/bin/bash
# Higgins Post native plugins for Flame - installer / updater / uninstaller.
#   bash hp-update.sh                 interactive: shows what is installed vs the latest release, asks what to do
#   bash hp-update.sh --check         only show the table
#   bash hp-update.sh --all [--yes]   install / update every plugin (--yes answers the installers' prompts with their defaults)
#   bash hp-update.sh --only lensblur,faceuv,pixelspread,hooks   (hooks = the Flame hooks kit: Setup, Render Monitor, auto-refresh)
#   --force   install even while the engine renders (the engine kits and the hooks kit restart it; normally they wait)
#   bash hp-update.sh --uninstall lensblur,faceuv | --uninstall all [--purge]   (--purge also removes the shared engine + models)
#   --flame 2027.1   install the builds for that Flame version (default: the newest Flame on this machine; Higgins Post
#                    Updates in Flame passes the Flame it runs in)
# macOS (Apple Silicon) and Rocky Linux. Needs curl, unzip, python3, sudo. Releases: https://github.com/whiggs14/autodesk-flame/releases
set -u
REPO="whiggs14/autodesk-flame"
API="https://api.github.com/repos/$REPO/releases?per_page=100"
case "$(uname -s)" in
  Darwin) OS=mac; SUFFIX=Tester; PLUGIN_DIR=/Library/OFX/Plugins; ENGINE_DEFAULT=/Users/Shared/MatteLTXNative;;
  Linux)  OS=linux; SUFFIX=Linux; PLUGIN_DIR=/usr/OFX/Plugins; ENGINE_DEFAULT=/opt/MatteLTXNative;;
  *) echo "Unsupported OS: $(uname -s)"; exit 1;;
esac
STATE_DIR="$HOME/.aifx"; STATE="$STATE_DIR/installed.json"; mkdir -p "$STATE_DIR"
WORK="${TMPDIR:-/tmp}/hp-update.$$"; mkdir -p "$WORK"; trap 'rm -rf "$WORK"' EXIT
bold() { printf "\033[1m%s\033[0m\n" "$*"; }
fail() { printf "\033[31mERROR: %s\033[0m\n" "$*"; exit 1; }
for t in curl unzip python3; do command -v "$t" >/dev/null || fail "$t is needed"; done

MODE=menu; ONLY=""; YES=0; PURGE=0; UNINSTALL=""; FORCE=0; HOOKS_TOUCHED=0; FLAME_SEL="${AIFX_FLAME_VERSION:-}"
HOOKS_DIR=/opt/Autodesk/shared/python/aifx_context
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check;; --all) MODE=all;; --only) MODE=only; ONLY="$2"; shift;; --yes|-y) YES=1;;
    --uninstall) MODE=uninstall; UNINSTALL="$2"; shift;; --purge) PURGE=1;;
    --force) FORCE=1;; --flame) FLAME_SEL="$2"; shift;; -h|--help) sed -n 2,12p "$0"; exit 0;; *) fail "unknown option $1";;
  esac; shift
done

# ---- the Flame versions on this machine: Flame / Flare / Flame Assist in /opt/Autodesk, each read from its VERSION file
python3 - > "$WORK/flames.txt" <<'EOF'
import os, re
root = "/opt/Autodesk"; seen = {}
def fv(s):
    m = re.match(r"(\d{4})(?:\.(\d+))?(?:\.(\d+))?(?:\.pr(\d+))?", s or "")
    return tuple(int(x or 0) for x in m.groups()) if m else (0, 0, 0, 0)
try:
    names = os.listdir(root)
except OSError:
    names = []
for n in names:
    m = re.match(r"^(flame|flare|flameassist|flame_assist)_(\d{4}\S*)$", n)
    if not m:
        continue
    p = os.path.realpath(os.path.join(root, n))
    if not os.path.isdir(os.path.join(p, "bin")):
        continue
    v = m.group(2)
    try:
        mm = re.search(r'VERSION\s+"([^"]+)"', open(os.path.join(p, "VERSION")).read())
        if mm:
            v = mm.group(1)
    except OSError:
        pass
    seen[(m.group(1), v)] = p
for (app, v), p in sorted(seen.items(), key=lambda kv: fv(kv[0][1])):
    print(app, v, p)
EOF
FLAMES=$(awk '{print $1" "$2}' "$WORK/flames.txt" | paste -sd, - | sed 's/,/, /g')
if [ -n "$FLAME_SEL" ]; then FLAME_TARGET="$FLAME_SEL"; else FLAME_TARGET=$(tail -1 "$WORK/flames.txt" | awk '{print $2}'); fi
if [ -n "$FLAMES" ]; then bold "Flame on this machine: $FLAMES"; else echo "No Flame found in /opt/Autodesk - installing the default builds."; fi
if [ -n "$FLAME_TARGET" ]; then
  how=""; [ -z "$FLAME_SEL" ] && [ "$(wc -l < "$WORK/flames.txt" | tr -d ' ')" -gt 1 ] && how=" (the newest here; --flame <version> for another)"
  echo "  Installing the builds for Flame $FLAME_TARGET$how"
  [ -n "$FLAME_SEL" ] && [ -s "$WORK/flames.txt" ] && ! awk '{print $2}' "$WORK/flames.txt" | grep -qx "$FLAME_SEL" && echo "  (Flame $FLAME_SEL is not installed on this machine)"
  [ "$(awk '{split($2, v, "."); print v[1]"."v[2]}' "$WORK/flames.txt" | sed 's/\.pr[0-9]*$/.0/' | sort -u | wc -l | tr -d ' ')" -gt 1 ] && \
    echo "  Every Flame here shares one set of plugins and hooks; they adapt to the Flame they run in."
fi
# ---- the latest release of every plugin for this OS: "<kit> <version> <url> <title>"
bold "Checking the latest releases on GitHub ..."
if [ -n "${AIFX_RELEASES_JSON:-}" ]; then cp "$AIFX_RELEASES_JSON" "$WORK/releases.json"     # testing: a saved release list
else curl -fsSL -H "Accept: application/vnd.github+json" "$API" -o "$WORK/releases.json" || fail "could not reach GitHub (api.github.com)"; fi
python3 - "$WORK/releases.json" "$SUFFIX" "${FLAME_TARGET:-}" "$WORK" > "$WORK/latest.txt" <<'EOF'
import json, os, re, sys
rels = json.load(open(sys.argv[1])); suffix = sys.argv[2]; target = sys.argv[3]; work = sys.argv[4]
# <Kit>-<Tester|Linux|Hotfix>-<version>[-Flame<major.minor>].zip   (Hotfix = the Flame hooks kit, Mac + Linux)
pat = re.compile(r"^([A-Za-z0-9]+)-(Tester|Linux|Hotfix)-([0-9][0-9.]*?)(?:-Flame([0-9][0-9.]*))?\.zip$")
def vt(v): return tuple(int(x) for x in v.split(".") if x)
def fv(s):
    m = re.match(r"(\d{4})(?:\.(\d+))?(?:\.(\d+))?(?:\.pr(\d+))?", s or "")
    return tuple(int(x or 0) for x in m.groups()) if m else (0, 0, 0, 0)
T = fv(target)[:2] if target else None
MIN = {"*": "2025"}                      # the oldest Flame (major.minor) a kit is offered for; the hooks need Flame's Python 3.11+
best = {}; blocked = {}
for r in rels:
    if r.get("draft") or r.get("prerelease"): continue
    for a in r.get("assets", []):
        m = pat.match(a["name"])
        if not m or (m.group(2) != suffix and not (m.group(1) == "FlameHooks" and m.group(2) == "Hotfix")): continue
        kit, ver, tag = m.group(1), m.group(3), m.group(4)
        if T is not None and tag and fv(tag)[:2] > T:                    # a build made for a newer Flame than this one
            if kit not in blocked or fv(tag) < fv(blocked[kit][1]): blocked[kit] = (ver, tag)
            continue
        need = MIN.get(kit, MIN["*"])
        if T is not None and T < fv(need)[:2]:
            if kit not in blocked or vt(ver) > vt(blocked[kit][0]): blocked[kit] = (ver, need)
            continue
        key = (vt(ver), fv(tag)[:2] if tag else (0, 0))                  # the newest kit; for that version the closest Flame build
        if kit not in best or key > best[kit][0]:
            best[kit] = (key, ver, a["browser_download_url"], r.get("name", ""), tag or "")
for kit in sorted(best):
    _, ver, url, title, tag = best[kit]
    print(kit, ver, url, title.replace(" ", "_"))
with open(os.path.join(work, "blocked.txt"), "w") as f:
    for kit in sorted(blocked):
        if kit not in best: f.write(f"{kit} {blocked[kit][0]} {blocked[kit][1]}\n")
with open(os.path.join(work, "tags.txt"), "w") as f:
    for kit in sorted(best):
        if best[kit][4]: f.write(f"{kit} {best[kit][4]}\n")
notes = []
if T is not None:
    if T < (2026, 1): notes.append("Flame before 2026.1: Input Colour 'Auto' cannot read the clip's colour tag - set the plate's colour on each node.")
    if T < (2027, 0): notes.append("Flame before 2027: the plugins are built and tested on Flame 2027; Camera Track cannot read the lens from the clip's metadata.")
    if T < (2027, 2): notes.append("Flame before 2027.2: the hooks work from Flame's idle timer (no background thread) and see a batch change within 10 s; "
                                  "Camera Track's dense cloud comes into Action as points (no Gaussian Splats node).")
with open(os.path.join(work, "flame_notes.txt"), "w") as f:
    f.write("".join(n + "\n" for n in notes))
EOF
if [ ! -s "$WORK/latest.txt" ]; then
  [ -s "$WORK/blocked.txt" ] && fail "Flame $FLAME_TARGET is older than these plugins support (Flame $(awk '{print $3}' "$WORK/blocked.txt" | sort -u | head -1) or newer)"
  fail "no releases found for $SUFFIX"
fi

installed_version() {   # the version stamped by the kit (bundle / hooks folder), else recorded by this script; "present" = installed without a version; "-" = absent
  local kit="$1" v rec
  rec=$(python3 -c "import json,sys; d=json.load(open('$STATE')) if __import__('os').path.exists('$STATE') else {}; print(d.get('$kit',''))" 2>/dev/null)
  if [ "$kit" = FlameHooks ]; then
    [ -f "$HOOKS_DIR/aifx_setup.py" ] || [ -f "$HOOKS_DIR/aifx_autorefresh.py" ] || { echo "-"; return; }
    v=$(cat "$HOOKS_DIR/hooks_version.txt" 2>/dev/null | tr -dc '0-9.')
  else
    [ -d "$PLUGIN_DIR/$kit.ofx.bundle" ] || { echo "-"; return; }
    v=$(cat "$PLUGIN_DIR/$kit.ofx.bundle/Contents/Resources/kit_version.txt" 2>/dev/null | tr -dc '0-9.')
  fi
  [ -n "$v" ] || v="$rec"
  if [ -n "$v" ]; then echo "$v"; else echo "present"; fi
}
# exit 0 when no engine on this machine is rendering; else 1, printing "<engine folder> <jobs>" for each busy one
engine_idle() { python3 - "$PLUGIN_DIR" "$ENGINE_DEFAULT" <<'EOF'
import glob, json, os, socket, sys
roots = []
for p in glob.glob(os.path.join(sys.argv[1], "*.ofx.bundle", "Contents", "Resources", "engine_root.txt")):
    try: r = open(p).read().strip()
    except OSError: continue
    if r and r not in roots: roots.append(r)
if sys.argv[2] not in roots: roots.append(sys.argv[2])
busy = 0
for r in roots:
    sock = os.path.join(r, "run", "engine.sock")
    if not os.path.exists(sock): continue
    try:
        c = socket.socket(socket.AF_UNIX); c.settimeout(3); c.connect(sock); c.sendall(b'{"cmd": "jobs"}\n'); buf = b""
        while b"\n" not in buf:
            d = c.recv(1 << 20)
            if not d: break
            buf += d
        c.close()
        n = sum(1 for j in json.loads(buf.decode().split("\n")[0]).get("jobs", []) if j.get("state") in ("running", "queued"))
    except Exception:
        n = 0                                     # no answer: no engine running there
    if n: print(r, n); busy += n
sys.exit(1 if busy else 0)
EOF
}
record_version() { python3 - "$STATE" "$1" "$2" <<'EOF'
import json, os, sys
p, kit, ver = sys.argv[1:]
d = json.load(open(p)) if os.path.exists(p) else {}
if ver: d[kit] = ver
else: d.pop(kit, None)
json.dump(d, open(p, "w"), indent=1)
EOF
}
vgt() { python3 -c "import sys; a=[int(x) for x in sys.argv[1].split('.')]; b=[int(x) for x in sys.argv[2].split('.')]; sys.exit(0 if a>b else 1)" "$1" "$2"; }

# ---- the table
echo; printf "  %-24s %-12s %-12s %s\n" "plugin" "installed" "latest" ""; printf "  %-24s %-12s %-12s %s\n" "------" "---------" "------" ""
TODO=""
while read -r kit ver url title; do
  cur=$(installed_version "$kit"); what=""
  if [ "$cur" = "-" ]; then what="(not installed)"
  elif [ "$cur" = "present" ]; then what="UPDATE? (version unknown)"
  elif vgt "$ver" "$cur"; then what="UPDATE"
  else what="up to date"; fi
  printf "  %-24s %-12s %-12s %s\n" "$kit" "$cur" "$ver" "$what"
  case "$what" in UPDATE*|"(not installed)") TODO="$TODO $kit";; esac
done < "$WORK/latest.txt"
while read -r kit ver need; do printf "  %-24s %-12s %-12s %s\n" "$kit" "$(installed_version "$kit")" "$ver" "needs Flame $need+ (not offered)"; done < "$WORK/blocked.txt"
while read -r kit tag; do echo "  ($kit: the build made for Flame $tag)"; done < "$WORK/tags.txt"
[ -s "$WORK/flame_notes.txt" ] && { echo; sed 's/^/  /' "$WORK/flame_notes.txt"; }
echo

install_kit() {   # kit version url
  local kit="$1" ver="$2" url="$3" zip="$WORK/$kit-$SUFFIX-$ver.zip" dir
  bold ">>> $kit $ver"
  curl -fL --progress-bar "$url" -o "$zip" || { echo "download failed: $url"; return 1; }
  rm -rf "$WORK/$kit"; mkdir -p "$WORK/$kit"; unzip -q "$zip" -d "$WORK/$kit" || { echo "unzip failed"; return 1; }
  dir=$(find "$WORK/$kit" -maxdepth 1 -mindepth 1 -type d | head -1)
  local inst
  if [ "$kit" = FlameHooks ] || [ "$OS" = linux ]; then inst="$dir/install.sh"; else inst=$(find "$dir" -maxdepth 1 -name "Install *.command" | head -1); fi
  if [ "$FORCE" = 0 ] && { [ "$kit" = FlameHooks ] || [ -d "$dir/payload/engine" ]; }; then   # these restart the engine
    local b; if ! b=$(engine_idle); then
      echo "    skipped: the engine is rendering ($(echo "$b" | awk '{s+=$2} END {print s}') job(s)) and this install restarts it."
      echo "    Run the update again when the render has finished (or with --force)."; return 1; fi
  fi
  [ -f "$inst" ] || { echo "no installer in the kit"; return 1; }
  [ -d "$dir/payload/aifx_context" ] && HOOKS_TOUCHED=1        # an engine kit: it copies its own (maybe older) Flame hooks in
  chmod +x "$inst"
  if [ "$YES" = 1 ]; then
    # the installers ask for the engine folder (Return = the default / the one already there), a models folder to search and a
    # Return to close: an empty line answers every one of those with its default
    (cd "$dir" && yes "" | bash "$inst") || { echo "installer reported a problem"; return 1; }
  else
    (cd "$dir" && bash "$inst" < /dev/tty) || { echo "installer reported a problem"; return 1; }
  fi
  if [ "$kit" = FlameHooks ]; then
    if [ -f "$HOOKS_DIR/aifx_autorefresh.py" ]; then record_version "$kit" "$ver"; echo "    Flame hooks $ver installed (in Flame: Python > Rescan Python Hooks)."; return 0; fi
    echo "    the hooks are not in $HOOKS_DIR after the install - check the installer's output"; return 1
  fi
  if [ -d "$PLUGIN_DIR/$kit.ofx.bundle" ]; then record_version "$kit" "$ver"; echo "    $kit $ver installed."; else echo "    $kit: the bundle is not in $PLUGIN_DIR after the install - check the installer's output"; return 1; fi
}
uninstall_kit() {
  local kit="$1" b="$PLUGIN_DIR/$kit.ofx.bundle"
  if [ -d "$b" ]; then sudo rm -rf "$b" && echo "    removed $b"; else echo "    $kit was not installed"; fi
  record_version "$kit" ""
}
sudo_keepalive() { sudo -v || fail "sudo is needed to write to $PLUGIN_DIR"; ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null & }

case "$MODE" in
  check) exit 0;;
  uninstall)
    [ -n "$UNINSTALL" ] || fail "--uninstall needs a list of plugins or 'all'"
    sudo_keepalive
    if [ "$UNINSTALL" = all ]; then
      while read -r kit ver url title; do uninstall_kit "$kit"; done < "$WORK/latest.txt"
      for b in "$PLUGIN_DIR"/*Native.ofx.bundle; do [ -d "$b" ] && sudo rm -rf "$b" && echo "    removed $b"; done
      if [ "$OS" = mac ]; then H="/opt/Autodesk/shared/python/aifx_context"; else H="/opt/Autodesk/shared/python/aifx_context"; fi
      [ -d "$H" ] && sudo rm -rf "$H" && echo "    removed the Flame hook $H"
    else
      for kit in $(echo "$UNINSTALL" | tr ',' ' '); do
        real=$(awk -v k="$kit" 'tolower($1)==tolower(k) || tolower($1)==tolower(k)"native" || (tolower(k)=="hooks" && $1=="FlameHooks") {print $1}' "$WORK/latest.txt" | head -1)
        [ -n "$real" ] || { echo "    unknown plugin: $kit"; continue; }
        uninstall_kit "$real"
      done
    fi
    if [ "$PURGE" = 1 ]; then
      ROOT=$(cat "$PLUGIN_DIR"/*.ofx.bundle/Contents/Resources/engine_root.txt 2>/dev/null | head -1); ROOT="${ROOT:-$ENGINE_DEFAULT}"
      if [ -d "$ROOT" ]; then
        echo; bold "This removes the shared engine AND every downloaded model in $ROOT ($(du -sh "$ROOT" 2>/dev/null | cut -f1))."
        read -r -p "Type DELETE to confirm: " ans < /dev/tty
        [ "$ans" = DELETE ] && { rm -rf "$ROOT" 2>/dev/null || sudo rm -rf "$ROOT"; echo "    removed $ROOT"; }
      fi
    fi
    echo; bold "Done. Restart Flame."; exit 0;;
  all) SEL="$TODO";;
  only) SEL=""; for kit in $(echo "$ONLY" | tr ',' ' '); do real=$(awk -v k="$kit" 'tolower($1)==tolower(k) || tolower($1)==tolower(k)"native" || (tolower(k)=="hooks" && $1=="FlameHooks") {print $1}' "$WORK/latest.txt" | head -1); [ -n "$real" ] && SEL="$SEL $real" || echo "unknown plugin: $kit"; done;;
  menu)
    echo "  1) install / update everything that is new or missing"
    echo "  2) update only what is already installed"
    echo "  3) choose plugins"
    echo "  4) uninstall plugins"
    echo "  5) quit"
    read -r -p "> " ans < /dev/tty
    case "$ans" in
      1) SEL="$TODO";;
      2) SEL=""; for kit in $TODO; do [ "$(installed_version "$kit")" != "-" ] && SEL="$SEL $kit"; done;;
      3) read -r -p "plugins (names, comma separated, e.g. lensblur,faceuv): " ONLY < /dev/tty; SEL=""; for kit in $(echo "$ONLY" | tr ',' ' '); do real=$(awk -v k="$kit" 'tolower($1)==tolower(k) || tolower($1)==tolower(k)"native" || (tolower(k)=="hooks" && $1=="FlameHooks") {print $1}' "$WORK/latest.txt" | head -1); [ -n "$real" ] && SEL="$SEL $real" || echo "unknown plugin: $kit"; done;;
      4) read -r -p "plugins to remove (comma separated, or all): " U < /dev/tty; exec bash "$0" --uninstall "$U";;
      *) exit 0;;
    esac
    [ "$YES" = 1 ] || { read -r -p "Answer the installers' questions with their defaults automatically? [Y/n] " a < /dev/tty; [ "$a" = n ] || [ "$a" = N ] || YES=1; };;
esac
[ -n "${SEL// /}" ] || { bold "Nothing to do - everything is up to date."; exit 0; }
case " $SEL " in *" MatteLTXNative "*) SEL="MatteLTXNative $(echo "$SEL" | tr ' ' '\n' | grep -v '^MatteLTXNative$' | tr '\n' ' ')";; esac   # first: it brings the engine the other engine kits need
case " $SEL " in *" FlameHooks "*) SEL="$(echo "$SEL" | tr ' ' '\n' | grep -v '^FlameHooks$' | tr '\n' ' ') FlameHooks";; esac   # last: the engine kits carry hooks of their own
echo; bold "Installing:$SEL"; echo
sudo_keepalive
OK=""; BAD=""
for kit in $SEL; do
  line=$(awk -v k="$kit" '$1==k' "$WORK/latest.txt"); set -- $line
  if install_kit "$1" "$2" "$3"; then OK="$OK $kit"; else BAD="$BAD $kit"; fi
  echo
done
# the engine kits copy the Flame hooks they were built with: put the current hooks kit back on top
case " $OK $BAD " in *" FlameHooks "*) ;; *)
  line=$(awk '$1=="FlameHooks"' "$WORK/latest.txt")
  if [ "${HOOKS_TOUCHED:-0}" = 1 ] && [ -n "$line" ]; then
    set -- $line; bold "The engine kits brought their own copy of the Flame hooks - reinstalling the current hooks ($2) on top"
    if install_kit "$1" "$2" "$3"; then OK="$OK FlameHooks"; else BAD="$BAD FlameHooks"; fi; echo
  fi;;
esac
bold "Installed / updated:${OK:- none}"; [ -n "$BAD" ] && printf "\033[31mFailed:%s\033[0m\n" "$BAD"
bold "Restart Flame to load the new versions."
[ -z "$BAD" ]                                   # the exit status says whether everything went in (Higgins Post Updates reads it)

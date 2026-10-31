#!/bin/bash
# Higgins Post native plugins for Flame - installer / updater / uninstaller.
#   bash hp-update.sh                 interactive: shows what is installed vs the latest release, asks what to do
#   bash hp-update.sh --check         only show the table
#   bash hp-update.sh --all [--yes]   install / update every plugin (--yes answers the installers' prompts with their defaults)
#   bash hp-update.sh --only lensblur,faceuv,pixelspread,hooks   (hooks = the Flame hooks kit: Setup, Render Monitor, auto-refresh)
#   --force   install even while the engine renders (the engine kits and the hooks kit restart it; normally they wait)
#   bash hp-update.sh --uninstall lensblur,faceuv | --uninstall all [--purge]   (--purge also removes the shared engine + models)
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

MODE=menu; ONLY=""; YES=0; PURGE=0; UNINSTALL=""; FORCE=0
HOOKS_DIR=/opt/Autodesk/shared/python/aifx_context
while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE=check;; --all) MODE=all;; --only) MODE=only; ONLY="$2"; shift;; --yes|-y) YES=1;;
    --uninstall) MODE=uninstall; UNINSTALL="$2"; shift;; --purge) PURGE=1;;
    --force) FORCE=1;; -h|--help) sed -n 2,10p "$0"; exit 0;; *) fail "unknown option $1";;
  esac; shift
done

# ---- the latest release of every plugin for this OS: "<kit> <version> <url> <title>"
bold "Checking the latest releases on GitHub ..."
curl -fsSL -H "Accept: application/vnd.github+json" "$API" -o "$WORK/releases.json" || fail "could not reach GitHub (api.github.com)"
python3 - "$WORK/releases.json" "$SUFFIX" > "$WORK/latest.txt" <<'EOF'
import json, re, sys
rels = json.load(open(sys.argv[1])); suffix = sys.argv[2]
pat = re.compile(r"^([A-Za-z0-9]+)-(Tester|Linux|Hotfix)-([0-9][0-9.]*)\.zip$")     # Hotfix = the Flame hooks kit, Mac + Linux
best = {}
def vt(v): return tuple(int(x) for x in v.split("."))
for r in rels:
    if r.get("draft") or r.get("prerelease"): continue
    for a in r.get("assets", []):
        m = pat.match(a["name"])
        if not m or (m.group(2) != suffix and not (m.group(1) == "FlameHooks" and m.group(2) == "Hotfix")): continue
        kit, ver = m.group(1), m.group(3)
        if kit not in best or vt(ver) > vt(best[kit][0]):
            best[kit] = (ver, a["browser_download_url"], r.get("name", ""))
for kit in sorted(best):
    ver, url, title = best[kit]
    print(kit, ver, url, title.replace(" ", "_"))
EOF
[ -s "$WORK/latest.txt" ] || fail "no releases found for $SUFFIX"

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
case " $SEL " in *" FlameHooks "*) SEL="$(echo "$SEL" | tr ' ' '\n' | grep -v '^FlameHooks$' | tr '\n' ' ') FlameHooks";; esac   # last: the engine kits carry hooks of their own
echo; bold "Installing:$SEL"; echo
sudo_keepalive
OK=""; BAD=""
for kit in $SEL; do
  line=$(awk -v k="$kit" '$1==k' "$WORK/latest.txt"); set -- $line
  if install_kit "$1" "$2" "$3"; then OK="$OK $kit"; else BAD="$BAD $kit"; fi
  echo
done
bold "Installed / updated:${OK:- none}"; [ -n "$BAD" ] && printf "\033[31mFailed:%s\033[0m\n" "$BAD"
bold "Restart Flame to load the new versions."
[ -z "$BAD" ]                                   # the exit status says whether everything went in (Higgins Post Updates reads it)

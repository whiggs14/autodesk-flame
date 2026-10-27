"""
Colour Space Favourites
=======================

Script Version: 2.1.0
Flame Version:  2023.2+ (tested target: 2027)

Adds a "Colour Space..." right-click menu in the MediaHub (Files tab) with your
most-used tagged colour spaces. Picking one sets the MediaHub General Colour
Management options to Tag Only + that colour space, so every clip you import
from then on is tagged with it.

Favourites are edited from inside Flame:
    Flame main menu > Higgins Post > Colour Space Favourites...

The editor lists every colour space in the current project's OCIO config, so
names are always valid. Favourites are saved to
    <script folder>/config/colour_space_favourites.json
which is kept when the script itself is updated.

Install:  /opt/Autodesk/shared/python/colour_space_favourites/colour_space_favourites.py
Then:     Flame > Python > Refresh Python Hooks (or restart Flame)

Note: Flame's Python API only supports Tag Only mode for MediaHub colour
management (not Auto Convert), and cannot colour or reorder the MediaHub
colour-space dropdown itself, hence this menu.
"""

import json
import os

import flame

SCRIPT_NAME = 'Colour Space Favourites'
SCRIPT_VERSION = 'v2.1.0'
SCRIPT_PATH = os.path.abspath(os.path.dirname(__file__))
CONFIG_DIR = os.path.join(SCRIPT_PATH, 'config')
CONFIG_FILE = os.path.join(CONFIG_DIR, 'colour_space_favourites.json')

FROM_FILE = 'From File or Rules'

# First-run defaults: (menu label, [candidate names, most likely first]).
# The first candidate found in the project's OCIO config is saved.
DEFAULTS = [
    ('S-Log3', [
        'Sony S-Log3 S-Gamut3.Cine', 'Sony S-Gamut3.Cine/S-Log3',
        'S-Log3 S-Gamut3.Cine', 'Sony S-Log3 S-Gamut3', 'Sony S-Gamut3/S-Log3',
        'S-Log3 S-Gamut3', 'SLog3 / SGamut3.Cine', 'SLog3 / SGamut3',
    ]),
    ('Rec.709', ['Rec.709 video', 'Rec.1886 Rec.709 - Display', 'Rec.709']),
    ('ACEScg', ['ACEScg', 'ACES - ACEScg']),
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _log(msg):
    print(f'[{SCRIPT_NAME}] {msg}')


def _console(msg, kind='info'):
    try:
        flame.messages.show_in_console(f'{SCRIPT_NAME}: {msg}', kind, 5)
    except Exception:  # noqa: BLE001
        _log(msg)


def _dialog(msg, kind='error'):
    try:
        flame.messages.show_in_dialog(SCRIPT_NAME, msg, kind, ['Ok'])
    except Exception:  # noqa: BLE001
        _log(msg)


def project_colour_spaces():
    """List of (name, family) from the current project's OCIO config, plus a
    {lowercase name/alias: name} lookup. Empty if the config can't be read."""
    try:
        import PyOpenColorIO as ocio
        prj = flame.projects.current_project
        path = os.path.realpath(
            os.path.join(prj.setups_folder, 'colour_mgmt', 'config.ocio'))
        cfg = ocio.Config.CreateFromFile(path)
        spaces, lookup = [], {}
        for cs in cfg.getColorSpaces():
            name = cs.getName()
            spaces.append((name, cs.getFamily() or ''))
            lookup[name.lower()] = name
            for alias in cs.getAliases():
                lookup[alias.lower()] = name
        return spaces, lookup
    except Exception as e:  # noqa: BLE001
        _log(f'Could not read OCIO config: {e}')
        return [], {}


def _default_favourites():
    _, lookup = project_colour_spaces()
    favs = []
    for label, candidates in DEFAULTS:
        chosen = next((lookup[c.lower()] for c in candidates if c.lower() in lookup),
                      candidates[0])
        favs.append({'label': label, 'colour_space': chosen})
    return favs


def load_favourites():
    try:
        with open(CONFIG_FILE, 'r') as f:
            data = json.load(f)
        favs = [
            {'label': str(d['label']), 'colour_space': str(d['colour_space'])}
            for d in data.get('favourites', [])
            if d.get('label') and d.get('colour_space')
        ]
        return favs
    except FileNotFoundError:
        favs = _default_favourites()
        save_favourites(favs)
        return favs
    except Exception as e:  # noqa: BLE001
        _log(f'Could not read {CONFIG_FILE} ({e}); using defaults.')
        return _default_favourites()


def save_favourites(favs):
    try:
        os.makedirs(CONFIG_DIR, exist_ok=True)
        tmp = CONFIG_FILE + '.tmp'
        with open(tmp, 'w') as f:
            json.dump({'version': SCRIPT_VERSION, 'favourites': favs}, f, indent=4)
        os.replace(tmp, CONFIG_FILE)
        return True
    except Exception as e:  # noqa: BLE001
        _dialog(f'Could not save favourites:\n{e}')
        return False


def refresh_hooks():
    """Rebuild Flame's Python menus so edited favourites show up immediately."""
    try:
        flame.execute_shortcut('Rescan Python Hooks')
    except Exception:  # noqa: BLE001
        _console('Saved. Use Python > Refresh Python Hooks to update the menu.')


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------
def set_tagged_colour_space(colour_space):
    try:
        flame.mediahub.files.options.set_tagged_colour_space(colour_space)
    except Exception as e:  # noqa: BLE001
        _dialog(
            f'"{colour_space}" is not available in this project\'s colour config.\n\n'
            f'({e})\n\nUse Higgins Post > Colour Space Favourites... to pick a valid one.')
        return
    _console(f'MediaHub set to Tag Only: {colour_space}')


def _make_action(colour_space):
    def execute(selection):  # selection unused; the option is global to MediaHub
        set_tagged_colour_space(colour_space)
    return execute


# ---------------------------------------------------------------------------
# Editor window
# ---------------------------------------------------------------------------
def _qt():
    try:
        from PySide6 import QtCore, QtWidgets
    except ImportError:
        from PySide2 import QtCore, QtWidgets
    return QtCore, QtWidgets


def edit_favourites(selection=None):
    QtCore, QtWidgets = _qt()
    spaces, _ = project_colour_spaces()
    favs = load_favourites()

    parent = QtWidgets.QApplication.activeWindow()
    dlg = QtWidgets.QDialog(parent)
    dlg.setWindowTitle(f'{SCRIPT_NAME} {SCRIPT_VERSION}')
    dlg.setMinimumSize(900, 520)

    # --- Left: favourites table (label editable, colour space read-only) ---
    fav_table = QtWidgets.QTableWidget(0, 2)
    fav_table.setHorizontalHeaderLabels(['Menu Label (double-click to rename)', 'Colour Space'])
    fav_table.horizontalHeader().setStretchLastSection(True)
    fav_table.horizontalHeader().resizeSection(0, 220)
    fav_table.verticalHeader().setVisible(False)
    fav_table.setSelectionBehavior(QtWidgets.QAbstractItemView.SelectRows)
    fav_table.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)

    def add_row(label, cs, row=None):
        row = fav_table.rowCount() if row is None else row
        fav_table.insertRow(row)
        lbl = QtWidgets.QTableWidgetItem(label)
        csi = QtWidgets.QTableWidgetItem(cs)
        csi.setFlags(csi.flags() & ~QtCore.Qt.ItemIsEditable)
        fav_table.setItem(row, 0, lbl)
        fav_table.setItem(row, 1, csi)
        return row

    for f in favs:
        add_row(f['label'], f['colour_space'])

    def move(step):
        row = fav_table.currentRow()
        new = row + step
        if row < 0 or not (0 <= new < fav_table.rowCount()):
            return
        label = fav_table.item(row, 0).text()
        cs = fav_table.item(row, 1).text()
        fav_table.removeRow(row)
        add_row(label, cs, new)
        fav_table.selectRow(new)

    def remove():
        row = fav_table.currentRow()
        if row >= 0:
            fav_table.removeRow(row)

    up_btn = QtWidgets.QPushButton('Move Up')
    down_btn = QtWidgets.QPushButton('Move Down')
    remove_btn = QtWidgets.QPushButton('Remove')
    up_btn.clicked.connect(lambda: move(-1))
    down_btn.clicked.connect(lambda: move(1))
    remove_btn.clicked.connect(remove)

    left = QtWidgets.QVBoxLayout()
    left.addWidget(QtWidgets.QLabel('Favourites (menu order)'))
    left.addWidget(fav_table)
    row_btns = QtWidgets.QHBoxLayout()
    for b in (up_btn, down_btn, remove_btn):
        row_btns.addWidget(b)
    left.addLayout(row_btns)

    # --- Right: all colour spaces in the project config, filterable ---
    filter_edit = QtWidgets.QLineEdit()
    filter_edit.setPlaceholderText('Filter, e.g. log3, 709, aces')
    all_list = QtWidgets.QListWidget()
    for name, family in spaces:
        item = QtWidgets.QListWidgetItem(name)
        item.setToolTip(family)
        item.setData(QtCore.Qt.UserRole, f'{name} {family}'.lower())
        all_list.addItem(item)
    if not spaces:
        all_list.addItem('(Could not read the project colour config)')

    def apply_filter(text):
        words = text.lower().split()
        for i in range(all_list.count()):
            it = all_list.item(i)
            hay = it.data(QtCore.Qt.UserRole) or ''
            it.setHidden(bool(words) and not all(w in hay for w in words))

    filter_edit.textChanged.connect(apply_filter)

    def add_selected():
        it = all_list.currentItem()
        if not it or not spaces:
            return
        cs = it.text()
        existing = [fav_table.item(r, 1).text() for r in range(fav_table.rowCount())]
        if cs in existing:
            fav_table.selectRow(existing.index(cs))
            return
        row = add_row(cs, cs)
        fav_table.selectRow(row)

    add_btn = QtWidgets.QPushButton('<<  Add to Favourites')
    add_btn.clicked.connect(add_selected)
    all_list.itemDoubleClicked.connect(lambda _it: add_selected())

    right = QtWidgets.QVBoxLayout()
    right.addWidget(QtWidgets.QLabel('All colour spaces in this project (double-click to add)'))
    right.addWidget(filter_edit)
    right.addWidget(all_list)
    right.addWidget(add_btn)

    # --- Bottom: Save / Cancel ---
    save_btn = QtWidgets.QPushButton('Save')
    cancel_btn = QtWidgets.QPushButton('Cancel')
    save_btn.setDefault(True)
    cancel_btn.clicked.connect(dlg.reject)

    def save():
        out = []
        for r in range(fav_table.rowCount()):
            label = fav_table.item(r, 0).text().strip()
            cs = fav_table.item(r, 1).text()
            out.append({'label': label or cs, 'colour_space': cs})
        if save_favourites(out):
            dlg.accept()

    save_btn.clicked.connect(save)

    bottom = QtWidgets.QHBoxLayout()
    bottom.addStretch(1)
    bottom.addWidget(cancel_btn)
    bottom.addWidget(save_btn)

    columns = QtWidgets.QHBoxLayout()
    columns.addLayout(left, 3)
    columns.addLayout(right, 2)
    main = QtWidgets.QVBoxLayout(dlg)
    main.addLayout(columns)
    main.addLayout(bottom)

    run = getattr(dlg, 'exec', None) or dlg.exec_
    if run():
        refresh_hooks()
        _console('Favourites saved.')


# ---------------------------------------------------------------------------
# Flame hook
# ---------------------------------------------------------------------------
def get_mediahub_files_custom_ui_actions():
    # MediaHub > Files > right-click > Colour Space... > favourites
    actions = [
        {
            'name': f['label'],
            'execute': _make_action(f['colour_space']),
            'minimumVersion': '2023.2',
        }
        for f in load_favourites()
    ]
    actions.append({
        'name': FROM_FILE,
        'execute': _make_action(FROM_FILE),
        'minimumVersion': '2023.2',
    })
    return [{'name': 'Colour Space...', 'actions': actions}]


def get_main_menu_custom_ui_actions():
    # Flame main menu > Higgins Post > Colour Space Favourites... (the setup/editor)
    return [{
        'name': 'Higgins Post',
        'hierarchy': [],
        'actions': [{
            'name': 'Colour Space Favourites...',
            'execute': edit_favourites,
            'minimumVersion': '2023.2',
        }],
    }]

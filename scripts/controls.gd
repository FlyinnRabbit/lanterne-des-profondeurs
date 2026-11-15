extends Node
# Autoload « Controls » : touches par défaut, réaffectation, sauvegarde,
# noms des boutons façon manette Xbox (XInput) et vibrations.

signal bindings_changed
signal device_changed(using_pad: bool)

const Paths = preload("res://scripts/paths.gd")
const SAVE_NAME := "controls.cfg"   # voir paths.gd (mode portable)
const SAVE_VERSION := 2   # v2 : boutons de souris dans les cases « Touche »

# Les cases « Touche » acceptent aussi la souris : un bouton de souris est stocké
# comme un nombre négatif (-1 clic gauche, -2 clic droit, -3 clic milieu, -8/-9 boutons latéraux).
const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "Clic gauche", MOUSE_BUTTON_RIGHT: "Clic droit",
	MOUSE_BUTTON_MIDDLE: "Clic milieu", MOUSE_BUTTON_XBUTTON1: "Souris 4", MOUSE_BUTTON_XBUTTON2: "Souris 5",
}
const CURSOR_HIDE_DELAY := 2.0
var cursor_idle := 0.0

# Ordre et noms affichés dans le menu
const ACTIONS := ["move_left", "move_right", "up", "down", "jump", "attack", "dash", "parry", "ultimate", "focus", "inventory"]
const LABELS := {
	"move_left": "Gauche", "move_right": "Droite", "up": "Haut / Banc", "down": "Bas",
	"jump": "Sauter", "attack": "Frapper", "dash": "Ruée / Esquive", "parry": "Parade",
	"ultimate": "Ultime", "focus": "Se soigner", "inventory": "Inventaire",
}

var DEFAULT_KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE, KEY_NONE], "attack": [KEY_J, -MOUSE_BUTTON_LEFT],
	"dash": [KEY_K, KEY_SHIFT], "parry": [KEY_I, -MOUSE_BUTTON_RIGHT],
	"ultimate": [KEY_U, KEY_R], "focus": [KEY_L, KEY_F],
	"inventory": [KEY_TAB, KEY_B],
}
var DEFAULT_PAD := {
	"move_left": {"type": "button", "index": JOY_BUTTON_DPAD_LEFT},
	"move_right": {"type": "button", "index": JOY_BUTTON_DPAD_RIGHT},
	"up": {"type": "button", "index": JOY_BUTTON_DPAD_UP},
	"down": {"type": "button", "index": JOY_BUTTON_DPAD_DOWN},
	"jump": {"type": "button", "index": JOY_BUTTON_A},
	"attack": {"type": "button", "index": JOY_BUTTON_X},
	"dash": {"type": "axis", "axis": JOY_AXIS_TRIGGER_RIGHT, "dir": 1},
	"parry": {"type": "button", "index": JOY_BUTTON_LEFT_SHOULDER},
	"ultimate": {"type": "button", "index": JOY_BUTTON_Y},
	"focus": {"type": "button", "index": JOY_BUTTON_B},
	"inventory": {"type": "button", "index": JOY_BUTTON_BACK},
}
# Le stick gauche reste toujours actif pour se déplacer, en plus des réglages.
const STICK := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0],
}

const PAD_BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "View", JOY_BUTTON_GUIDE: "Xbox", JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Croix haut", JOY_BUTTON_DPAD_DOWN: "Croix bas",
	JOY_BUTTON_DPAD_LEFT: "Croix gauche", JOY_BUTTON_DPAD_RIGHT: "Croix droite",
}

var keys := {}       # action -> [keycode physique 1, keycode physique 2]
var pad := {}        # action -> {"type": "button"/"axis", ...}
var vibration := true
var using_pad := false
var pad_kind := "xbox"     # détecté : "xbox" ou "ps"

# Noms PlayStation (DualShock 4 / DualSense)
const PS_BUTTON_NAMES := {
	JOY_BUTTON_A: "Croix", JOY_BUTTON_B: "Rond", JOY_BUTTON_X: "Carré", JOY_BUTTON_Y: "Triangle",
	JOY_BUTTON_BACK: "Create", JOY_BUTTON_GUIDE: "PS", JOY_BUTTON_START: "Options",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "L1", JOY_BUTTON_RIGHT_SHOULDER: "R1",
	JOY_BUTTON_DPAD_UP: "Flèche haut", JOY_BUTTON_DPAD_DOWN: "Flèche bas",
	JOY_BUTTON_DPAD_LEFT: "Flèche gauche", JOY_BUTTON_DPAD_RIGHT: "Flèche droite",
	JOY_BUTTON_TOUCHPAD: "Pavé tactile",
}

static func detect_kind(joy_name: String) -> String:
	var n := joy_name.to_lower()
	for k in ["ps4", "ps5", "ps3", "dualsense", "dualshock", "sony", "playstation", "wireless controller"]:
		if n.contains(k):
			return "ps"
	return "xbox"

# Style de noms à afficher pour la manette : réglage Options, sinon détection automatique
func pad_style() -> String:
	match int(Settings.pad_style):
		1: return "xbox"
		2: return "ps"
	return pad_kind

# Libellé du périphérique actuel : « Clavier / souris », « Manette Xbox », « Manette PlayStation »
func device_label() -> String:
	if not using_pad:
		return "Clavier / souris"
	return "Manette PlayStation" if pad_style() == "ps" else "Manette Xbox"

# Touche de pause selon le périphérique
func pause_label() -> String:
	if not using_pad:
		return "Échap / P"
	return "Options" if pad_style() == "ps" else "Menu"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		pad_kind = detect_kind(Input.get_joy_name(pads[0]))
	# Sur Steam Deck, les commandes intégrées sont une manette : on affiche ses boutons d'emblée
	if Settings.is_steam_deck():
		using_pad = true
	reset_defaults(false)
	load_settings()
	apply()

func reset_defaults(save := true) -> void:
	keys = DEFAULT_KEYS.duplicate(true)
	pad = DEFAULT_PAD.duplicate(true)
	if save:
		apply()
		save_settings()

# ---------------------------------------------------------------- InputMap
func apply() -> void:
	for a in ACTIONS:
		if InputMap.has_action(a):
			InputMap.action_erase_events(a)
		else:
			InputMap.add_action(a, 0.4)
		for k in keys[a]:
			if k == KEY_NONE:
				continue
			if k < 0:
				var mb := InputEventMouseButton.new()
				mb.button_index = -k
				InputMap.action_add_event(a, mb)
			else:
				var ev := InputEventKey.new()
				ev.device = -1
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)
		var pe := pad_event(pad[a])
		if pe:
			InputMap.action_add_event(a, pe)
		if STICK.has(a):
			var jm := InputEventJoypadMotion.new()
			jm.device = -1
			jm.axis = STICK[a][0]
			jm.axis_value = STICK[a][1]
			InputMap.action_add_event(a, jm)
	# Menus à la manette : A valide, B revient en arrière (Godot ne le fait pas par défaut)
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var exists := false
		for e in InputMap.action_get_events(pair[0]):
			if e is InputEventJoypadButton and e.button_index == pair[1]:
				exists = true
		if not exists:
			var jb := InputEventJoypadButton.new()
			jb.device = -1
			jb.button_index = pair[1]
			InputMap.action_add_event(pair[0], jb)
	# Menu : Échap / bouton Menu de la manette (non modifiable)
	if not InputMap.has_action("pause_menu"):
		InputMap.add_action("pause_menu")
		for k in [KEY_ESCAPE, KEY_P]:
			var esc := InputEventKey.new()
			esc.physical_keycode = k
			InputMap.action_add_event("pause_menu", esc)
		var st := InputEventJoypadButton.new()
		st.device = -1
		st.button_index = JOY_BUTTON_START
		InputMap.action_add_event("pause_menu", st)
	bindings_changed.emit()

func pad_event(d: Dictionary) -> InputEvent:
	if d.is_empty():
		return null
	if d["type"] == "button":
		var b := InputEventJoypadButton.new()
		b.device = -1
		b.button_index = int(d["index"])
		return b
	var m := InputEventJoypadMotion.new()
	m.device = -1
	m.axis = int(d["axis"])
	m.axis_value = float(d["dir"])
	return m

# ---------------------------------------------------------------- réaffectation
# slot 0 et 1 : clavier, slot 2 : manette. Si l'entrée est déjà utilisée ailleurs, on échange.
func rebind_key(action: String, slot: int, keycode: int) -> void:
	var old: int = keys[action][slot]
	for a in ACTIONS:
		for s in 2:
			if keys[a][s] == keycode and not (a == action and s == slot):
				keys[a][s] = old
	keys[action][slot] = keycode
	apply()
	save_settings()

func rebind_pad(action: String, d: Dictionary) -> void:
	var old: Dictionary = pad[action]
	for a in ACTIONS:
		if a != action and _same_pad(pad[a], d):
			pad[a] = old
	pad[action] = d
	apply()
	save_settings()

func clear_key(action: String, slot: int) -> void:
	keys[action][slot] = KEY_NONE
	apply()
	save_settings()

func _same_pad(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty() or a["type"] != b["type"]:
		return false
	if a["type"] == "button":
		return int(a["index"]) == int(b["index"])
	return int(a["axis"]) == int(b["axis"]) and signf(float(a["dir"])) == signf(float(b["dir"]))

static func event_to_pad(ev: InputEvent) -> Dictionary:
	if ev is InputEventJoypadButton and ev.pressed:
		if ev.button_index == JOY_BUTTON_START:
			return {}
		return {"type": "button", "index": ev.button_index}
	if ev is InputEventJoypadMotion and absf(ev.axis_value) > 0.6:
		return {"type": "axis", "axis": ev.axis, "dir": 1 if ev.axis_value > 0 else -1}
	return {}

# ---------------------------------------------------------------- noms affichés
# Code stockable pour un bouton de souris (0 si non utilisable, ex. molette)
static func mouse_code(ev: InputEventMouseButton) -> int:
	if ev.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
		return -ev.button_index
	return 0

func key_name(k: int) -> String:
	if k == KEY_NONE:
		return "—"
	if k < 0:
		return MOUSE_NAMES.get(-k, "Souris %d" % -k)
	var local := DisplayServer.keyboard_get_keycode_from_physical(k)
	var s := OS.get_keycode_string(local)
	return s if s != "" else OS.get_keycode_string(k)

func pad_name(d: Dictionary) -> String:
	if d.is_empty():
		return "—"
	var ps := pad_style() == "ps"
	if d["type"] == "button":
		var names: Dictionary = PS_BUTTON_NAMES if ps else PAD_BUTTON_NAMES
		return names.get(int(d["index"]), "Bouton %d" % int(d["index"]))
	var axis := int(d["axis"])
	var pos: bool = float(d["dir"]) > 0
	match axis:
		JOY_AXIS_TRIGGER_LEFT: return "L2" if ps else "LT"
		JOY_AXIS_TRIGGER_RIGHT: return "R2" if ps else "RT"
		JOY_AXIS_LEFT_X: return "Stick G " + ("droite" if pos else "gauche")
		JOY_AXIS_LEFT_Y: return "Stick G " + ("bas" if pos else "haut")
		JOY_AXIS_RIGHT_X: return "Stick D " + ("droite" if pos else "gauche")
		JOY_AXIS_RIGHT_Y: return "Stick D " + ("bas" if pos else "haut")
	return "Axe %d %s" % [axis, "+" if pos else "-"]

# Nom court de la commande principale, selon le périphérique utilisé en dernier
func label(action: String) -> String:
	if using_pad:
		return pad_name(pad[action])
	for k in keys[action]:
		if k != KEY_NONE:
			return key_name(k)
	return "—"

# Toutes les commandes clavier/souris d'une action (« J / Clic gauche »), ou celle de la manette
func label_all(action: String) -> String:
	if using_pad:
		return pad_name(pad[action])
	var parts := []
	for k in keys[action]:
		if k != KEY_NONE:
			parts.append(key_name(k))
	return " / ".join(parts) if not parts.is_empty() else "—"

func pad_description() -> String:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return "Aucune manette détectée"
	var parts := []
	for id in pads:
		var n := Input.get_joy_name(id)
		var tag := " (PlayStation)" if detect_kind(n) == "ps" else " (Xbox / XInput)"
		parts.append(n + tag)
	return "Manette : " + ", ".join(parts)

# ---------------------------------------------------------------- vibrations
func rumble(weak: float, strong: float, duration: float) -> void:
	if not vibration:
		return
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(id, clampf(weak, 0.0, 1.0), clampf(strong, 0.0, 1.0), duration)

# ---------------------------------------------------------------- détection du périphérique
func _process(delta: float) -> void:
	# Curseur visible dans les menus ; caché en jeu après 2 s sans bouger la souris
	cursor_idle += delta
	var want_hidden := not get_tree().paused and cursor_idle > CURSOR_HIDE_DELAY
	var mode := Input.MOUSE_MODE_HIDDEN if want_hidden else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode:
		Input.mouse_mode = mode

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cursor_idle = 0.0
	var pad_now := using_pad
	var kind := pad_kind
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		pad_now = true
		kind = detect_kind(Input.get_joy_name(event.device))
	elif event is InputEventKey or event is InputEventMouseButton:
		pad_now = false
	if pad_now != using_pad or kind != pad_kind:
		using_pad = pad_now
		pad_kind = kind
		device_changed.emit(using_pad)

# ---------------------------------------------------------------- sauvegarde
func save_settings() -> void:
	var cfg := ConfigFile.new()
	for a in ACTIONS:
		cfg.set_value("keys", a, keys[a])
		cfg.set_value("pad", a, pad[a])
	cfg.set_value("options", "vibration", vibration)
	cfg.set_value("meta", "version", SAVE_VERSION)
	cfg.save(Paths.file(SAVE_NAME))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(Paths.file(SAVE_NAME)) != OK:
		return
	vibration = cfg.get_value("options", "vibration", true)
	if int(cfg.get_value("meta", "version", 1)) < SAVE_VERSION:
		return   # ancienne sauvegarde : on repart des touches par défaut (avec la souris)
	for a in ACTIONS:
		if not cfg.has_section_key("keys", a):
			continue   # action ajoutée après la sauvegarde : on garde le défaut
		var k = cfg.get_value("keys", a, null)
		if k is Array and k.size() == 2:
			keys[a] = [int(k[0]), int(k[1])]
		var p = cfg.get_value("pad", a, null)
		if p is Dictionary:
			pad[a] = p
	vibration = cfg.get_value("options", "vibration", true)

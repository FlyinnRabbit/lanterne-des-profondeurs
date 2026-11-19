extends Control
# Onglets des menus : indication LB / RB (L1 / R1, ou Q / E au clavier) de part et d'autre d'une
# rangée d'onglets, et lecture de ces boutons pour passer à l'onglet précédent / suivant.

const G = preload("res://scripts/glyphs.gd")

var right := false

static func make(is_right: bool) -> Control:
	var h = load("res://scripts/menu_tabs.gd").new()
	h.right = is_right
	h.custom_minimum_size = Vector2(48, 36)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h

func _process(_d: float) -> void:
	if is_visible_in_tree():
		queue_redraw()     # suit le passage clavier <-> manette

func _draw() -> void:
	var c = get_node_or_null("/root/Controls")
	var g: Dictionary
	if c and c.using_pad:
		g = {"pad": {"type": "button", "index": JOY_BUTTON_RIGHT_SHOULDER if right else JOY_BUTTON_LEFT_SHOULDER}}
	else:
		g = {"key": KEY_E if right else KEY_Q}
	var font := get_theme_default_font()
	var h := size.y * 0.72
	var w := G.width(g, h, font)
	G.draw(self, (size.x - w) / 2.0, size.y / 2.0, h, g, font)

# -1 : onglet précédent, +1 : suivant, 0 : autre touche
static func step(event: InputEvent) -> int:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			return -1
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			return 1
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q, KEY_PAGEUP:
				return -1
			KEY_E, KEY_PAGEDOWN:
				return 1
	return 0

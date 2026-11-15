# Icônes de commandes dessinées en code : touches de clavier, boutons de souris,
# boutons de manette façon Xbox (A B X Y colorés, LB/RT…) ou PlayStation (croix, rond,
# carré, triangle, L1/R2…). Symboles génériques, pas les logos des marques.
#
# draw_rich() dessine une ligne de texte où {action} est remplacé par l'icône de la touche
# réglée pour cette action (et {pause} par la touche de pause).

const XBOX_FACE := {
	JOY_BUTTON_A: ["A", Color(0.36, 0.78, 0.3)], JOY_BUTTON_B: ["B", Color(0.92, 0.3, 0.25)],
	JOY_BUTTON_X: ["X", Color(0.25, 0.52, 1.0)], JOY_BUTTON_Y: ["Y", Color(1.0, 0.78, 0.18)],
}
const PS_FACE := {
	JOY_BUTTON_A: ["cross", Color(0.5, 0.65, 1.0)], JOY_BUTTON_B: ["circle", Color(1.0, 0.4, 0.45)],
	JOY_BUTTON_X: ["square", Color(1.0, 0.55, 0.82)], JOY_BUTTON_Y: ["triangle", Color(0.3, 0.88, 0.62)],
}
const DARK := Color(0.1, 0.1, 0.14)
const LIGHT := Color(0.9, 0.92, 0.97)

# ---------------------------------------------------------------- quelles icônes ?
static func for_action(action: String) -> Array:
	var c = Engine.get_main_loop().root.get_node("Controls")
	if action == "pause":
		if c.using_pad:
			return [{"pad": {"type": "button", "index": JOY_BUTTON_START}}]
		return [{"key": KEY_ESCAPE}, {"key": KEY_P}]
	if not c.ACTIONS.has(action):
		return []
	if c.using_pad:
		return [{"pad": c.pad[action]}]
	var out := []
	for k in c.keys[action]:
		if k != KEY_NONE:
			out.append({"key": k})
	return out

static func _style() -> String:
	return Engine.get_main_loop().root.get_node("Controls").pad_style()

# ---------------------------------------------------------------- mesures
static func width(g: Dictionary, h: float, font: Font) -> float:
	if g.has("key"):
		var k: int = g["key"]
		if k < 0 and -k in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			return h * 0.75
		var t := _key_text(k)
		return maxf(h, font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, int(h * 0.5)).x + h * 0.55)
	var d: Dictionary = g["pad"]
	var kind := _pad_kind(d)
	match kind:
		"shoulder", "trigger", "menu":
			return h * 1.45
	return h

static func _key_text(k: int) -> String:
	var c = Engine.get_main_loop().root.get_node("Controls")
	if k < 0:
		return "M%d" % -k
	var t: String = c.key_name(k)
	match t:
		"Escape": return TranslationServer.translate("Échap")
		"Space": return TranslationServer.translate("Espace")
		"Shift": return TranslationServer.translate("Maj")
		"Enter": return TranslationServer.translate("Entrée")
		"Tab": return "Tab"
		"Left": return "←"
		"Right": return "→"
		"Up": return "↑"
		"Down": return "↓"
	return t

static func _pad_kind(d: Dictionary) -> String:
	if d.is_empty():
		return "none"
	if d["type"] == "axis":
		var a := int(d["axis"])
		if a == JOY_AXIS_TRIGGER_LEFT or a == JOY_AXIS_TRIGGER_RIGHT:
			return "trigger"
		return "stick"
	var i := int(d["index"])
	if XBOX_FACE.has(i):
		return "face"
	if i in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		return "shoulder"
	if i in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
		return "dpad"
	if i in [JOY_BUTTON_START, JOY_BUTTON_BACK, JOY_BUTTON_GUIDE, JOY_BUTTON_TOUCHPAD]:
		return "menu"
	if i in [JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK]:
		return "stickpress"
	return "other"

# ---------------------------------------------------------------- dessin
# Dessine l'icône g dont le bord gauche est à x et le centre vertical à y. Renvoie sa largeur.
static func draw(ci: CanvasItem, x: float, y: float, h: float, g: Dictionary, font: Font) -> float:
	var w := width(g, h, font)
	var c := Vector2(x + w / 2.0, y)
	if g.has("key"):
		var k: int = g["key"]
		if k < 0 and -k in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_mouse(ci, c, h, -k)
		else:
			_keycap(ci, Rect2(x, y - h / 2.0, w, h), _key_text(k), font)
		return w
	var d: Dictionary = g["pad"]
	var ps := _style() == "ps"
	match _pad_kind(d):
		"face":
			var i := int(d["index"])
			var r := h / 2.0
			ci.draw_circle(c, r, DARK)
			if ps:
				var f: Array = PS_FACE[i]
				ci.draw_arc(c, r - 1.0, 0.0, TAU, 24, Color(0.35, 0.36, 0.42), 1.5)
				_ps_symbol(ci, c, r * 0.5, f[0], f[1])
			else:
				var f: Array = XBOX_FACE[i]
				ci.draw_circle(c, r - 2.0, f[1].darkened(0.55))
				ci.draw_arc(c, r - 1.0, 0.0, TAU, 24, f[1], 2.0)
				_text(ci, font, c, f[0], int(h * 0.6), f[1].lightened(0.3))
		"shoulder":
			var right := int(d["index"]) == JOY_BUTTON_RIGHT_SHOULDER
			var rr := Rect2(x, y - h * 0.32, w, h * 0.64)
			_rounded(ci, rr, DARK, Color(0.6, 0.62, 0.7))
			_text(ci, font, rr.get_center(), ("R1" if right else "L1") if ps else ("RB" if right else "LB"), int(h * 0.45), LIGHT)
		"trigger":
			var right := int(d["axis"]) == JOY_AXIS_TRIGGER_RIGHT
			var pts := PackedVector2Array([Vector2(x + w * 0.15, y - h / 2.0), Vector2(x + w * 0.85, y - h / 2.0),
				Vector2(x + w, y - h * 0.1), Vector2(x + w, y + h / 2.0), Vector2(x, y + h / 2.0), Vector2(x, y - h * 0.1)])
			ci.draw_colored_polygon(pts, DARK)
			var outline := pts.duplicate()
			outline.append(pts[0])
			ci.draw_polyline(outline, Color(0.6, 0.62, 0.7), 1.5)
			_text(ci, font, c + Vector2(0, h * 0.05), ("R2" if right else "L2") if ps else ("RT" if right else "LT"), int(h * 0.45), LIGHT)
		"dpad":
			var i := int(d["index"])
			var a := h * 0.17
			var l := h * 0.48
			var base := Color(0.32, 0.33, 0.4)
			ci.draw_rect(Rect2(c.x - a, c.y - l, a * 2, l * 2), base)
			ci.draw_rect(Rect2(c.x - l, c.y - a, l * 2, a * 2), base)
			var dir := {JOY_BUTTON_DPAD_UP: Vector2.UP, JOY_BUTTON_DPAD_DOWN: Vector2.DOWN,
				JOY_BUTTON_DPAD_LEFT: Vector2.LEFT, JOY_BUTTON_DPAD_RIGHT: Vector2.RIGHT}[i] as Vector2
			var arm := Rect2(c + dir * (l - a) - Vector2(a, a), Vector2(a * 2, a * 2))
			ci.draw_rect(arm, LIGHT)
		"stick", "stickpress":
			var r := h / 2.0
			ci.draw_circle(c, r, DARK)
			ci.draw_arc(c, r - 1.0, 0.0, TAU, 24, Color(0.6, 0.62, 0.7), 2.0)
			ci.draw_arc(c, r * 0.55, 0.0, TAU, 20, Color(0.45, 0.47, 0.55), 1.5)
			var left := true
			if d["type"] == "axis":
				left = int(d["axis"]) in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]
				var ax := int(d["axis"])
				var dv := Vector2(float(d["dir"]), 0) if ax in [JOY_AXIS_LEFT_X, JOY_AXIS_RIGHT_X] else Vector2(0, float(d["dir"]))
				var tip := c + dv * r * 0.95
				var side := Vector2(-dv.y, dv.x) * r * 0.28
				ci.draw_colored_polygon(PackedVector2Array([tip, tip - dv * r * 0.35 + side, tip - dv * r * 0.35 - side]), LIGHT)
			else:
				left = int(d["index"]) == JOY_BUTTON_LEFT_STICK
			_text(ci, font, c, ("L" if left else "R") + ("3" if d["type"] == "button" else ""), int(h * 0.4), LIGHT)
		"menu":
			var i := int(d["index"])
			var rr := Rect2(x, y - h * 0.3, w, h * 0.6)
			_rounded(ci, rr, DARK, Color(0.6, 0.62, 0.7))
			var cc := rr.get_center()
			if i == JOY_BUTTON_START:
				for k in 3:
					ci.draw_line(cc + Vector2(-h * 0.2, (k - 1) * h * 0.11), cc + Vector2(h * 0.2, (k - 1) * h * 0.11), LIGHT, 1.8)
			elif i == JOY_BUTTON_BACK:
				if ps:
					for k in 3:
						var a := -PI / 2.0 + (k - 1) * 0.6
						ci.draw_line(cc + Vector2(0, h * 0.12), cc + Vector2(0, h * 0.12) + Vector2.from_angle(a) * h * 0.24, LIGHT, 1.8)
				else:
					ci.draw_rect(Rect2(cc + Vector2(-h * 0.2, -h * 0.13), Vector2(h * 0.25, h * 0.18)), LIGHT, false, 1.5)
					ci.draw_rect(Rect2(cc + Vector2(-h * 0.08, -h * 0.05), Vector2(h * 0.25, h * 0.18)), LIGHT, false, 1.5)
			elif ps:
				_text(ci, font, cc, "PS", int(h * 0.35), LIGHT)
			else:
				ci.draw_circle(cc, h * 0.14, LIGHT)
		_:
			var r := h / 2.0
			ci.draw_circle(c, r, DARK)
			_text(ci, font, c, "?", int(h * 0.5), LIGHT)
	return w

static func _rounded(ci: CanvasItem, r: Rect2, fill: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(int(r.size.y * 0.35))
	ci.draw_style_box(sb, r)

static func _keycap(ci: CanvasItem, r: Rect2, t: String, font: Font) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.88, 0.93)
	sb.border_color = Color(0.55, 0.57, 0.65)
	sb.set_border_width_all(1)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(5)
	ci.draw_style_box(sb, r)
	var arrows := {"←": Vector2.LEFT, "→": Vector2.RIGHT, "↑": Vector2.UP, "↓": Vector2.DOWN}
	if arrows.has(t):
		var dv: Vector2 = arrows[t]
		var c := r.get_center() - Vector2(0, 1.5)
		var s := r.size.y * 0.22
		var side := Vector2(-dv.y, dv.x) * s
		ci.draw_colored_polygon(PackedVector2Array([c + dv * s, c - dv * s + side, c - dv * s - side]), Color(0.12, 0.12, 0.16))
		return
	_text(ci, font, r.get_center() - Vector2(0, 1.5), t, int(r.size.y * 0.5), Color(0.12, 0.12, 0.16))

static func _mouse(ci: CanvasItem, c: Vector2, h: float, button: int) -> void:
	var w := h * 0.7
	var r := Rect2(c - Vector2(w / 2.0, h / 2.0), Vector2(w, h))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.86, 0.88, 0.93)
	sb.set_corner_radius_all(int(w * 0.5))
	ci.draw_style_box(sb, r)
	var hl := Color(1.0, 0.6, 0.25)
	var top := Rect2(r.position + Vector2(2, 2), Vector2(w / 2.0 - 2.5, h * 0.42))
	if button == MOUSE_BUTTON_LEFT:
		var s2 := StyleBoxFlat.new()
		s2.bg_color = hl
		s2.corner_radius_top_left = int(w * 0.45)
		ci.draw_style_box(s2, top)
	elif button == MOUSE_BUTTON_RIGHT:
		var s3 := StyleBoxFlat.new()
		s3.bg_color = hl
		s3.corner_radius_top_right = int(w * 0.45)
		ci.draw_style_box(s3, Rect2(top.position + Vector2(w / 2.0 - 1.0, 0), top.size))
	ci.draw_line(c + Vector2(0, -h / 2.0), c + Vector2(0, -h * 0.08), Color(0.4, 0.42, 0.5), 1.5)
	ci.draw_line(c + Vector2(-w / 2.0, -h * 0.08), c + Vector2(w / 2.0, -h * 0.08), Color(0.4, 0.42, 0.5), 1.5)
	ci.draw_rect(Rect2(c + Vector2(-1.5, -h * 0.36), Vector2(3, h * 0.16)), hl if button == MOUSE_BUTTON_MIDDLE else Color(0.4, 0.42, 0.5))

static func _ps_symbol(ci: CanvasItem, c: Vector2, s: float, kind: String, col: Color) -> void:
	match kind:
		"cross":
			ci.draw_line(c + Vector2(-s, -s), c + Vector2(s, s), col, 2.5)
			ci.draw_line(c + Vector2(-s, s), c + Vector2(s, -s), col, 2.5)
		"circle":
			ci.draw_arc(c, s, 0.0, TAU, 20, col, 2.5)
		"square":
			ci.draw_rect(Rect2(c - Vector2(s, s) * 0.85, Vector2(s, s) * 1.7), col, false, 2.5)
		"triangle":
			var p := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.95, s * 0.7), c + Vector2(-s * 0.95, s * 0.7), c + Vector2(0, -s)])
			ci.draw_polyline(p, col, 2.5)

static func _text(ci: CanvasItem, font: Font, center: Vector2, t: String, size: int, col: Color) -> void:
	var sz := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	ci.draw_string(font, center + Vector2(-sz.x / 2.0, size * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# ---------------------------------------------------------------- texte enrichi
# Découpe « Appuie sur {jump} pour sauter » en morceaux de texte et d'icônes.
static func _segments(text: String) -> Array:
	var out := []
	var i := 0
	while i < text.length():
		var a := text.find("{", i)
		if a < 0:
			out.append(text.substr(i))
			break
		var b := text.find("}", a)
		if b < 0:
			out.append(text.substr(i))
			break
		if a > i:
			out.append(text.substr(i, a - i))
		# {action} : toutes les touches ; {action|1} : seulement la première
		var token := text.substr(a + 1, b - a - 1)
		var first_only := token.ends_with("|1")
		var glyphs := for_action(token.trim_suffix("|1"))
		if first_only and glyphs.size() > 1:
			glyphs = [glyphs[0]]
		if glyphs.is_empty():
			out.append(text.substr(a, b - a + 1))
		else:
			out.append(glyphs)
		i = b + 1
	return out

static func rich_width(font: Font, text: String, font_size: int) -> float:
	text = String(TranslationServer.translate(text))
	var h := font_size * 1.3
	var total := 0.0
	for seg in _segments(text):
		if seg is String:
			total += font.get_string_size(seg, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		else:
			for j in seg.size():
				total += width(seg[j], h, font) + (font.get_string_size(" / ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if j > 0 else 0.0)
	return total

# Dessine une ligne centrée dans [x, x + avail] ; y = ligne de base du texte.
static func draw_rich(ci: CanvasItem, font: Font, x: float, avail: float, y: float, text: String, font_size: int, col: Color, shadow := false) -> void:
	text = String(TranslationServer.translate(text))
	var h := font_size * 1.3
	var total := rich_width(font, text, font_size)
	var cx := x + (avail - total) / 2.0
	var mid := y - font_size * 0.35
	for seg in _segments(text):
		if seg is String:
			if shadow:
				ci.draw_string(font, Vector2(cx + 2, y + 2), seg, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, col.a * 0.7))
			ci.draw_string(font, Vector2(cx, y), seg, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
			cx += font.get_string_size(seg, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		else:
			for j in seg.size():
				if j > 0:
					ci.draw_string(font, Vector2(cx, y), " / ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
					cx += font.get_string_size(" / ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				cx += draw(ci, cx, mid, h, seg[j], font)

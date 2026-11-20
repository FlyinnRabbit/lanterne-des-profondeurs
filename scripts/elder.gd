extends CanvasLayer
# Les Mémoires de l'Ancien (Sanctuaire) : même panneau de bois cerclé de laiton que le Scriptorium.
# Onglets : Chroniques (l'histoire du monde), Habitants (le passé des PNJ), Gardiens (l'ancienne
# vie des boss) et Paroles (tout ce que les habitants t'ont dit). À gauche la liste, à droite le
# récit ; une mémoire écoutée pour la première fois rapporte quelques éclats (Lore.REWARD).

const DU = preload("res://scripts/draw_util.gd")
const G = preload("res://scripts/glyphs.gd")
const MenuTabs = preload("res://scripts/menu_tabs.gd")
const Lore = preload("res://scripts/lore.gd")
const W := 1280.0
const H := 720.0
const PANEL := Rect2(196, 20, 888, 682)
const BRASS := Color(0.72, 0.58, 0.32)
const TABS := ["Chroniques", "Habitants", "Gardiens", "Paroles"]
const LIST := Rect2(222, 168, 296, 470)
const ROW_H := 34.0
const TEXT_X := 548.0
const TEXT_W := 506.0

# ce que dit l'Ancien en t'accueillant (une phrase par palier terminé)
const GREET := [
	"« Approche, petit veilleur. Les vieux escargots n'ont que des souvenirs à offrir… mais ils en ont beaucoup. »",
	"« Tu es revenu. Bien. Chaque palier que tu franchis réveille un souvenir de plus. »",
	"« L'eau, les cloches, les prières… Assieds-toi, je vais te raconter la Citadelle. »",
	"« Tu as entendu bourdonner, n'est-ce pas ? Je sais ce qu'est devenue la Ruche. »",
	"« Les os de l'Ossuaire avaient des noms, autrefois. Je m'en souviens de quelques-uns. »",
	"« Le chemin du retour n'existe plus. Alors c'est moi qui te le raconte. »",
	"« Le Chevalier… Je lui ai serré la main avant qu'il ne descende. Elle était froide déjà. »",
	"« Tu es allé plus loin que moi, petit veilleur. Plus loin que n'importe qui. »",
]

var main
var page := 0
var sel := 0
var t := 0.0
var canvas: Control
var stage: Node2D
var portrait: Node2D = null
var toast := ""
var toast_t := 0.0
var _tab_rects := []
var _row_rects := []
var _close_rect := Rect2()
var _open_t := 0.0
var _hold_dir := Vector2i.ZERO
var _hold_t := 0.0
var _b_was := false

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.draw.connect(_draw_panel)
	canvas.gui_input.connect(_on_gui_input)
	add_child(canvas)
	stage = Node2D.new()
	add_child(stage)

# ---------------------------------------------------------------- ouverture
func greeting() -> String:
	return tr(GREET[clampi(GameState.record, 0, GREET.size() - 1)])

func open() -> void:
	get_parent().move_child(self, -1)
	_open_t = 0.15
	_b_was = Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	_hold_dir = Vector2i(0, -1) if Input.is_action_pressed("up") else Vector2i.ZERO
	visible = true
	toast = ""
	Lore.hear("L'Ancien", greeting())
	# s'ouvre sur la première mémoire pas encore écoutée
	page = 0
	sel = 0
	var found := false
	for p in 3:
		var items := _items(p)
		for i in items.size():
			if items[i]["new"]:
				page = p
				sel = i
				found = true
				break
		if found:
			break
	get_tree().paused = true
	Audio.sfx("door", 0.05, -6.0)
	_on_select()

func close() -> void:
	visible = false
	_clear_portrait()
	get_tree().paused = false

func _process(delta: float) -> void:
	if not visible:
		return
	if _open_t > 0.0:
		_open_t -= delta
	else:
		_nav_input(delta)
	t += delta
	if toast_t > 0.0:
		toast_t -= delta
	var k := _k()
	stage.scale = Vector2(k, k)
	stage.position = _off()
	if is_instance_valid(portrait):
		if "anim_t" in portrait:
			portrait.anim_t += delta
		portrait.queue_redraw()
	canvas.queue_redraw()

func _k() -> float:
	var vp: Vector2 = canvas.size
	return minf(vp.x / W, vp.y / H)

func _off() -> Vector2:
	return (canvas.size - Vector2(W, H) * _k()) / 2.0

# ---------------------------------------------------------------- contenu
# Éléments de l'onglet : {title, unlocked, new, hint, text, text_b, ids}
func _items(p: int) -> Array:
	var out := []
	var rec := GameState.record
	match p:
		0:
			for c in Lore.CHRONICLES:
				var ok := rec >= int(c["need"])
				out.append({"title": tr(c["title"]), "unlocked": ok, "new": ok and not Lore.is_read(c["id"]),
					"hint": tr("Termine le palier %d pour que l'Ancien s'en souvienne.") % int(c["need"]),
					"text": tr(c["text"]), "ids": [c["id"]]})
		1:
			for pe in Lore.PEOPLE:
				var ok := rec >= int(pe["need"])
				var ok_b: bool = pe["b"] != "" and rec >= int(pe["need_b"])
				var ids := ["p_" + pe["id"]]
				if ok_b:
					ids.append("p_" + pe["id"] + "_b")
				var fresh := false
				for id in ids:
					if not Lore.is_read(id):
						fresh = true
				var hint_b := ""
				if pe["b"] != "" and not ok_b:
					hint_b = tr("La suite de son histoire se dévoile après le palier %d.") % int(pe["need_b"])
				out.append({"title": tr(pe["name"]), "unlocked": ok, "new": ok and fresh, "prop": pe["prop"],
					"hint": tr("Pas encore arrivé au Sanctuaire : termine le palier %d.") % int(pe["need"]) if int(pe["need"]) < 7 else tr("Atteins le fond du monde."),
					"text": tr(pe["a"]), "text_b": tr(pe["b"]) if ok_b else "", "hint_b": hint_b, "ids": ids})
		2:
			for b in Lore.BOSS_ORDER:
				var ok := Lore.boss_beaten(b)
				out.append({"title": tr(GameState.BOSSES[b]["name"]), "unlocked": ok, "new": ok and not Lore.is_read("g_" + b), "boss": b,
					"hint": tr("Vaincs ce gardien : l'Ancien te dira qui il était avant la nuit."),
					"text": tr(Lore.GUARDIANS[b]), "ids": ["g_" + b]})
		3:
			var talk := Lore.talk()
			var who := talk.keys()
			who.sort()
			if who.has("L'Ancien"):
				who.erase("L'Ancien")
				who.push_front("L'Ancien")
			for w in who:
				out.append({"title": tr(w), "unlocked": true, "new": false, "lines": talk[w], "ids": []})
	return out

func _mark_read() -> void:
	var items := _items(page)
	if sel >= items.size() or not items[sel]["unlocked"]:
		return
	var gained := 0
	var rl := Lore.read_list()
	for id in items[sel]["ids"]:
		if not rl.has(id):
			rl.append(id)
			gained += Lore.REWARD
	if gained > 0 and main and main.player:
		main.player.geo += gained
		GameState.prog["geo"] = main.player.geo
		GameState.j_add("geo_in", gained)
		GameState.snapshot = GameState.prog.duplicate(true)
		GameState.save_game()
		toast = tr("« Merci de m'avoir écouté. »  +%d éclats") % gained
		toast_t = 3.0
		Audio.sfx("pickup", 0.1, -6.0)

func _on_select() -> void:
	_mark_read()
	_build_portrait()

# ---------------------------------------------------------------- portraits
func _clear_portrait() -> void:
	if is_instance_valid(portrait):
		portrait.queue_free()
	portrait = null

func _boss_script(id: String) -> Array:
	var m := {"reine": "boss_queen", "colosse": "boss_colossus", "ver": "boss_worm", "chevalier": "boss_knight", "ombre": "boss_lantern",
		"cerbere": "boss_cerberus", "centaure": "boss_centaur", "oeil": "boss_eye"}
	if m.has(id):
		return ["res://scripts/%s.gd" % m[id], 0]
	return ["res://scripts/boss.gd", 2 if id == "abbesse" else 1]

func _build_portrait() -> void:
	_clear_portrait()
	var items := _items(page)
	if sel >= items.size():
		return
	var it: Dictionary = items[sel]
	if page == 2:
		var sc := _boss_script(it["boss"])
		var n := CharacterBody2D.new()
		n.set_script(load(sc[0]))
		n.display = true
		n.main = main
		if sc[1] > 0:
			n.variant = sc[1]
		n.process_mode = Node.PROCESS_MODE_DISABLED
		stage.add_child(n)
		var big: float = maxf(n.size.x, n.size.y)
		var s := 120.0 / maxf(big, 60.0)
		n.scale = Vector2(s, s)
		n.position = Vector2(TEXT_X + TEXT_W / 2.0, 262)
		n.modulate = Color(1, 1, 1) if it["unlocked"] else Color(0, 0, 0, 0.75)
		portrait = n
	elif page == 1 and String(it.get("prop", "")) != "":
		var p := Node2D.new()
		p.set_script(load("res://scripts/prop.gd"))
		p.kind = it["prop"]
		p.set_meta("portrait", true)
		stage.add_child(p)
		p.remove_from_group("sleepy")
		# chaque habitant est dessiné avec son décor : on le cadre sur le personnage
		var off := {"elder": Vector2(10, 0), "merchant": Vector2(-60, 0), "tailor": Vector2(40, 0), "scriptorium": Vector2(-20, 0),
			"smith": Vector2(0, 0), "cartographer": Vector2(0, 0), "jeweler": Vector2(0, 0)}
		var sc2 := 1.15
		p.scale = Vector2(sc2, sc2)
		p.position = Vector2(TEXT_X + TEXT_W / 2.0, 300) + off.get(it["prop"], Vector2.ZERO) * sc2
		p.modulate = Color(1, 1, 1) if it["unlocked"] else Color(0, 0, 0, 0.75)
		portrait = p

# ---------------------------------------------------------------- dessin
func _box(bg: Color, border: Color, bw := 1, bottom := 3) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.border_width_bottom = bottom
	sb.set_corner_radius_all(4)
	return sb

func _wrap(text: String, width: float, fsize: int) -> Array:
	var f := ThemeDB.fallback_font
	var out := []
	for para in text.split("\n"):
		var line := ""
		for word in para.split(" "):
			var test := word if line == "" else line + " " + word
			if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width and line != "":
				out.append(line)
				line = word
			else:
				line = test
		out.append(line)
	return out

func _wrap_draw(c: Control, text: String, pos: Vector2, width: float, fsize: int, col: Color, center := false) -> float:
	var f := ThemeDB.fallback_font
	var lines := _wrap(text, width, fsize)
	var lh := fsize * 1.45
	for i in lines.size():
		c.draw_string(f, pos + Vector2(0, i * lh), lines[i], HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT, width if center else -1, fsize, col)
	return pos.y + lines.size() * lh

# taille de police la plus grande qui fait tenir le texte dans la hauteur donnée
func _fit(text: String, width: float, height: float, big := 16, small := 12) -> int:
	var fs := big
	while fs > small and _wrap(text, width, fs).size() * fs * 1.45 > height:
		fs -= 1
	return fs

func _draw_panel() -> void:
	var c := canvas
	var k := _k()
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.02, 0.015, 0.015, 0.78))
	c.draw_set_transform(_off(), 0.0, Vector2(k, k))
	var f := ThemeDB.fallback_font
	var panel := _box(Color(0.075, 0.058, 0.052, 0.97), BRASS, 3, 3)
	panel.set_corner_radius_all(5)
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 14
	panel.shadow_offset = Vector2(0, 5)
	c.draw_style_box(panel, PANEL)
	var ink := Color(0.88, 0.84, 0.76)
	var gold := Color(0.98, 0.82, 0.48)
	var soft := Color(0.62, 0.58, 0.52)
	var cx := PANEL.position.x
	var cw := PANEL.size.x
	c.draw_string(f, Vector2(cx, 62), tr("Les Mémoires de l'Ancien"), HORIZONTAL_ALIGNMENT_CENTER, cw, 28, Color(0.95, 0.9, 0.8))
	var unread := Lore.unread_count()
	var sub := tr("mémoires : %d / %d") % [Lore.unlocked_count(), Lore.entries().size()]
	if unread > 0:
		sub += "  ·  " + tr("%d à écouter") % unread
	c.draw_string(f, Vector2(cx, 84), sub, HORIZONTAL_ALIGNMENT_CENTER, cw, 13, soft)
	# onglets, LB / RB de part et d'autre
	_tab_rects.clear()
	var tw := 150.0
	var gap := 8.0
	var row_w := TABS.size() * tw + (TABS.size() - 1) * gap
	var x0 := cx + (cw - row_w) / 2.0
	var ty := 100.0
	var pad = get_node_or_null("/root/Controls")
	var use_pad: bool = pad != null and pad.using_pad
	for side in [-1, 1]:
		var g: Dictionary = {"pad": {"type": "button", "index": JOY_BUTTON_LEFT_SHOULDER if side < 0 else JOY_BUTTON_RIGHT_SHOULDER}} if use_pad else {"key": KEY_Q if side < 0 else KEY_E}
		var gh := 20.0
		var gwid := G.width(g, gh, f)
		var gx := x0 - 14.0 - gwid if side < 0 else x0 + row_w + 14.0
		G.draw(c, gx, ty + 17.0, gh, g, f)
	for i in TABS.size():
		var r := Rect2(x0 + i * (tw + gap), ty, tw, 34)
		_tab_rects.append(r)
		var on := i == page
		var sb := _box(Color(0.28, 0.2, 0.12), Color(1.0, 0.86, 0.55), 2, 3) if on else _box(Color(0.15, 0.11, 0.085), Color(0.36, 0.27, 0.18))
		c.draw_style_box(sb, r)
		c.draw_string(f, r.position + Vector2(0, 23), tr(TABS[i]), HORIZONTAL_ALIGNMENT_CENTER, tw, 15, Color(1.0, 0.88, 0.55) if on else Color(0.78, 0.74, 0.68))
		# point doré : il reste des mémoires à écouter dans cet onglet
		if i < 3:
			for it in _items(i):
				if it["new"]:
					c.draw_circle(r.position + Vector2(tw - 12, 10), 4.0, Color(1.0, 0.8, 0.35))
					break
	c.draw_rect(Rect2(cx + 24, 146, cw - 48, 1), Color(BRASS, 0.3))
	# liste
	var items := _items(page)
	_row_rects.clear()
	if items.is_empty():
		_wrap_draw(c, tr("Personne ne t'a encore rien dit. Va parler aux habitants du Sanctuaire."), Vector2(LIST.position.x, LIST.position.y + 20), LIST.size.x, 14, soft)
	for i in items.size():
		var it: Dictionary = items[i]
		var r := Rect2(LIST.position.x, LIST.position.y + i * ROW_H, LIST.size.x, ROW_H - 4)
		_row_rects.append(r)
		var on := i == sel
		c.draw_style_box(_box(Color(0.24, 0.17, 0.1) if on else Color(0.12, 0.09, 0.07), Color(1.0, 0.86, 0.55) if on else Color(0.3, 0.23, 0.16), 2 if on else 1, 2), r)
		var label: String = it["title"] if it["unlocked"] else "???"
		var col := (Color(1.0, 0.9, 0.62) if on else ink) if it["unlocked"] else Color(0.45, 0.42, 0.4)
		c.draw_string(f, r.position + Vector2(14, 20), label, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 40, 15, col)
		if it["new"]:
			var pulse := 0.75 + 0.25 * sin(t * 4.0)
			c.draw_circle(r.position + Vector2(r.size.x - 16, r.size.y / 2.0), 4.5, Color(1.0, 0.8, 0.35, pulse))
		elif not it["unlocked"]:
			_lock(c, r.position + Vector2(r.size.x - 17, r.size.y / 2.0))
	c.draw_rect(Rect2(LIST.end.x + 14, LIST.position.y, 1, 430), Color(BRASS, 0.25))
	# récit
	if sel < items.size():
		_draw_entry(c, f, items[sel], ink, gold, soft)
	# accueil de l'Ancien, en bas
	var greet := greeting() if toast_t <= 0.0 else toast
	var gcol := Color(0.72, 0.68, 0.82) if toast_t <= 0.0 else Color(1.0, 0.85, 0.5, clampf(toast_t, 0.0, 1.0))
	_wrap_draw(c, greet, Vector2(cx + 40, 620), cw - 80, 14, gcol, true)
	_close_rect = Rect2(560, 656, 160, 34)
	c.draw_style_box(_box(Color(0.15, 0.11, 0.085), Color(0.36, 0.27, 0.18)), _close_rect)
	c.draw_string(f, _close_rect.position + Vector2(0, 23), tr("Fermer"), HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(0.95, 0.9, 0.8))

func _lock(c: Control, p: Vector2) -> void:
	var col := Color(0.5, 0.45, 0.4)
	c.draw_arc(p + Vector2(0, -3), 4.0, PI, TAU, 10, col, 1.6)
	c.draw_rect(Rect2(p + Vector2(-5.5, -3), Vector2(11, 8)), col)

func _draw_entry(c: Control, f: Font, it: Dictionary, ink: Color, gold: Color, soft: Color) -> void:
	var x := TEXT_X
	var w := TEXT_W
	var bottom := 600.0
	if page == 3:
		c.draw_string(f, Vector2(x, 186), it["title"], HORIZONTAL_ALIGNMENT_LEFT, w, 20, gold)
		c.draw_rect(Rect2(x, 194, w, 1.5), Color(BRASS, 0.45))
		# dernières répliques d'abord, autant qu'il en tient
		var lines: Array = it["lines"]
		var y := 222.0
		for i in range(lines.size() - 1, -1, -1):
			var ls := _wrap(String(lines[i]), w, 14)
			if y + ls.size() * 14 * 1.45 > bottom:
				c.draw_string(f, Vector2(x, y + 4), tr("… et %d de plus, plus anciennes.") % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, w, 12, soft)
				break
			y = _wrap_draw(c, String(lines[i]), Vector2(x, y), w, 14, ink) + 8
		return
	var has_portrait := page == 2 or (page == 1 and String(it.get("prop", "")) != "")
	var y0 := 186.0
	if has_portrait:
		c.draw_circle(Vector2(x + w / 2.0, 262), 82, Color(1.0, 0.85, 0.5, 0.05))
		y0 = 352.0
	var ny := _wrap_draw(c, it["title"] if it["unlocked"] else "???", Vector2(x, y0), w, 21, gold, true)
	c.draw_rect(Rect2(x + w / 2.0 - 60, ny - 10, 120, 1.5), Color(BRASS, 0.45))
	if not it["unlocked"]:
		_wrap_draw(c, it["hint"], Vector2(x, ny + 14), w, 15, soft, true)
		return
	var body: String = it["text"]
	if String(it.get("text_b", "")) != "":
		body += "\n" + String(it["text_b"])
	var fs := _fit(body + ("\n" + String(it.get("hint_b", "")) if String(it.get("hint_b", "")) != "" else ""), w, bottom - ny - 8)
	var y2 := _wrap_draw(c, body, Vector2(x, ny + 8), w, fs, ink)
	if String(it.get("hint_b", "")) != "":
		_wrap_draw(c, it["hint_b"], Vector2(x, y2 + 4), w, maxi(fs - 2, 12), soft)

# ---------------------------------------------------------------- commandes
func _set_page(p: int) -> void:
	if p == page:
		return
	page = p
	sel = 0
	Audio.sfx("door", 0.2, -12.0)
	_on_select()

func _set_sel(i: int) -> void:
	var n := _items(page).size()
	if n == 0:
		return
	i = clampi(i, 0, n - 1)
	if i == sel:
		return
	sel = i
	Audio.sfx("door", 0.35, -18.0)
	_on_select()

func _input(event: InputEvent) -> void:
	if visible and not (event is InputEventMouse):
		var st := MenuTabs.step(event)
		if st != 0 and _open_t <= 0.0:
			_set_page(posmod(page + st, TABS.size()))
		get_viewport().set_input_as_handled()

func _pressed(acts: Array) -> bool:
	for a in acts:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false

func _held(acts: Array) -> bool:
	for a in acts:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false

func _b_edge() -> bool:
	var now := Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	var edge := now and not _b_was
	_b_was = now
	return edge

func _nav_input(delta: float) -> void:
	if _pressed(["pause_menu", "ui_cancel", "inventory"]) or _b_edge():
		close()
		return
	var d := Vector2i.ZERO
	if _held(["up", "ui_up"]):
		d.y = -1
	elif _held(["down", "ui_down"]):
		d.y = 1
	elif _held(["move_left", "ui_left"]):
		d.x = -1
	elif _held(["move_right", "ui_right"]):
		d.x = 1
	if d == Vector2i.ZERO:
		_hold_dir = d
		return
	if d != _hold_dir:
		_hold_dir = d
		_hold_t = 0.35
		_step(d)
		return
	_hold_t -= delta
	if _hold_t <= 0.0:
		_hold_t = 0.12
		_step(d)

# haut / bas : la liste ; gauche / droite : les onglets
func _step(d: Vector2i) -> void:
	if d.y != 0:
		_set_sel(sel + d.y)
	elif d.x != 0:
		_set_page(posmod(page + d.x, TABS.size()))

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var p: Vector2 = (event.position - _off()) / _k()
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_set_sel(sel + (1 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1))
		return
	if not click:
		return
	for i in _tab_rects.size():
		if _tab_rects[i].has_point(p):
			_set_page(i)
			return
	for i in _row_rects.size():
		if _row_rects[i].has_point(p):
			_set_sel(i)
			return
	if _close_rect.has_point(p):
		close()

extends CanvasLayer
# Inventaire : emblèmes (équipement), encoches et objets clés.
# S'ouvre avec Tab / bouton View et met le jeu en pause.
# Les emblèmes ne peuvent être (dés)équipés qu'assis sur un banc, comme dans l'inspiration.

const DU = preload("res://scripts/draw_util.gd")
const MenuTabs = preload("res://scripts/menu_tabs.gd")
const Weapons = preload("res://scripts/weapons.gd")
const C = preload("res://scripts/charms.gd")
const PlayerScript = preload("res://scripts/player.gd")

var main
var root: Control
var slots := []          # CharmSlot
var notch_bar: Control
var title_info: Label
var desc_name: Label
var desc_text: Label
var desc_cost: Label
var status: Label
var items_label: Label
var stats_label: Label
var focused_id := -1
var panel: PanelContainer
var page := 0              # 0 : emblèmes (grille), 1 : équipement (emblèmes portés + jauges)
var page_tabs := []
var page_boxes := []
var eq_list: VBoxContainer
var eq_head: Label
var gauge_box: VBoxContainer
var weapon_title: Label

# couleurs des jauges : base, niveaux de l'arme / trouvailles, emblèmes, malus
const COL_BASE := Color(0.82, 0.62, 0.32)
const COL_FORGE := Color(0.45, 0.85, 0.45)
const COL_CHARM := Color(0.58, 0.62, 1.0)
const COL_MALUS := Color(0.92, 0.32, 0.3)

# ---------------------------------------------------------------- jauge : base + bonus colorés
class Gauge extends Control:
	var label := ""
	var base := 0.0
	var forge := 0.0
	var charm := 0.0          # peut être négatif (malus d'un emblème)
	var vmax := 1.0
	var fmt := "%d"
	var unit := ""
	func _draw() -> void:
		var font := get_theme_default_font()
		var fs := 15
		var lw := 170.0
		var bw := 200.0
		var y := size.y / 2.0
		draw_string(font, Vector2(0, y + fs * 0.36), tr(label), HORIZONTAL_ALIGNMENT_LEFT, lw - 8.0, fs, Color(0.82, 0.85, 0.92))
		var r := Rect2(lw, y - 7.0, bw, 14.0)
		draw_rect(r, Color(0.08, 0.07, 0.06))
		var k := bw / maxf(vmax, 0.001)
		var x0 := r.position.x
		var b := clampf(base, 0.0, vmax)
		var bf := clampf(base + forge, 0.0, vmax)
		var fin := clampf(base + forge + charm, 0.0, vmax)
		draw_rect(Rect2(x0, r.position.y, b * k, r.size.y), COL_BASE)
		if bf > b:
			draw_rect(Rect2(x0 + b * k, r.position.y, (bf - b) * k, r.size.y), COL_FORGE)
		if charm > 0.0 and fin > bf:
			draw_rect(Rect2(x0 + bf * k, r.position.y, (fin - bf) * k, r.size.y), COL_CHARM)
		elif charm < 0.0 and bf > fin:
			# malus : la partie perdue reste visible, hachurée en rouge
			var lost := Rect2(x0 + fin * k, r.position.y, (bf - fin) * k, r.size.y)
			draw_rect(lost, Color(COL_MALUS, 0.35))
			var xx := lost.position.x
			while xx < lost.end.x:
				draw_line(Vector2(xx, lost.end.y), Vector2(minf(xx + 5.0, lost.end.x), lost.position.y), COL_MALUS, 1.5)
				xx += 5.0
		draw_rect(r, Color(0.85, 0.75, 0.5, 0.6), false, 1.0)
		# valeur : base, puis les bonus dans leur couleur
		var x := r.end.x + 10.0
		var parts := [[_f(base), Color(0.95, 0.93, 0.88)]]
		if absf(forge) > 0.0001:
			parts.append([" +" + _f(forge), COL_FORGE])
		if absf(charm) > 0.0001:
			parts.append([(" +" if charm > 0.0 else " −") + _f(absf(charm)), COL_CHARM if charm > 0.0 else COL_MALUS])
		if unit != "":
			parts.append([" " + unit, Color(0.6, 0.62, 0.7)])
		for pt in parts:
			draw_string(font, Vector2(x, y + fs * 0.36), pt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, pt[1])
			x += font.get_string_size(pt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	func _f(v: float) -> String:
		return fmt % v

# ---------------------------------------------------------------- icône d'un emblème porté
class CharmBadge extends Control:
	const CharmIcon = preload("res://scripts/charm_icon.gd")
	var charm_id := 0
	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
	func _draw() -> void:
		var col: Color = GameState.charm(charm_id)["color"]
		CharmIcon.draw(self, size / 2.0, size.y * 0.4, charm_id, col, true, Time.get_ticks_msec() / 1000.0)

# ---------------------------------------------------------------- case d'emblème dessinée
class CharmSlot extends Button:
	const DU = preload("res://scripts/draw_util.gd")
	const CharmIcon = preload("res://scripts/charm_icon.gd")
	func _process(_d: float) -> void:
		if is_visible_in_tree():
			queue_redraw()
	var charm_id := 0
	func _draw() -> void:
		var owned: bool = GameState.owns(charm_id)
		# 42 emblèmes : petites cases, icône et encoches à l'échelle de la case
		var r := size.y * 0.29
		var c := Vector2(size.x / 2.0, size.y / 2.0 - r * 0.3)
		if owned:
			var col: Color = GameState.charm(charm_id)["color"]
			var eq: bool = GameState.has_charm(charm_id)
			CharmIcon.draw(self, c, r, charm_id, col, eq, Time.get_ticks_msec() / 1000.0)
			if eq:
				draw_arc(c, r + 3.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.6), 2.0)
			# coût en petites encoches
			var cost: int = GameState.charm(charm_id)["cost"]
			for i in cost:
				var np := Vector2(size.x / 2.0 - (cost - 1) * 4.5 + i * 9.0, size.y - 7.0)
				draw_circle(np, 3.4, Color(0.25, 0.2, 0.1))
				draw_circle(np, 2.6, Color(1.0, 0.88, 0.55))
		else:
			CharmIcon.draw_locked(self, c, r)

# ---------------------------------------------------------------- barre d'encoches
class NotchBar extends Control:
	func _draw() -> void:
		var total: int = GameState.prog["notches"]
		var used: int = GameState.notches_used()
		for i in total:
			var p := Vector2(14 + i * 30, size.y / 2.0)
			if i < used:
				draw_circle(p, 10.0, Color(1.0, 0.88, 0.55))
			draw_arc(p, 11.0, 0.0, TAU, 24, Color(0.85, 0.8, 0.65), 2.0)

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	panel = PanelContainer.new()
	panel.theme = main.menu._make_theme() if main and main.menu else null
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title := Label.new()
	title.text = "Inventaire"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	v.add_child(title)
	title_info = Label.new()
	title_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_info)
	# onglets : Emblèmes / Équipement (LB / RB, Q / E, ou clic)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	tabs.add_child(MenuTabs.make(false))
	for i in 2:
		var tb := Button.new()
		tb.text = ["Emblèmes", "Équipement"][i]
		tb.custom_minimum_size = Vector2(190, 36)
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(_set_page.bind(i))
		tabs.add_child(tb)
		page_tabs.append(tb)
	tabs.add_child(MenuTabs.make(true))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
	page_boxes.append(h)
	# --- colonne gauche : encoches + grille d'emblèmes
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	h.add_child(left)
	var nl := Label.new()
	nl.text = "Encoches"
	nl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	left.add_child(nl)
	notch_bar = NotchBar.new()
	notch_bar.custom_minimum_size = Vector2(300, 28)
	left.add_child(notch_bar)
	var el := Label.new()
	el.text = "Emblèmes"
	el.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	left.add_child(el)
	var grid := GridContainer.new()
	grid.columns = 7    # 42 emblèmes : 6 rangées de 7 dans une liste déroulante (3 rangées visibles)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var gscroll := ScrollContainer.new()
	gscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gscroll.follow_focus = true
	gscroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	gscroll.custom_minimum_size = Vector2(7 * 88 + 16, 3 * 84 - 4)
	gscroll.add_child(grid)
	left.add_child(gscroll)
	var hint := Label.new()
	hint.text = "▼ Fais défiler pour voir tous les emblèmes"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	left.add_child(hint)
	for id in GameState.charm_count():
		var b := CharmSlot.new()
		b.charm_id = id
		b.custom_minimum_size = Vector2(80, 76)
		b.focus_entered.connect(_show_desc.bind(id))
		b.mouse_entered.connect(_show_desc.bind(id))
		b.pressed.connect(_toggle.bind(id))
		grid.add_child(b)
		slots.append(b)
	# --- colonne droite : description + objets + stats
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 8)
	h.add_child(right)
	desc_name = Label.new()
	desc_name.add_theme_font_size_override("font_size", 24)
	desc_name.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	right.add_child(desc_name)
	desc_cost = Label.new()
	desc_cost.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65))
	right.add_child(desc_cost)
	desc_text = Label.new()
	desc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_text.custom_minimum_size = Vector2(380, 70)
	right.add_child(desc_text)
	var il := Label.new()
	il.text = "Objets"
	il.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	right.add_child(il)
	items_label = Label.new()
	items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(items_label)
	stats_label = Label.new()
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	right.add_child(stats_label)

	_build_equipment_page(v)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(0, 28)
	status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	v.add_child(status)
	var close_b := Button.new()
	close_b.text = "Fermer"
	close_b.custom_minimum_size = Vector2(200, 40)
	close_b.pressed.connect(close)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(close_b)
	v.add_child(row)
	visible = false
	panel.resized.connect(_apply_scale)
	Settings.changed.connect(_apply_scale)

# ---------------------------------------------------------------- page « Équipement »
func _build_equipment_page(v: VBoxContainer) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	h.visible = false
	v.add_child(h)
	page_boxes.append(h)
	# gauche : emblèmes portés
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	h.add_child(left)
	eq_head = Label.new()
	eq_head.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	left.add_child(eq_head)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(500, 340)
	left.add_child(sc)
	eq_list = VBoxContainer.new()
	eq_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_list.add_theme_constant_override("separation", 6)
	sc.add_child(eq_list)
	# droite : arme et jauges
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	h.add_child(right)
	weapon_title = Label.new()
	weapon_title.add_theme_font_size_override("font_size", 22)
	weapon_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	right.add_child(weapon_title)
	gauge_box = VBoxContainer.new()
	gauge_box.add_theme_constant_override("separation", 2)
	right.add_child(gauge_box)
	# légende
	var leg := HBoxContainer.new()
	leg.add_theme_constant_override("separation", 14)
	for it in [["base", COL_BASE], ["niveaux / trouvailles", COL_FORGE], ["emblèmes", COL_CHARM], ["malus", COL_MALUS]]:
		var l := Label.new()
		l.text = "■ " + tr(it[0])
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", it[1])
		leg.add_child(l)
	right.add_child(leg)

func _section(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	gauge_box.add_child(l)

func _gauge(label: String, base: float, forge: float, charm: float, vmax: float, fmt := "%d", unit := "") -> void:
	var g := Gauge.new()
	g.label = label
	g.base = base
	g.forge = forge
	g.charm = charm
	g.vmax = vmax
	g.fmt = fmt
	g.unit = unit
	g.custom_minimum_size = Vector2(520, 25)
	gauge_box.add_child(g)

func _refresh_equipment() -> void:
	var p = main.player
	for c in eq_list.get_children():
		c.queue_free()
	for c in gauge_box.get_children():
		c.queue_free()
	var ids: Array = GameState.prog.get("equipped", [])
	eq_head.text = tr("Emblèmes portés : %d — encoches %d / %d") % [ids.size(), GameState.notches_used(), int(GameState.prog["notches"])]
	if ids.is_empty():
		var none := Label.new()
		none.text = "Aucun emblème porté."
		none.add_theme_color_override("font_color", Color(0.6, 0.62, 0.7))
		eq_list.add_child(none)
	for cid in ids:
		var c: Dictionary = GameState.charm(int(cid))
		var lvl: int = GameState.charm_level(int(cid))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var badge := CharmBadge.new()
		badge.charm_id = int(cid)
		badge.custom_minimum_size = Vector2(52, 52)
		row.add_child(badge)
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 0)
		var n := Label.new()
		n.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		n.text = tr(c["name"]) + ((tr("  niv. %d") % lvl) if lvl >= 2 else "") + "   " + "●".repeat(int(c["cost"]))
		n.add_theme_font_size_override("font_size", 17)
		n.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
		tv.add_child(n)
		var d := Label.new()
		d.text = c["desc"]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(430, 0)
		d.add_theme_font_size_override("font_size", 14)
		d.add_theme_color_override("font_color", Color(0.75, 0.78, 0.86))
		tv.add_child(d)
		row.add_child(tv)
		eq_list.add_child(row)
	# --- arme : base de l'arme, niveaux de la forgeronne, emblèmes
	var wid: String = p.wid()
	var lv: int = GameState.weapon_level(wid)
	var w0: Dictionary = Weapons.get_w(wid)
	var b: Dictionary = Weapons.bonus(wid, lv)
	weapon_title.text = tr(w0["name"]) + tr("  niv. %d") % lv
	_section("Arme")
	_gauge("Dégâts", 1.0 + float(w0["dmg"]), float(b["dmg"]), 1.0 if p.eq(C.BRUTE) else 0.0, 6.0)
	if not bool(w0["ranged"]):
		var r0 := 70.0 * float(w0["w"])
		var rf := r0 * float(b["reach"])
		_gauge("Portée", r0, rf, (r0 + rf) * (p.reach() - 1.0), 360.0, "%d", "px")
	var ac: float = PlayerScript.ATTACK_COOLDOWN
	var s0 := 1.0 / (ac * float(w0["cd"]))
	var sf := s0 * (1.0 + float(b["speed"]))
	var sc := sf / float(p.clv(C.BRUTE, [1.2, 1.12, 1.05], 1.0))
	_gauge("Coups par seconde", s0, sf - s0, sc - sf, 5.0, "%.1f")
	_gauge("Critique", 0.0, float(b["crit"]) * 100.0, float(p.clv(C.HAWK_EYE, [0.08, 0.12, 0.16], 0.0)) * 100.0, 40.0, "%d", "%")
	_gauge("Recul", float(w0["knock"]) * 100.0, 0.0, 0.0, 180.0, "%d", "%")
	# --- héros
	_section("Héros")
	var bonus_hp := float(GameState.max_hp_bonus())
	_gauge("Vie max", 5.0, bonus_hp, float(p.max_hp) - 5.0 - bonus_hp, 16.0)
	var soul0: float = PlayerScript.SOUL_PER_HIT * float(GameState.d("soul")) * float(w0.get("soul", 1.0))
	_gauge("Âme par coup", soul0, 0.0, float(p.soul_per_hit()) - soul0, 30.0, "%.0f")
	var ult0: float = PlayerScript.ULT_PER_HIT * float(GameState.d("ult"))
	_gauge("Ultime par coup", ult0, 0.0, float(p.ult_per_hit()) - ult0, 20.0, "%.0f", "%")
	_gauge("Vitesse de course", 100.0, 0.0, (float(p.clv(C.SWIFT_CLOAK, [1.12, 1.18, 1.24], 1.0)) - 1.0) * 100.0, 130.0, "%d", "%")
	_gauge("Ruées en l'air", 1.0 if p.can_dash else 0.0, 0.0, 1.0 if (p.can_dash and p.eq(C.TWIN_SHADOW)) else 0.0, 2.0)
	_gauge("Sauts en l'air", 0.0, 0.0, 1.0 if p.eq(C.MOTH_WING) else 0.0, 2.0)

func _set_page(i: int) -> void:
	page = i
	for k in page_boxes.size():
		page_boxes[k].visible = k == page
	for k in page_tabs.size():
		page_tabs[k].add_theme_color_override("font_color", Color(1.0, 0.88, 0.55) if k == page else Color(0.75, 0.75, 0.8))
	if page == 1:
		_refresh_equipment()
	elif visible:
		slots[maxi(focused_id, 0)].grab_focus()
	call_deferred("_apply_scale")

func _apply_scale() -> void:
	var s: float = Settings.menu_scale
	# ne jamais dépasser de l'écran, quelle que soit la taille des menus choisie
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if panel.size.y > 0.0 and panel.size.x > 0.0:
		s = minf(s, minf(vp.y * 0.96 / panel.size.y, vp.x * 0.96 / panel.size.x))
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(s, s)

# ---------------------------------------------------------------- ouverture
func open() -> void:
	visible = true
	Engine.time_scale = Settings.speed()
	get_tree().paused = true
	status.text = ""
	_refresh()
	focused_id = -1
	_set_page(page)
	slots[0].grab_focus()

func close() -> void:
	visible = false
	get_tree().paused = false

func _can_edit() -> bool:
	return main and main.player and main.player.sitting

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			close()
			get_viewport().set_input_as_handled()
		elif not get_tree().paused and main and main.player and not main.player.dead:
			open()
			get_viewport().set_input_as_handled()
	elif visible and (event.is_action_pressed("pause_menu") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		close()
		get_viewport().set_input_as_handled()
	elif visible and MenuTabs.step(event) != 0:
		_set_page(posmod(page + MenuTabs.step(event), 2))
		Audio.sfx("pickup", 0.15, -14.0)
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- actions
func _toggle(id: int) -> void:
	if not GameState.owns(id):
		status.text = "Emblème pas encore trouvé."
		return
	if not _can_edit():
		status.text = "Repose-toi sur un banc pour changer d'équipement."
		return
	var err: String = GameState.toggle_equip(id)
	if err != "":
		status.text = err
	else:
		var n: String = tr(GameState.charm(id)["name"])
		status.text = tr("%s équipé." if GameState.has_charm(id) else "%s retiré.") % n
		Controls.rumble(0.2, 0.0, 0.06)
	_refresh()
	_show_desc(id)

func _show_desc(id: int) -> void:
	focused_id = id
	if GameState.owns(id):
		var c: Dictionary = GameState.charm(id)
		var lvl: int = GameState.charm_level(id)
		desc_name.text = tr(c["name"]) + ((tr("  niv. %d") % lvl) if lvl >= 2 else "") + (tr("  (équipé)") if GameState.has_charm(id) else "")
		desc_cost.text = tr("Coût : %d encoches" if c["cost"] > 1 else "Coût : %d encoche") % c["cost"]
		desc_text.text = tr(c["desc"]) + ("\n" + tr(c.get("up", "")) if c.has("up") else "")
	else:
		desc_name.text = "???"
		desc_cost.text = ""
		desc_text.text = "Un emblème encore caché quelque part dans les profondeurs."

func _refresh() -> void:
	var p = main.player
	title_info.text = "Assis sur un banc : clique ou valide un emblème pour l'équiper." if _can_edit() else "Consultation seule — repose-toi sur un banc pour changer d'équipement."
	var items := []
	items.append("• " + tr(p.weapon()["name"]))
	if p.can_dash:
		items.append("• " + tr("Cape d'Ombre-Vive (Ruée / Esquive)"))
	items.append("• " + tr("Éclats : %d") % p.geo)
	items.append("• " + tr("Emblèmes trouvés : %d / %d") % [GameState.prog["owned"].size(), GameState.charm_count()])
	items_label.text = "\n".join(items)
	stats_label.text = tr("Vie %d/%d   Âme %d   Ultime %d %%   Dégâts %d") % [p.hp, p.max_hp, p.soul, p.ult, p.nail_damage()]
	for s in slots:
		s.queue_redraw()
	notch_bar.queue_redraw()
	if focused_id >= 0:
		_show_desc(focused_id)

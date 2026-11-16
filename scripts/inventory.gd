extends CanvasLayer
# Inventaire : emblèmes (équipement), encoches et objets clés.
# S'ouvre avec Tab / bouton View et met le jeu en pause.
# Les emblèmes ne peuvent être (dés)équipés qu'assis sur un banc, comme dans l'inspiration.

const DU = preload("res://scripts/draw_util.gd")

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
		var c := Vector2(size.x / 2.0, size.y / 2.0 - 8.0)
		if owned:
			var col: Color = GameState.charm(charm_id)["color"]
			var eq: bool = GameState.has_charm(charm_id)
			CharmIcon.draw(self, c, 22.0, charm_id, col, eq, Time.get_ticks_msec() / 1000.0)
			if eq:
				draw_arc(c, 25.0, 0.0, TAU, 32, Color(1.0, 0.9, 0.6), 2.0)
			# coût en petites encoches
			var cost: int = GameState.charm(charm_id)["cost"]
			for i in cost:
				var np := Vector2(size.x / 2.0 - (cost - 1) * 6.0 + i * 12.0, size.y - 12.0)
				draw_circle(np, 4.2, Color(0.25, 0.2, 0.1))
				draw_circle(np, 3.2, Color(1.0, 0.88, 0.55))
				draw_circle(np + Vector2(-1, -1), 1.0, Color(1, 1, 0.9))
		else:
			CharmIcon.draw_locked(self, c, 22.0)

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

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	v.add_child(h)
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
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	left.add_child(grid)
	for id in GameState.charm_count():
		var b := CharmSlot.new()
		b.charm_id = id
		b.custom_minimum_size = Vector2(84, 80)
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

func _apply_scale() -> void:
	var s: float = Settings.menu_scale
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(s, s)

# ---------------------------------------------------------------- ouverture
func open() -> void:
	visible = true
	Engine.time_scale = Settings.speed()
	get_tree().paused = true
	status.text = ""
	_apply_scale()
	_refresh()
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
		desc_name.text = tr(c["name"]) + (tr("  (équipé)") if GameState.has_charm(id) else "")
		desc_cost.text = tr("Coût : %d encoches" if c["cost"] > 1 else "Coût : %d encoche") % c["cost"]
		desc_text.text = c["desc"]
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

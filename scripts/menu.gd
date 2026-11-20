extends CanvasLayer
# Menu pause (Échap / bouton Menu) + écran « Commandes » (réaffectation clavier, souris, manette)
# + écran « Options » (taille du HUD et des menus, caméra, secousses, plein écran…).

const GlyphButtonScript = preload("res://scripts/glyph_button.gd")
const Paths = preload("res://scripts/paths.gd")

var main
var dim: ColorRect
var pause_panel: PanelContainer
var controls_panel: PanelContainer
var options_panel: PanelContainer
var title_panel: PanelContainer
var diff_panel: PanelContainer
var home_panel: PanelContainer      # panneau de retour : pause ou écran titre
var first_title_button: Button
var diff_buttons: Array[Button] = []
var skip_tuto_check: CheckButton
var one_life_check: CheckButton
var diff_descs: Array = []
var title_row: HBoxContainer
var title_mode := false
var title_backdrop: Control
var diff_header: Label
var pad_header: Label
var diff_back_row: Control
var game_over := false
var option_widgets := {}   # clé de réglage -> HSlider / CheckButton
var first_option: Control
var grid: GridContainer
var status: Label
var pad_info: Label
var vib_check: CheckButton
var first_pause_button: Button
var cells := {}          # "action:slot" -> Button
var waiting_action := ""
var waiting_slot := -1
var wait_t := 0.0
var info: Label
var layout_btn: OptionButton
var ach_panel: PanelContainer
var slots_panel: PanelContainer
var discord_panel: PanelContainer
var discord_status: Label
var discord_link_btn: Button
var discord_code: LineEdit
var discord_join: Button
var discord          # discord_link.gd (créé avec le panneau)
var slots_box: VBoxContainer
var diff_warn: Label
var target_slot := 1
var ach_list: VBoxContainer
var ach_back: Button
var route: Label
var save_label: Label
var upd_button: Button
var upd_label: Label

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = _make_theme()
	add_child(root)
	dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	title_backdrop = TitleBackdrop.new()
	title_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_backdrop.visible = false
	root.add_child(title_backdrop)
	_build_pause(root)
	_build_controls(root)
	_build_options(root)
	_build_title(root)
	_build_difficulty(root)
	_build_achievements(root)
	_build_slots(root)
	_build_discord(root)
	home_panel = pause_panel
	for p in _panels():
		p.resized.connect(_apply_scale)
	Settings.changed.connect(_apply_scale)
	_show(false)
	Controls.bindings_changed.connect(_refresh)
	Controls.device_changed.connect(func(_p): _refresh())
	Input.joy_connection_changed.connect(_on_joy_changed)

func _panels() -> Array:
	return [pause_panel, controls_panel, options_panel, title_panel, diff_panel, ach_panel, slots_panel, discord_panel]

# Affiche un seul panneau
var title_wrap: Control
# conteneur à afficher / cacher pour un panneau (l'écran titre a son propre cadre plein écran)
func _holder(p: Control) -> Control:
	return title_wrap if p == title_panel and title_wrap else p.get_parent()

func _go(panel: PanelContainer) -> void:
	if title_backdrop:
		title_backdrop.visible = title_mode
	# sur l'écran titre, les autres panneaux (options, parties…) gardent un voile sombre
	if title_mode:
		dim.visible = panel != title_panel
		dim.color = Color(0.0, 0.0, 0.03, 0.6)
	for p in _panels():
		if p:
			_holder(p).visible = (p == panel)
	_apply_scale()

# ---------------------------------------------------------------- écran titre et difficulté
func _build_title(root: Control) -> void:
	# Écran titre plein écran : colonne à gauche (titre et menu en texte), la Lanterne suspendue à
	# droite, et le Sanctuaire qui se devine dans sa lumière (TitleBackdrop).
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wrap)
	title_wrap = wrap
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 70)
	mc.add_theme_constant_override("margin_top", 30)
	mc.add_theme_constant_override("margin_bottom", 80)
	wrap.add_child(mc)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(col)
	title_panel = PanelContainer.new()
	title_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	title_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(title_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	title_panel.add_child(v)
	title_items.clear()
	var t := Label.new()
	t.text = tr("Lanterne des Profondeurs")
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(470, 0)
	t.add_theme_font_size_override("font_size", 58)
	t.add_theme_constant_override("line_spacing", -14)
	t.add_theme_color_override("font_color", Color(0.96, 0.85, 0.6))
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	t.add_theme_constant_override("shadow_offset_x", 0)
	t.add_theme_constant_override("shadow_offset_y", 3)
	v.add_child(t)
	title_items.append(t)
	var sub := Label.new()
	sub.text = "Un metroidvania aux profondeurs changeantes"
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.62, 0.69, 0.84))
	v.add_child(sub)
	title_items.append(sub)
	var rule := TitleRule.new()
	rule.custom_minimum_size = Vector2(300, 22)
	v.add_child(rule)
	title_items.append(rule)
	var cs: int = GameState.continue_slot()
	if cs > 0:
		first_title_button = _item("Continuer", func(): GameState.continue_game(cs))
		v.add_child(first_title_button)
		var sv := Label.new()
		save_label = sv
		sv.text = tr("Emplacement %d") % cs + " · " + GameState.save_summary(cs).replace(" — ", " · ")
		sv.add_theme_font_size_override("font_size", 12)
		sv.add_theme_color_override("font_color", Color(0.55, 0.6, 0.74))
		var sm := MarginContainer.new()
		sm.add_theme_constant_override("margin_left", 30)
		sm.add_theme_constant_override("margin_bottom", 6)
		sm.add_child(sv)
		v.add_child(sm)
		title_items.append(sm)
		v.add_child(_item("Parties", _open_slots))
	else:
		first_title_button = _item("Jouer", _open_slots)
		v.add_child(first_title_button)
	v.add_child(_item("Commandes", _open_controls))
	v.add_child(_item("Options", _open_options))
	v.add_child(_item("Succès", _open_achievements))
	v.add_child(_item("Discord", _open_discord))
	if not OS.has_feature("web"):   # dans un navigateur, on ferme simplement l'onglet
		v.add_child(_item("Quitter le jeu", func(): get_tree().quit()))
	# version et mise à jour (voir updater.gd), en bas de l'écran
	var foot := VBoxContainer.new()
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.offset_left = 70
	foot.offset_right = 600
	foot.offset_top = -110
	foot.offset_bottom = -18
	foot.alignment = BoxContainer.ALIGNMENT_END
	wrap.add_child(foot)
	# l'option « écran titre animé », aussi réglable directement ici
	anim_item = _item("", func():
		Settings.set_value("menu_anim", not Settings.menu_anim)
		if option_widgets.has("menu_anim"):
			option_widgets["menu_anim"].set_pressed_no_signal(Settings.menu_anim)
		_refresh_anim_item())
	anim_item.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	anim_item.add_theme_font_size_override("font_size", 14)
	anim_item.add_theme_color_override("font_color", Color(0.55, 0.58, 0.68))
	foot.add_child(anim_item)
	_refresh_anim_item()
	Settings.changed.connect(_refresh_anim_item)
	upd_button = _item("", _on_update_pressed)
	upd_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	upd_button.add_theme_font_size_override("font_size", 15)
	upd_button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	upd_button.visible = false
	foot.add_child(upd_button)
	upd_label = Label.new()
	upd_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	upd_label.add_theme_font_size_override("font_size", 12)
	upd_label.add_theme_color_override("font_color", Color(0.42, 0.45, 0.55))
	foot.add_child(upd_label)
	title_items.append(foot)
	Updater.changed.connect(_refresh_update)
	_refresh_update()

var anim_item: Button
func _refresh_anim_item() -> void:
	if anim_item:
		anim_item.text = tr("Animations de l'écran titre : %s") % (tr("oui") if Settings.menu_anim else tr("non"))

# Entrée du menu titre : du texte seul, un losange doré devant l'entrée choisie qui glisse un peu
var title_items := []
var title_intro := 0.0

func _item(text: String, cb: Callable) -> Button:
	var b := TitleItem.new()
	b.text = text
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): if b.visible and not b.disabled: b.grab_focus())
	title_items.append(b)
	return b

class TitleItem extends Button:
	var slide := 0.0
	var sb := StyleBoxEmpty.new()
	func _ready() -> void:
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		flat = true
		focus_mode = Control.FOCUS_ALL
		sb.content_margin_left = 30
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, sb)
		if not has_theme_font_size_override("font_size"):
			add_theme_font_size_override("font_size", 25)
		if not has_theme_color_override("font_color"):
			add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
		add_theme_color_override("font_hover_color", Color(1.0, 0.89, 0.65))
		add_theme_color_override("font_focus_color", Color(1.0, 0.89, 0.65))
		add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.8))
		add_theme_color_override("font_outline_color", Color(1.0, 0.65, 0.25, 0.0))
	func _process(delta: float) -> void:
		var anim: bool = Settings.menu_anim
		var want := 12.0 if has_focus() else 0.0
		slide = lerpf(slide, want, minf(delta * 12.0, 1.0)) if anim else want
		sb.content_margin_left = 30.0 + slide
		if has_focus():
			queue_redraw()
	func _draw() -> void:
		if not has_focus():
			return
		var t := Time.get_ticks_msec() / 1000.0
		var pulse := (0.5 + 0.5 * sin(t * 3.0)) if Settings.menu_anim else 0.6
		var c := Vector2(10.0 + slide * 0.5, size.y / 2.0)
		var r := 6.0
		draw_circle(c, 13.0, Color(1.0, 0.7, 0.3, 0.10 + 0.08 * pulse))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), Color(0.92, 0.74, 0.38))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.45), c + Vector2(r * 0.45, 0), c + Vector2(0, r * 0.45), c + Vector2(-r * 0.45, 0)]), Color(1.0, 0.95, 0.75))

class TitleRule extends Control:
	func _draw() -> void:
		var y := size.y / 2.0
		var n := 40
		for i in n:
			var a := 1.0 - float(i) / n
			draw_line(Vector2(4 + i * 7.5, y), Vector2(4 + (i + 1) * 7.5, y), Color(0.79, 0.63, 0.29, 0.8 * a), 1.5)

# animation d'arrivée du menu titre : les éléments glissent et apparaissent l'un après l'autre
func _process_title_intro(delta: float) -> void:
	if not title_mode or not title_panel or not _holder(title_panel).visible:
		return
	title_intro += delta
	for i in title_items.size():
		var it = title_items[i]
		if not is_instance_valid(it):
			continue
		var k := clampf((title_intro - 0.15 - i * 0.06) / 0.45, 0.0, 1.0) if Settings.menu_anim else 1.0
		k = 1.0 - pow(1.0 - k, 3.0)
		it.modulate.a = k

func _refresh_update() -> void:
	if upd_label == null:
		return
	upd_button.visible = Updater.state in ["ready", "available"]
	upd_label.text = tr("Version %s") % Updater.version
	match Updater.state:
		"downloading":
			upd_label.text = tr("Mise à jour %s : téléchargement… %d %%") % [Updater.latest, int(Updater.progress * 100.0)]
		"ready":
			upd_button.text = tr("Mise à jour %s prête — redémarrer") % Updater.latest
		"available":
			upd_button.text = tr("Version %s disponible — télécharger") % Updater.latest
		"uptodate":
			upd_label.text = tr("Version %s — à jour") % Updater.version

func _on_update_pressed() -> void:
	if Updater.state == "ready":
		Updater.restart()
	else:
		Updater.open_page()

func _build_difficulty(root: Control) -> void:
	diff_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	diff_panel.add_child(v)
	diff_header = Label.new()
	diff_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_header.add_theme_font_size_override("font_size", 18)
	diff_header.add_theme_color_override("font_color", Color(0.85, 0.75, 0.75))
	diff_header.visible = false
	v.add_child(diff_header)
	v.add_child(_title("Choisis la difficulté"))
	if true:
		var warn := Label.new()
		diff_warn = warn
		warn.text = "Une nouvelle partie remplace ta sauvegarde actuelle."
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.add_theme_font_size_override("font_size", 14)
		warn.add_theme_color_override("font_color", Color(1.0, 0.65, 0.5))
		v.add_child(warn)
	for i in GameState.DIFFS.size():
		var dd: Dictionary = GameState.DIFFS[i]
		var b := _button(dd["name"], _start_game.bind(i))
		b.custom_minimum_size = Vector2(560, 44)
		b.add_theme_color_override("font_color", dd["color"])
		b.add_theme_font_size_override("font_size", 22)
		v.add_child(b)
		diff_buttons.append(b)
		var l := Label.new()
		l.text = dd["desc"]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(560, 0)
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color(0.65, 0.7, 0.82))
		v.add_child(l)
		diff_descs.append(l)
	skip_tuto_check = CheckButton.new()
	skip_tuto_check.text = "Passer le tutoriel"
	v.add_child(skip_tuto_check)
	one_life_check = CheckButton.new()
	one_life_check.text = "Une seule vie : la partie s'efface à la première mort"
	one_life_check.add_theme_color_override("font_color", Color(1.0, 0.6, 0.5))
	v.add_child(one_life_check)
	var br := _button("Retour", _back_to_pause)
	br.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(br)
	v.add_child(row)
	diff_back_row = row
	# après une mort en « une seule vie » : revenir à l'écran-titre au lieu de recommencer
	title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var bt := _button("Écran-titre", _to_title)
	bt.custom_minimum_size = Vector2(200, 40)
	title_row.add_child(bt)
	title_row.visible = false
	v.add_child(title_row)

func _open_difficulty(s := -1) -> void:
	target_slot = s if s > 0 else GameState.slot
	if diff_warn:
		diff_warn.visible = GameState.slot_exists(target_slot)
		diff_warn.text = tr("Une nouvelle partie remplace la sauvegarde de l'emplacement %d.") % target_slot
	one_life_check.button_pressed = false
	title_row.visible = false
	for l in diff_descs:
		l.visible = true
	_go(diff_panel)
	diff_buttons[GameState.difficulty].grab_focus()

func _to_title() -> void:
	game_over = false
	GameState.show_title = true
	GameState._reload(false)

func _start_game(diff: int) -> void:
	GameState.new_game(skip_tuto_check.button_pressed, diff, target_slot, one_life_check.button_pressed)

# ---------------------------------------------------------------- emplacements de sauvegarde
func _build_slots(root: Control) -> void:
	slots_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	slots_panel.add_child(v)
	v.add_child(_title("Parties"))
	var hint := Label.new()
	hint.text = "Chaque emplacement a sa propre partie et sa propre difficulté."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	v.add_child(hint)
	slots_box = VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 8)
	v.add_child(slots_box)
	var br := _button("Retour", _back_to_pause)
	br.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(br)
	v.add_child(row)

func _open_slots() -> void:
	for ch in slots_box.get_children():
		slots_box.remove_child(ch)
		ch.queue_free()
	var first: Button = null
	for s in range(1, GameState.SLOTS + 1):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var exists: bool = GameState.slot_exists(s)
		var main_b := Button.new()
		main_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		main_b.custom_minimum_size = Vector2(660, 48)
		main_b.add_theme_font_size_override("font_size", 15)
		main_b.clip_text = true
		var cur := "  ◆" if s == GameState.slot and not title_mode else ""
		if exists:
			main_b.text = tr("Emplacement %d") % s + cur + " — " + GameState.save_summary(s)
			main_b.pressed.connect(func(): GameState.continue_game(s))
		else:
			main_b.text = tr("Emplacement %d") % s + " — " + tr("vide : nouvelle partie")
			main_b.pressed.connect(_open_difficulty.bind(s))
		line.add_child(main_b)
		var nb := Button.new()
		nb.text = "Nouvelle"
		nb.custom_minimum_size = Vector2(110, 48)
		nb.disabled = not exists
		nb.pressed.connect(_open_difficulty.bind(s))
		line.add_child(nb)
		var db := Button.new()
		db.text = "Supprimer"
		db.custom_minimum_size = Vector2(120, 48)
		db.disabled = not exists or (s == GameState.slot and not title_mode)
		db.pressed.connect(func():
			if db.text != tr("Confirmer ?"):
				db.text = tr("Confirmer ?")
			else:
				GameState.delete_slot(s)
				_open_slots())
		line.add_child(db)
		slots_box.add_child(line)
		if first == null:
			first = main_b
	_go(slots_panel)
	first.grab_focus()

# Mort définitive : récapitulatif de la partie puis choix d'une nouvelle partie
func open_game_over(summary: String) -> void:
	game_over = true
	target_slot = GameState.slot
	home_panel = diff_panel
	visible = true
	dim.visible = true
	dim.color = Color(0.05, 0.0, 0.02, 0.86)
	diff_header.text = summary
	diff_header.visible = true
	diff_back_row.visible = false
	skip_tuto_check.button_pressed = true
	one_life_check.button_pressed = false
	title_row.visible = true
	# écran compact : le récapitulatif prend la place des descriptions
	for l in diff_descs:
		l.visible = false
	if diff_warn:
		diff_warn.visible = false
	_go(diff_panel)
	get_tree().paused = true
	diff_buttons[GameState.difficulty].grab_focus()

# Écran titre au lancement : le jeu reste en pause derrière
func open_title() -> void:
	title_mode = true
	home_panel = title_panel
	visible = true
	dim.visible = false
	title_intro = 0.0
	_frame_title_scene()
	_go(title_panel)
	get_tree().paused = true
	first_title_button.grab_focus()
	Audio.play_boss(GameState.CosmeticsScript.hub_music())

# Écran titre : la caméra (figée, le jeu est en pause) cadre le Sanctuaire sous la Lanterne
func _frame_title_scene() -> void:
	if main == null or main.camera == null:
		return
	if main.hud:
		main.hud.visible = false
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var z: float = main.camera.zoom.x
	var lamp: Vector2 = vp * Vector2(0.68, 0.0)
	# point du monde à placer sous la Lanterne, sol aux 4/5 de l'écran
	var target: Vector2 = Vector2(17.5 * 32.0, 17.0 * 32.0) if GameState.mode == "hub" else main.player.global_position + Vector2(0, 24)
	var screen := Vector2(lamp.x, vp.y * 0.8)
	main.camera.position_smoothing_enabled = false
	main.camera.offset = Vector2.ZERO
	main.camera.global_position = target - (screen - vp / 2.0) / z
	main.camera.force_update_scroll()

# ---------------------------------------------------------------- construction
func _make_theme() -> Theme:
	# panneaux de bois sombre cerclés de laiton, boutons en plaques de bois
	var th := Theme.new()
	var brass := Color(0.72, 0.58, 0.32)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.075, 0.058, 0.052, 0.97)
	panel.border_color = brass
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(5)
	panel.set_content_margin_all(22)
	panel.shadow_color = Color(0, 0, 0, 0.55)
	panel.shadow_size = 14
	panel.shadow_offset = Vector2(0, 5)
	th.set_stylebox("panel", "PanelContainer", panel)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.15, 0.11, 0.085)
	normal.border_color = Color(0.36, 0.27, 0.18)
	normal.set_border_width_all(1)
	normal.border_width_bottom = 3
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.16, 0.11)
	hover.border_color = Color(0.55, 0.42, 0.26)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.28, 0.2, 0.12)
	focus.border_color = Color(1.0, 0.86, 0.55)
	focus.set_border_width_all(2)
	focus.border_width_bottom = 3
	focus.shadow_color = Color(1.0, 0.75, 0.35, 0.25)
	focus.shadow_size = 6
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.36, 0.26, 0.15)
	pressed.border_width_bottom = 1
	pressed.border_width_top = 3
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.09, 0.075, 0.065)
	disabled.border_color = Color(0.2, 0.16, 0.12)
	for t in ["Button", "CheckButton", "OptionButton"]:
		th.set_stylebox("normal", t, normal)
		th.set_stylebox("hover", t, hover)
		th.set_stylebox("focus", t, focus)
		th.set_stylebox("pressed", t, pressed)
		th.set_stylebox("disabled", t, disabled)
		th.set_font_size("font_size", t, 18)
		th.set_color("font_color", t, Color(0.95, 0.9, 0.8))
		th.set_color("font_hover_color", t, Color(1.0, 0.95, 0.85))
		th.set_color("font_focus_color", t, Color(1.0, 0.93, 0.75))
		th.set_color("font_disabled_color", t, Color(0.5, 0.45, 0.4))
	th.set_font_size("font_size", "Label", 20)
	th.set_color("font_color", "Label", Color(0.88, 0.84, 0.76))
	th.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	th.set_constant("shadow_offset_x", "Label", 1)
	th.set_constant("shadow_offset_y", "Label", 1)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.08, 0.06)
	sb.set_corner_radius_all(3)
	var grab := StyleBoxFlat.new()
	grab.bg_color = brass.darkened(0.2)
	grab.set_corner_radius_all(3)
	th.set_stylebox("scroll", "VScrollBar", sb)
	th.set_stylebox("grabber", "VScrollBar", grab)
	th.set_stylebox("grabber_highlight", "VScrollBar", grab)
	th.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return th

# ---------------------------------------------------------------- fond peint de l'écran titre
class TitleBackdrop extends Control:
	# Le jeu (le Sanctuaire) reste visible derrière : on le recouvre de nuit, sauf dans le cône de
	# lumière de la Lanterne suspendue à droite. Colonne de gauche assombrie pour le menu.
	const DU = preload("res://scripts/draw_util.gd")
	const SHADER := """
shader_type canvas_item;
uniform vec2 rect_size = vec2(1280.0, 720.0);
uniform vec2 lamp = vec2(870.0, 300.0);
uniform float breath = 1.0;
uniform float reveal = 1.0;
void fragment() {
	vec2 p = UV * rect_size;
	float h = rect_size.y;
	// halo rond autour de la lanterne, puis grand ovale de lumière qui descend sur le Sanctuaire
	float halo = 1.0 - smoothstep(0.0, h * 0.42, length(p - lamp));
	vec2 d = (p - (lamp + vec2(0.0, h * 0.40))) / vec2(h * 0.62, h * 0.46);
	float cone = 1.0 - smoothstep(0.30, 1.0, length(d));
	float light = clamp(max(cone * 0.92, halo * 0.75) * breath, 0.0, 1.0);
	float a = 1.0 - light * reveal;
	// colonne de gauche : nuit profonde pour lire le menu
	float col = smoothstep(rect_size.x * 0.52, rect_size.x * 0.22, p.x);
	a = max(a, col * 0.96);
	vec3 night = vec3(0.018, 0.016, 0.03);
	vec3 warm = vec3(0.32, 0.18, 0.06);
	COLOR = vec4(mix(warm, night, a), max(a, light * 0.10));
}
"""
	var t := 0.0
	var breath := 1.0
	var veil: ColorRect
	var mat: ShaderMaterial
	func _ready() -> void:
		veil = ColorRect.new()
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = SHADER
		mat = ShaderMaterial.new()
		mat.shader = sh
		veil.material = mat
		veil.show_behind_parent = true
		add_child(veil)
	func _lamp() -> Vector2:
		return Vector2(size.x * 0.68, size.y * 0.36)
	func _process(d: float) -> void:
		if not visible:
			return
		t += d
		var anim: bool = Settings.menu_anim
		mat.set_shader_parameter("rect_size", size)
		mat.set_shader_parameter("lamp", _lamp())
		breath = (0.97 + 0.03 * sin(t * 0.9) + 0.01 * sin(t * 1.7)) if anim else 1.0
		mat.set_shader_parameter("breath", breath)
		mat.set_shader_parameter("reveal", 1.0 if int(Settings.title_scene) == 0 else 0.0)
		queue_redraw()
	func _draw() -> void:
		var anim: bool = Settings.menu_anim
		var c := _lamp()
		var tt := t if anim else 0.0
		# balancement léger de la lanterne au bout de sa chaîne
		var sway := sin(tt * 0.9) * 0.035
		var pivot := Vector2(c.x, 0)
		var flick := (0.95 + 0.05 * sin(tt * 2.2) * sin(tt * 1.3)) if anim else 1.0
		var GLOW := Color(1.0, 0.72, 0.36)
		var BRASS := Color(0.72, 0.58, 0.32)
		if camp:
			camp.visible = int(Settings.title_scene) == 4
		match int(Settings.title_scene):
			1: _village_troglo(tt)
			2: _village_hameau(tt)
			3: _iso_sanctuary(tt)
			4: _campfire(tt)
		# rayons qui descendent
		for i in 9:
			var ang := PI / 2.0 + (i - 4) * 0.2 + sin(tt * 0.5 + i) * 0.03
			var d := Vector2.from_angle(ang)
			draw_colored_polygon(PackedVector2Array([c, c + d.rotated(-0.05) * size.y, c + d.rotated(0.05) * size.y]), Color(GLOW, 0.03))
		draw_set_transform(pivot, sway, Vector2.ONE)
		var lc := c - pivot
		DU.glow(self, lc, 120.0, GLOW, 0.35 * flick)
		draw_line(Vector2(0, 0), lc + Vector2(0, -70), Color(0.3, 0.26, 0.22), 3.0)
		for i in 8:
			draw_arc(Vector2(0, lc.y - 74.0 - i * 16.0), 5.0, 0.0, TAU, 10, Color(0.42, 0.36, 0.28), 2.0)
		var body := Rect2(lc + Vector2(-30, -44), Vector2(60, 84))
		DU.flat(self, PackedVector2Array([lc + Vector2(-38, -44), lc + Vector2(0, -72), lc + Vector2(38, -44)]), Color(0.22, 0.17, 0.11))
		draw_arc(lc + Vector2(0, -76), 9.0, PI, TAU, 10, BRASS.darkened(0.3), 3.0)
		draw_rect(body, Color(0.06, 0.05, 0.05))
		draw_rect(body.grow(-7), Color(1.0, 0.86, 0.55).lerp(Color(1.0, 0.95, 0.75), 0.3 * (flick - 0.95) / 0.05))
		var fc := lc + Vector2(0, 14)
		var fh := 30.0 * flick
		draw_colored_polygon(PackedVector2Array([fc + Vector2(-9, 0), fc + Vector2(-3, -fh * 0.6), fc + Vector2(sin(tt * 1.8) * 1.5, -fh), fc + Vector2(3, -fh * 0.6), fc + Vector2(9, 0), fc + Vector2(0, 6)]), Color(1.0, 0.65, 0.2))
		draw_colored_polygon(PackedVector2Array([fc + Vector2(-4, 0), fc + Vector2(0, -fh * 0.65), fc + Vector2(4, 0), fc + Vector2(0, 4)]), Color(1.0, 0.95, 0.75))
		for x: float in [-30.0, 30.0]:
			draw_line(lc + Vector2(x, -44), lc + Vector2(x, 40), BRASS.darkened(0.15), 4.0)
		draw_line(lc + Vector2(0, -44), lc + Vector2(0, 40), Color(BRASS.darkened(0.25), 0.8), 2.0)
		DU.box(self, Rect2(lc + Vector2(-36, 40), Vector2(72, 10)), Color(0.22, 0.17, 0.11))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# braises qui montent de la lanterne
		for i in 22:
			var s := fposmod(tt * (0.06 + fposmod(i * 0.137, 0.05)) + i * 0.31, 1.0)
			var p := c + Vector2(sin(i * 3.1 + tt * 0.8) * (30.0 + i * 9.0), 30.0 - s * size.y * 0.55)
			draw_circle(p, 1.6 * (1.0 - s) + 0.4, Color(1.0, 0.7, 0.3, (1.0 - s) * 0.8))

	# ---- éclairage d'un point par la Lanterne (même forme que le voile)
	func lit(p: Vector2) -> float:
		var c := _lamp()
		var h := size.y
		var halo := 1.0 - smoothstep(0.0, h * 0.42, p.distance_to(c))
		var d := (p - (c + Vector2(0, h * 0.40))) / Vector2(h * 0.62, h * 0.46)
		var cone := 1.0 - smoothstep(0.30, 1.0, d.length())
		var col := smoothstep(size.x * 0.52, size.x * 0.22, p.x)
		return clampf(maxf(cone * 0.95, halo * 0.8) * breath, 0.0, 1.0) * (1.0 - col * 0.9)
	func shade(col: Color, p: Vector2, amb := 0.08) -> Color:
		var night := Color(0.02, 0.018, 0.03)
		var l := maxf(lit(p), amb)
		var warm := col.lerp(Color(1.0, 0.75, 0.45), 0.12 * l)
		return night.lerp(warm, l)
	func spoly(pts: PackedVector2Array, col: Color) -> void:
		var cc := Vector2.ZERO
		for q in pts:
			cc += q
		draw_colored_polygon(pts, shade(col, cc / pts.size()))
	func srect(r: Rect2, col: Color) -> void:
		draw_rect(r, shade(col, r.get_center()))
	func window(r: Rect2, tt: float, k: int) -> void:
		var fl := 0.85 + 0.15 * sin(tt * (3.0 + k % 3) + k * 1.7)
		DU.glow(self, r.get_center(), r.size.x * 1.8, Color(1.0, 0.7, 0.35), 0.35 * fl)
		draw_rect(r, Color(1.0, 0.78, 0.42).lerp(Color(1.0, 0.9, 0.6), 0.3 * fl))
		draw_line(r.position + Vector2(r.size.x / 2.0, 0), r.position + Vector2(r.size.x / 2.0, r.size.y), Color(0.25, 0.15, 0.08), 1.2)
		draw_line(r.position + Vector2(0, r.size.y / 2.0), r.position + Vector2(r.size.x, r.size.y / 2.0), Color(0.25, 0.15, 0.08), 1.2)
	func garland(a: Vector2, b: Vector2, sag: float, tt: float, k: int) -> void:
		var pts := PackedVector2Array()
		for i in 13:
			var u := i / 12.0
			pts.append(a.lerp(b, u) + Vector2(0, sin(u * PI) * sag))
		draw_polyline(pts, Color(0.12, 0.09, 0.07), 1.2)
		for i in range(1, 12, 2):
			var p := pts[i] + Vector2(0, 3)
			var f := 0.7 + 0.3 * sin(tt * 2.5 + i + k)
			DU.glow(self, p, 7.0, Color(1.0, 0.75, 0.4), 0.45 * f)
			draw_circle(p, 1.8, Color(1.0, 0.85, 0.5))

	# ---- modèle 4 : les habitants réunis autour d'un feu sous la Lanterne, quelques échoppes dans
	# les coins ; tout est éclairé par la Lanterne qui vacille. Ce sont les vrais dessins du jeu.
	var camp: Node2D
	var force_cast := -1
	var camp_props := []    # [noeud, x relatif, y relatif, échelle, regard]
	const PropScript = preload("res://scripts/prop.gd")
	func _camp_setup() -> void:
		camp = Node2D.new()
		add_child(camp)
		# (type, x en fraction de largeur, décalage du sol, échelle, regard)
		# une composition tirée au hasard à chaque lancement du jeu
		var casts := [
			[["tailor", 0.585, 0.01, 1.15, 1.0], ["hero", 0.685, 0.0, 1.2, 1.0], ["elder", 0.77, 0.01, 1.15, -1.0]],
			[["scriptorium", 0.55, -0.01, 1.1, 1.0], ["hero", 0.645, 0.0, 1.2, 1.0], ["merchant", 0.71, -0.01, 1.1, 1.0]],
			[["cartographer", 0.6, 0.0, 1.1, 1.0], ["hero", 0.7, 0.0, 1.2, -1.0], ["elder", 0.785, 0.01, 1.1, -1.0]],
		]
		var cast: Array = casts[force_cast if force_cast >= 0 else randi() % casts.size()]
		for c in cast:
			var pr := Node2D.new()
			if c[0] == "hero":
				# le héros (avec ses cosmétiques), au centre, sous la Lanterne
				pr.draw.connect(func():
					var tt := t if Settings.menu_anim else 0.0
					pr.draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(0, -3), Vector2(14, 0), Vector2(0, 3)]), Color(0, 0, 0, 0.45))
					GameState.cos.draw_hero(pr, sin(tt * 2.5) * 0.6, sin(tt * 2.0) * 1.0, tt, false, false))
				camp.add_child(pr)
			else:
				pr.set_script(PropScript)
				pr.kind = c[0]
				camp.add_child(pr)
				pr.remove_from_group("sleepy")
			camp_props.append([pr, c[1], c[2], c[3], c[4]])
	func _campfire(tt: float) -> void:
		if camp == null:
			_camp_setup()
		var w := size.x
		var h := size.y
		var k := h / 720.0
		var ground := h * 0.84
		var fire := Vector2(w * 0.7, ground)
		# la Lanterne vacille : la lumière arrive par vagues
		var flux := (0.93 + 0.05 * sin(tt * 0.9) + 0.02 * sin(tt * 1.6)) if Settings.menu_anim else 1.0
		# sol : un tertre de roche éclairé
		var mound := PackedVector2Array()
		for i in 25:
			var u := i / 24.0
			mound.append(Vector2(w * 0.3 + u * w * 0.72, ground + 6.0 - sin(u * PI) * 10.0 + sin(u * 17.0) * 2.0))
		mound.append(Vector2(w * 1.02, h))
		mound.append(Vector2(w * 0.3, h))
		var cols := PackedColorArray()
		for q in mound:
			cols.append(shade(Color(0.24, 0.19, 0.16), q, 0.0))
		draw_polygon(mound, cols)
		# habitants (vrais dessins du jeu), éclairés selon la distance à la lumière
		for c in camp_props:
			var pr: Node2D = c[0]
			pr.position = Vector2(w * c[1], ground + h * c[2])
			pr.scale = Vector2(c[3] * c[4], c[3]) * k
			var l := maxf(lit(pr.position + Vector2(0, -40)), 1.0 - smoothstep(0.0, w * 0.22, pr.position.distance_to(fire)))
			var v := lerpf(0.18, 1.1, l) * flux
			pr.modulate = Color(v, v * 0.9, v * 0.76)
			pr.z_index = 0   # pas au-dessus des fenêtres du menu (choix de difficulté…)
			if pr.get_script() == null:
				pr.queue_redraw()

	var camp_fire: Node2D
	func _draw_fire() -> void:
		var f := camp_fire
		var tt := t if Settings.menu_anim else 0.0
		var k := size.y / 720.0
		var fire := Vector2(size.x * 0.7, size.y * 0.84)
		var flux := (0.86 + 0.08 * sin(tt * 2.1) + 0.06 * sin(tt * 7.7) * sin(tt * 3.1)) if Settings.menu_anim else 1.0
		for i in 7:
			var a := PI + i * PI / 6.0
			DU.ball(f, fire + Vector2(cos(a) * 26.0, 4.0 + absf(sin(a)) * 3.0) * k, 6.0 * k, shade(Color(0.42, 0.38, 0.36), fire))
		for side in [-1.0, 1.0]:
			f.draw_line(fire + Vector2(-20 * side, 6) * k, fire + Vector2(14 * side, -6) * k, Color(0.3, 0.18, 0.1), 6.0 * k)
		var fh := (34.0 + 6.0 * sin(tt * 11.0) + 4.0 * sin(tt * 17.0)) * k
		DU.glow(f, fire + Vector2(0, -16) * k, 60.0 * k, Color(1.0, 0.65, 0.25), 0.6 * flux)
		for j in 3:
			var sw := sin(tt * (6.0 + j * 2.0) + j) * 4.0 * k
			var ww := (16.0 - j * 4.0) * k
			var hh := fh * (1.0 - j * 0.25)
			var col: Color = [Color(1.0, 0.45, 0.12), Color(1.0, 0.7, 0.2), Color(1.0, 0.95, 0.7)][j]
			f.draw_colored_polygon(PackedVector2Array([fire + Vector2(-ww, -2 * k), fire + Vector2(-ww * 0.4, -hh * 0.55), fire + Vector2(sw, -hh), fire + Vector2(ww * 0.4, -hh * 0.55), fire + Vector2(ww, -2 * k)]), col)
		for i in 12:
			var u := fposmod(tt * (0.35 + (i % 4) * 0.08) + i * 0.17, 1.0)
			var p := fire + Vector2(sin(i * 2.3 + tt * 2.0) * 14.0 * (0.3 + u), -20.0 - u * 140.0) * k
			f.draw_circle(p, (1.8 * (1.0 - u) + 0.4) * k, Color(1.0, 0.7, 0.3, 0.9 * (1.0 - u)))

	# ---- modèle 3 : le Sanctuaire en vue isométrique, simplifié en volumes (sans rien dévoiler) :
	# un îlot de roche suspendu dans le noir, quelques bâtisses, une tour d'où pend une corde
	var _io := Vector2.ZERO
	var _is := 26.0
	func iso(x: float, y: float, z := 0.0) -> Vector2:
		return _io + Vector2((x - y) * 0.866, (x + y) * 0.5 - z) * _is
	func _face(pts: Array, col: Color, k: float) -> void:
		var pp := PackedVector2Array(pts)
		var cc := Vector2.ZERO
		for q in pp:
			cc += q
		draw_colored_polygon(pp, shade(col.darkened(k), cc / pp.size()))
	func prism(x: float, y: float, wx: float, wy: float, z0: float, hgt: float, col: Color, roof := 0.0) -> void:
		var z1 := z0 + hgt
		# faces visibles : avant gauche (y = y + wy), avant droite (x = x + wx), dessus
		_face([iso(x, y + wy, z0), iso(x + wx, y + wy, z0), iso(x + wx, y + wy, z1), iso(x, y + wy, z1)], col, 0.35)
		_face([iso(x + wx, y, z0), iso(x + wx, y + wy, z0), iso(x + wx, y + wy, z1), iso(x + wx, y, z1)], col, 0.15)
		if roof <= 0.0:
			_face([iso(x, y, z1), iso(x + wx, y, z1), iso(x + wx, y + wy, z1), iso(x, y + wy, z1)], col, -0.1)
		else:
			# toit à deux pans, faîte parallèle à x
			var my := y + wy / 2.0
			var rc := Color(0.3, 0.2, 0.2)
			_face([iso(x, y + wy, z1), iso(x + wx, y + wy, z1), iso(x + wx, my, z1 + roof), iso(x, my, z1 + roof)], rc, 0.05)
			_face([iso(x + wx, y, z1), iso(x + wx, y + wy, z1), iso(x + wx, my, z1 + roof)], col, 0.25)
			_face([iso(x, y, z1), iso(x + wx, y, z1), iso(x + wx, my, z1 + roof), iso(x, my, z1 + roof)], rc, -0.1)
	func iso_window(p: Vector2, tt: float, k: int) -> void:
		var fl := 0.8 + 0.2 * sin(tt * (2.5 + k % 3) + k * 1.3)
		DU.glow(self, p, _is * 0.9, Color(1.0, 0.7, 0.35), 0.4 * fl)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-0.18, -0.3) * _is, p + Vector2(0.18, -0.2) * _is, p + Vector2(0.18, 0.2) * _is, p + Vector2(-0.18, 0.1) * _is]), Color(1.0, 0.8, 0.45))

	func _iso_sanctuary(tt: float) -> void:
		var w := size.x
		var h := size.y
		_is = h / 720.0 * 23.0
		var bob := sin(tt * 0.6) * 3.0 * (h / 720.0)
		_io = Vector2(w * 0.68, h * 0.53 + bob)
		var rock := Color(0.3, 0.25, 0.22)
		# l'îlot : dalle épaisse, puis roche qui s'effile vers le bas
		var X := 11.0
		var Y := 8.0
		var cx := X / 2.0
		var cy := Y / 2.0
		_face([iso(0, Y, 0), iso(X, Y, 0), iso(X, Y, -1.4), iso(0, Y, -1.4)], rock, 0.35)
		_face([iso(X, 0, 0), iso(X, Y, 0), iso(X, Y, -1.4), iso(X, 0, -1.4)], rock, 0.15)
		_face([iso(0, Y, -1.4), iso(X, Y, -1.4), iso(cx + 1, cy + 1, -9.0)], rock, 0.5)
		_face([iso(X, 0, -1.4), iso(X, Y, -1.4), iso(cx + 1, cy + 1, -9.0)], rock, 0.3)
		for k in 5:
			var a := iso(1.0 + k * 2.2, Y, -1.4)
			draw_line(a, a.lerp(iso(cx + 1, cy + 1, -9.0), 0.6 + 0.08 * k), shade(rock.darkened(0.55), a), 1.5)
		_face([iso(0, 0, 0), iso(X, 0, 0), iso(X, Y, 0), iso(0, Y, 0)], Color(0.36, 0.3, 0.25), -0.05)
		# dallage : quelques lignes
		for i in range(1, int(X)):
			draw_line(iso(i, 0, 0), iso(i, Y, 0), shade(Color(0.25, 0.2, 0.17), iso(i, cy, 0)), 1.0)
		# bâtisses (de l'arrière vers l'avant pour l'ordre de dessin)
		var wood := Color(0.42, 0.3, 0.2)
		var stone := Color(0.4, 0.36, 0.33)
		prism(1.0, 0.6, 2.4, 1.8, 0.0, 1.6, stone, 1.0)
		iso_window(iso(3.4, 1.4, 0.9), tt, 1)
		# la tour, ossature ouverte, d'où une corde monte dans le noir
		var tx := 7.6
		var ty := 0.8
		for c in [[0.0, 0.0], [1.4, 0.0], [1.4, 1.4], [0.0, 1.4]]:
			draw_line(iso(tx + c[0], ty + c[1], 0), iso(tx + c[0], ty + c[1], 5.5), shade(wood.darkened(0.2), iso(tx, ty, 3)), 2.5)
		for zz in [1.8, 3.6, 5.5]:
			draw_polyline(PackedVector2Array([iso(tx, ty + 1.4, zz), iso(tx + 1.4, ty + 1.4, zz), iso(tx + 1.4, ty, zz)]), shade(wood, iso(tx, ty, zz)), 2.0)
		var top := iso(tx + 0.7, ty + 0.7, 5.5)
		draw_line(top, Vector2(top.x, 0), Color(0.35, 0.3, 0.25, 0.6), 1.2)
		var cage_z := 1.2 + (sin(tt * 0.35) * 0.5 + 0.5) * 2.8
		prism(tx + 0.3, ty + 0.3, 0.8, 0.8, cage_z, 0.9, Color(0.5, 0.4, 0.25))
		# auvent et étals
		prism(4.3, 0.8, 1.8, 1.2, 0.0, 0.8, wood)
		_face([iso(4.1, 2.2, 1.5), iso(6.3, 2.2, 1.5), iso(6.3, 0.8, 1.9), iso(4.1, 0.8, 1.9)], Color(0.38, 0.3, 0.3), 0.0)
		iso_window(iso(5.2, 2.0, 0.5), tt, 2)
		prism(1.2, 4.2, 2.6, 2.2, 0.0, 1.9, stone, 1.2)
		iso_window(iso(2.4, 6.4, 1.1), tt, 3)
		iso_window(iso(3.8, 5.3, 1.1), tt, 4)
		prism(5.0, 4.6, 1.4, 1.4, 0.0, 1.0, wood, 0.7)
		iso_window(iso(6.4, 5.3, 0.6), tt, 5)
		# arche de pierre et banc à l'avant
		prism(8.2, 5.2, 0.4, 0.4, 0.0, 2.0, stone)
		prism(9.8, 5.2, 0.4, 0.4, 0.0, 2.0, stone)
		prism(8.2, 5.2, 2.0, 0.4, 2.0, 0.4, stone)
		prism(7.4, 7.0, 1.6, 0.4, 0.0, 0.35, wood)
		# petites lanternes sur poteaux, et silhouette d'un voyageur minuscule
		for L in [[0.4, 7.4], [10.4, 3.0], [4.0, 7.4], [10.4, 7.4]]:
			var b2 := iso(L[0], L[1], 0)
			var t2 := iso(L[0], L[1], 1.3)
			draw_line(b2, t2, shade(Color(0.2, 0.17, 0.15), b2), 1.5)
			var f := 0.75 + 0.25 * sin(tt * 3.0 + L[0])
			DU.glow(self, t2, _is * 0.8, Color(1.0, 0.72, 0.4), 0.45 * f)
			draw_circle(t2, _is * 0.12, Color(1.0, 0.85, 0.55))
		var hp := iso(6.8, 6.6, 0)
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-3, 0), hp + Vector2(3, 0), hp + Vector2(2, -9), hp + Vector2(-2, -9)]), Color(0.08, 0.07, 0.1))
		draw_circle(hp + Vector2(0, -12), 3.2, Color(0.08, 0.07, 0.1))
		# poussière lumineuse qui tombe de l'îlot dans le vide
		for i in 14:
			var u := fposmod(tt * 0.08 + i * 0.137, 1.0)
			var p := iso(1.0 + fposmod(i * 3.7, 9.0), Y, -1.4 - u * 9.0)
			draw_circle(p, 1.4, Color(1.0, 0.75, 0.4, 0.5 * (1.0 - u) * maxf(lit(p), 0.2)))

	# ---- modèle 1 : village troglodyte creusé dans la paroi, fenêtres allumées, guirlandes
	func _village_troglo(tt: float) -> void:
		var w := size.x
		var h := size.y
		var x0 := w * 0.36
		var rock := Color(0.24, 0.19, 0.16)
		# paroi du fond, irrégulière
		var wx := w * 0.2
		var wall := PackedVector2Array([Vector2(wx, h)])
		for i in 15:
			var u := i / 14.0
			wall.append(Vector2(wx + u * (w - wx), h * 0.5 + sin(u * 11.0) * 22.0 + sin(u * 31.0) * 8.0 - sin(u * PI) * 40.0))
		wall.append(Vector2(w, h))
		spoly(wall, rock.darkened(0.25))
		# trois rangées de maisons creusées, en gradins
		var rows := [[h * 0.66, 0.85], [h * 0.78, 0.95], [h * 0.9, 1.05]]
		var k := 0
		for ri in rows.size():
			var gy: float = rows[ri][0]
			var sc: float = rows[ri][1]
			# corniche de la rangée
			spoly(PackedVector2Array([Vector2(x0 + 20 - ri * 30, gy), Vector2(w, gy), Vector2(w, gy + 10), Vector2(x0 + 10 - ri * 30, gy + 10)]), rock.lightened(0.12))
			var x := x0 + 60.0 + ri * 40.0 - ri * 30.0
			while x < w - 40.0:
				var hw := (54.0 + float((k * 37) % 30)) * sc
				var hh := (62.0 + float((k * 53) % 26)) * sc
				var r := Rect2(x, gy - hh, hw, hh)
				srect(r, rock.lightened(0.05 + 0.04 * (k % 3)))
				# linteau et porte en arc
				srect(Rect2(r.position + Vector2(-4, -6), Vector2(hw + 8, 8)), rock.lightened(0.2))
				var door := Rect2(x + hw * 0.18, gy - hh * 0.55, hw * 0.28, hh * 0.55)
				srect(door, Color(0.1, 0.07, 0.06))
				draw_arc(door.position + Vector2(door.size.x / 2.0, 0), door.size.x / 2.0, PI, TAU, 10, shade(rock.lightened(0.25), door.get_center()), 2.0)
				if k % 4 != 3:
					window(Rect2(x + hw * 0.6, gy - hh * 0.72, hw * 0.24, hh * 0.24), tt, k)
				else:
					srect(Rect2(x + hw * 0.6, gy - hh * 0.72, hw * 0.24, hh * 0.24), Color(0.08, 0.06, 0.06))
				# petite cheminée qui fume
				if k % 3 == 1:
					var cx := x + hw * 0.78
					srect(Rect2(cx, gy - hh - 16, 9, 12), rock.lightened(0.1))
					for j in 4:
						var u := fposmod(tt * 0.25 + j * 0.25 + k * 0.1, 1.0)
						draw_circle(Vector2(cx + 4 + sin(u * 6.0 + k) * 6.0, gy - hh - 18 - u * 60.0), 4.0 + u * 7.0, Color(0.55, 0.5, 0.48, 0.18 * (1.0 - u) * maxf(lit(Vector2(cx, gy - hh)), 0.3)))
				x += hw + 26.0 + float((k * 29) % 22)
				k += 1
			# escalier vers la rangée suivante
			if ri < 2:
				var sx := x0 + 30.0 + ri * 140.0
				for st in 6:
					srect(Rect2(sx + st * 9.0, gy + 10 + st * (h * 0.12 / 6.0), 12, 5), rock.lightened(0.15))
		# guirlandes entre les maisons
		garland(Vector2(x0 + 70, h * 0.6), Vector2(w * 0.95, h * 0.58), 26.0, tt, 1)
		garland(Vector2(x0 + 40, h * 0.73), Vector2(w * 0.9, h * 0.71), 20.0, tt, 2)
		# brume au sol
		for i in 3:
			var y := h * (0.86 + i * 0.05)
			DU.vgrad(self, Rect2(x0 - 100, y, w - x0 + 100, 40), Color(0.6, 0.45, 0.3, 0.0), Color(0.6, 0.45, 0.3, 0.06 * maxf(lit(Vector2(w * 0.7, y)), 0.2)))

	# ---- modèle 2 : hameau de bois sur pilotis accroché aux corniches, ponts de corde et lanternes
	func _village_hameau(tt: float) -> void:
		var w := size.x
		var h := size.y
		var x0 := w * 0.38
		var rock := Color(0.2, 0.17, 0.16)
		var wood := Color(0.42, 0.28, 0.17)
		# silhouette de stalagmites au loin
		for i in 9:
			var bx := x0 + i * (w - x0) / 8.0
			var th := 140.0 + float((i * 61) % 90)
			spoly(PackedVector2Array([Vector2(bx - 40, h), Vector2(bx, h - th - h * 0.25), Vector2(bx + 40, h)]), rock.darkened(0.4))
		# corniches rocheuses à plusieurs hauteurs
		var ledges := [[x0 + 30.0, w * 0.6, h * 0.7], [w * 0.62, w * 0.86, h * 0.62], [w * 0.8, w, h * 0.78], [x0 - 20.0, w, h * 0.92]]
		for L in ledges:
			var a: float = L[0]
			var b: float = L[1]
			var y: float = L[2]
			spoly(PackedVector2Array([Vector2(a, y), Vector2(b, y), Vector2(b - 10, y + 22), Vector2((a + b) / 2.0, y + 46), Vector2(a + 14, y + 20)]), rock)
			draw_line(Vector2(a, y), Vector2(b, y), shade(Color(0.55, 0.45, 0.25), Vector2((a + b) / 2.0, y)), 2.0)
		# maisons de bois sur pilotis, toits pointus
		var houses := [[x0 + 70.0, h * 0.7, 1.0], [x0 + 190.0, h * 0.7, 0.85], [w * 0.66, h * 0.62, 0.95], [w * 0.88, h * 0.78, 1.05], [w * 0.52, h * 0.92, 1.1], [w * 0.74, h * 0.92, 0.9]]
		var k := 0
		for H in houses:
			var hx: float = H[0]
			var gy: float = H[1]
			var sc: float = H[2]
			var hw := 70.0 * sc
			var hh := 52.0 * sc
			var by := gy - 14.0 * sc
			for px in [6.0, hw - 10.0]:
				srect(Rect2(hx + px, by, 4, gy - by + 4), wood.darkened(0.3))
			srect(Rect2(hx, by - hh, hw, hh), wood)
			for j in int(hh / 8.0):
				draw_line(Vector2(hx, by - hh + j * 8.0), Vector2(hx + hw, by - hh + j * 8.0), shade(wood.darkened(0.25), Vector2(hx + hw / 2.0, by - hh / 2.0)), 1.0)
			spoly(PackedVector2Array([Vector2(hx - 8, by - hh), Vector2(hx + hw / 2.0, by - hh - 34.0 * sc), Vector2(hx + hw + 8, by - hh)]), Color(0.3, 0.2, 0.22))
			srect(Rect2(hx + hw * 0.12, by - hh * 0.62, hw * 0.22, hh * 0.62), Color(0.12, 0.08, 0.06))
			window(Rect2(hx + hw * 0.55, by - hh * 0.7, hw * 0.24, hh * 0.3), tt, k)
			# cheminée et fumée
			var cx := hx + hw * 0.72
			srect(Rect2(cx, by - hh - 30.0 * sc, 8, 20), Color(0.3, 0.26, 0.24))
			for j in 4:
				var u := fposmod(tt * 0.22 + j * 0.25 + k * 0.17, 1.0)
				draw_circle(Vector2(cx + 4 + sin(u * 5.0 + k) * 7.0, by - hh - 34.0 * sc - u * 70.0), 4.0 + u * 8.0, Color(0.55, 0.5, 0.48, 0.18 * (1.0 - u) * maxf(lit(Vector2(cx, by - hh)), 0.3)))
			k += 1
		# ponts de corde entre les corniches, avec leurs lanternes
		for B in [[Vector2(w * 0.6, h * 0.7), Vector2(w * 0.62, h * 0.62)], [Vector2(w * 0.86, h * 0.62), Vector2(w * 0.8, h * 0.78)]]:
			var a2: Vector2 = B[0]
			var b2: Vector2 = B[1]
			var pts := PackedVector2Array()
			for i in 11:
				var u := i / 10.0
				pts.append(a2.lerp(b2, u) + Vector2(0, sin(u * PI) * 16.0))
			for i in 10:
				draw_line(pts[i] + Vector2(0, 2), pts[i + 1] + Vector2(0, 2), shade(wood.darkened(0.2), pts[i]), 3.0)
			draw_polyline(pts, shade(Color(0.5, 0.42, 0.3), a2), 1.0)
		garland(Vector2(x0 + 40, h * 0.56), Vector2(w * 0.97, h * 0.5), 34.0, tt, 3)
		# lucioles
		for i in 12:
			var p := Vector2(x0 + fposmod(i * 97.0 + tt * 12.0 * (1 + i % 3), w - x0), h * 0.55 + fposmod(i * 53.0, h * 0.4) + sin(tt * 1.5 + i) * 10.0)
			var a3 := 0.5 + 0.5 * sin(tt * 3.0 + i * 2.0)
			DU.glow(self, p, 6.0, Color(0.9, 1.0, 0.6), 0.4 * a3)

func _centered_panel(root: Control) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var p := PanelContainer.new()
	center.add_child(p)
	return p

func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	return l

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 46)
	b.pressed.connect(cb)
	return b

func _build_pause(root: Control) -> void:
	pause_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pause_panel.add_child(v)
	v.add_child(_title("Pause"))
	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	route = Label.new()
	route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route.add_theme_font_size_override("font_size", 13)
	route.add_theme_color_override("font_color", Color(0.5, 0.56, 0.68))
	_update_info()
	v.add_child(info)
	v.add_child(route)
	first_pause_button = _button("Reprendre", close)
	v.add_child(first_pause_button)
	v.add_child(_button("Commandes", _open_controls))
	v.add_child(_button("Options", _open_options))
	v.add_child(_button("Succès", _open_achievements))
	if GameState.is_tutorial():
		v.add_child(_button("Passer le tutoriel", func(): GameState.go_next_level(main.player)))
	if GameState.is_tutorial():
		v.add_child(_button("Recommencer le tutoriel", _restart))
	if GameState.mode == "descent":
		v.add_child(_button("Abandonner la descente", func(): GameState.abandon_descent()))
	elif GameState.mode == "duel":
		v.add_child(_button("Quitter le duel", func(): GameState.end_duel(0)))
	v.add_child(_button("Parties…", _open_slots))
	if GameState.mode == "hub":
		# au Sanctuaire : retour à l'écran-titre (la partie est sauvegardée avant)
		v.add_child(_button("Écran-titre", func():
			GameState.save_game()
			_to_title()))
	if not OS.has_feature("web"):   # dans un navigateur, on ferme simplement l'onglet
		v.add_child(_button("Quitter le jeu", func(): get_tree().quit()))

# Textes composés du menu (à refaire quand la langue change)
func _update_info() -> void:
	if info == null:
		return
	if GameState.is_tutorial():
		info.text = "Tutoriel"
	elif GameState.is_hub():
		info.text = tr("Sanctuaire — %s — record : palier %d") % [GameState.diff_name(), GameState.record]
	else:
		info.text = tr("Palier %d — niveau %d / %d — %s") % [GameState.palier, GameState.step, GameState.STEPS_PER_PALIER, GameState.diff_name()]
	route.text = "" if GameState.is_tutorial() else (tr("Progression sauvegardée automatiquement") + (tr(" (mode portable : dossier « sauvegardes » à côté du jeu)") if Paths.is_portable() else ""))
	if save_label:
		var cs2: int = GameState.continue_slot()
		if cs2 > 0:
			save_label.text = tr("Emplacement %d") % cs2 + " — " + GameState.save_summary(cs2)

func _build_achievements(root: Control) -> void:
	ach_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	ach_panel.add_child(v)
	v.add_child(_title("Succès"))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(620, 380)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	v.add_child(sc)
	ach_list = VBoxContainer.new()
	ach_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ach_list.add_theme_constant_override("separation", 4)
	sc.add_child(ach_list)
	ach_back = _button("Retour", _back_to_pause)
	ach_back.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(ach_back)
	v.add_child(row)

# ---------------------------------------------------------------- Discord (familier « Tube néon »)
class NeonPreview extends Control:
	const PetScript = preload("res://scripts/pet.gd")
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, 46.0, Color(0.07, 0.055, 0.045))
		draw_arc(c, 46.0, 0.0, TAU, 40, Color(0.85, 0.7, 0.35), 2.0)
		var base := Transform2D(0.0, Vector2(3.2, 3.2), 0.0, c + Vector2(sin(t * 1.7) * 4.0, sin(t * 2.3) * 3.0))
		draw_set_transform_matrix(base)
		PetScript.draw_pet(self, "pet_neon", Color(1.0, 0.3, 0.75), t, base)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _build_discord(root: Control) -> void:
	discord_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	discord_panel.add_child(v)
	v.add_child(_title("Discord"))
	var txt := Label.new()
	txt.text = "Rejoins le serveur Discord de la communauté : le code du jour y est posté. Tape-le ici pour recevoir le familier « Tube néon »."
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.custom_minimum_size = Vector2(520, 0)
	txt.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	v.add_child(txt)
	var prev := NeonPreview.new()
	prev.custom_minimum_size = Vector2(520, 110)
	v.add_child(prev)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	var join := _button("Rejoindre le serveur", func(): discord.join())
	discord_join = join
	join.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(join)
	v.add_child(col)
	var crow := HBoxContainer.new()
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	crow.add_theme_constant_override("separation", 8)
	discord_code = LineEdit.new()
	discord_code.placeholder_text = tr("Code du jour (XXXX-XXXX)")
	discord_code.max_length = 12
	discord_code.custom_minimum_size = Vector2(230, 44)
	discord_code.alignment = HORIZONTAL_ALIGNMENT_CENTER
	discord_code.text_submitted.connect(func(t: String): discord.redeem(t))
	crow.add_child(discord_code)
	discord_link_btn = _button("Valider", func(): discord.redeem(discord_code.text))
	discord_link_btn.custom_minimum_size = Vector2(130, 44)
	crow.add_child(discord_link_btn)
	v.add_child(crow)
	discord_status = Label.new()
	discord_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discord_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	discord_status.custom_minimum_size = Vector2(520, 44)
	discord_status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	v.add_child(discord_status)
	var back := _button("Retour", _back_to_pause)
	back.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(back)
	v.add_child(row)
	discord = Node.new()
	discord.set_script(load("res://scripts/discord_link.gd"))
	add_child(discord)
	discord.link_changed.connect(_on_discord)

func _on_discord(st: String) -> void:
	match st:
		"checking":
			discord_status.text = tr("Vérification du code…")
		"ok":
			discord_status.text = tr("Code accepté ! Familier « Tube néon » reçu et porté.")
			Audio.sfx("crit_ready", 0.0, -4.0)
		"bad_code":
			discord_status.text = tr("Code incorrect ou expiré : prends celui du jour sur le serveur.")
		"not_configured":
			discord_status.text = tr("Bientôt disponible : le code du jour n'est pas encore activé.")
		"too_many":
			discord_status.text = tr("Trop d'essais : réessaie demain.")
		"offline":
			discord_status.text = tr("Pas de connexion : réessaie plus tard.") + ("  [%s]" % discord.last_net if discord.last_net != "" else "")
	discord_link_btn.disabled = discord.has_pet()
	discord_code.editable = not discord.has_pet()

func _open_discord() -> void:
	discord_status.text = tr("Familier « Tube néon » déjà reçu ✔") if discord.has_pet() else ""
	discord_link_btn.disabled = discord.has_pet()
	discord_code.editable = not discord.has_pet()
	discord_code.text = ""
	_go(discord_panel)
	(discord_code if not discord.has_pet() else discord_join).grab_focus()

func _open_achievements() -> void:
	for ch in ach_list.get_children():
		ach_list.remove_child(ch)
		ch.queue_free()
	var n := 0
	for a in Achievements.LIST:
		var ok: bool = Achievements.done.has(a[0])
		if ok:
			n += 1
		var l := Label.new()
		l.text = ("✔  " if ok else "·  ") + tr(a[1]) + " — " + tr(a[2])
		for item_id in GameState.cos.for_achievement(a[0]):
			l.text += "  " + tr("(récompense : %s)") % tr(GameState.cos.item(item_id)["name"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(600, 0)
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55) if ok else Color(0.55, 0.58, 0.68))
		ach_list.add_child(l)
	var head := Label.new()
	head.text = tr("%d / %d débloqués") % [n, Achievements.LIST.size()]
	head.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	ach_list.add_child(head)
	ach_list.move_child(head, 0)
	_go(ach_panel)
	ach_back.grab_focus()

func _build_controls(root: Control) -> void:
	controls_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	controls_panel.add_child(v)
	v.add_child(_title("Commandes"))
	pad_info = Label.new()
	pad_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad_info.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	v.add_child(pad_info)
	# disposition du clavier (noms des touches affichés)
	var lrow := HBoxContainer.new()
	lrow.alignment = BoxContainer.ALIGNMENT_CENTER
	lrow.add_theme_constant_override("separation", 10)
	var ll := Label.new()
	ll.text = "Clavier :"
	lrow.add_child(ll)
	layout_btn = OptionButton.new()
	for lt in Controls.LAYOUT_LABELS:
		layout_btn.add_item(lt)
	layout_btn.selected = int(Settings.kb_layout)
	layout_btn.item_selected.connect(func(i):
		Settings.set_value("kb_layout", i)
		_refresh())
	lrow.add_child(layout_btn)
	v.add_child(lrow)
	# En-têtes fixes, puis liste défilante (molette, glisser, ou navigation clavier/manette)
	var header := GridContainer.new()
	header.columns = 4
	header.add_theme_constant_override("h_separation", 8)
	v.add_child(header)
	var widths := [150, 165, 165, 165]
	var heads := ["Action", "Touche 1", "Touche 2", "Manette"]
	for i in 4:
		var l := Label.new()
		if i == 3:
			pad_header = l
		l.text = heads[i]
		l.custom_minimum_size = Vector2(widths[i], 0)
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
		header.add_child(l)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	v.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	for a in Controls.ACTIONS:
		var name_l := Label.new()
		name_l.text = Controls.LABELS[a]
		name_l.custom_minimum_size = Vector2(150, 0)
		name_l.add_theme_font_size_override("font_size", 16)
		grid.add_child(name_l)
		for slot in 3:
			var b := Button.new()
			b.set_script(GlyphButtonScript)
			b.custom_minimum_size = Vector2(165, 28)
			b.add_theme_font_size_override("font_size", 15)
			b.clip_text = true
			b.pressed.connect(_start_wait.bind(a, slot))
			b.gui_input.connect(_cell_gui_input.bind(a, slot))
			grid.add_child(b)
			cells["%s:%d" % [a, slot]] = b
	status = Label.new()
	status.add_theme_font_size_override("font_size", 16)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(640, 0)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.custom_minimum_size = Vector2(0, 30)
	status.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	v.add_child(status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var bd := _button("Touches par défaut", _on_defaults)
	bd.custom_minimum_size = Vector2(240, 40)
	row.add_child(bd)
	var br := _button("Retour", _back_to_pause)
	br.custom_minimum_size = Vector2(160, 40)
	row.add_child(br)
	v.add_child(row)

# ---------------------------------------------------------------- écran Options
func _build_options(root: Control) -> void:
	options_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	options_panel.add_child(v)
	v.add_child(_title("Options"))
	var oscroll := ScrollContainer.new()
	oscroll.custom_minimum_size = Vector2(560, 400)
	oscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	oscroll.follow_focus = true
	v.add_child(oscroll)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 8)
	oscroll.add_child(g)
	_section(g, "Langue")
	_choice_row(g, "Langue / Language", "language", Lang.NAMES)
	_section(g, "Son")
	_slider_row(g, "Volume général", "master_volume", 0.0, 1.0, 0.05, true)
	_slider_row(g, "Musique", "music_volume", 0.0, 1.0, 0.05, true)
	_slider_row(g, "Effets sonores", "sfx_volume", 0.0, 1.0, 0.05, true)
	_section(g, "Affichage")
	_slider_row(g, "Taille du HUD", "hud_scale", 0.6, 1.6, 0.05, true)
	_slider_row(g, "Taille des menus", "menu_scale", 0.6, 1.3, 0.05, true)
	_slider_row(g, "Zoom de la caméra", "zoom", 0.9, 1.8, 0.05, false)
	_check_row(g, "Plein écran (F11)", "fullscreen")
	_check_row(g, "Synchronisation verticale", "vsync")
	_check_row(g, "Aides à l'écran", "show_hints")
	_choice_row(g, "Limite d'images par seconde", "fps_cap", Settings.FPS_LABELS)
	_choice_row(g, "Qualité graphique", "gfx_quality", Settings.GFX_LABELS)
	_check_row(g, "Afficher les FPS", "show_fps")
	_check_row(g, "Écran titre animé", "menu_anim")
	_check_row(g, "Barres de vie des ennemis", "enemy_bars")
	_check_row(g, "Dégâts infligés (coin de l'écran)", "damage_numbers")
	_check_row(g, "Mini-carte", "minimap")
	_check_row(g, "Annonces d'attaque ennemies (!)", "telegraphs")
	_check_row(g, "Arène des Ombres au Sanctuaire (duel à deux)", "arena_mode")
	if not OS.has_feature("web"):
		_check_row(g, "Mises à jour automatiques", "auto_update")
	_section(g, "Accessibilité")
	_check_row(g, "Dangers très contrastés (daltonisme)", "colorblind")
	_check_row(g, "Accroupi : appuyer pour basculer", "crouch_toggle")
	_choice_row(g, "Vitesse du jeu", "game_speed", Settings.SPEED_LABELS)
	_section(g, "Manette")
	_choice_row(g, "Noms des boutons", "pad_style", Settings.PAD_STYLE_LABELS)
	_section(g, "Sensations")
	_slider_row(g, "Secousses de l'écran", "shake", 0.0, 1.5, 0.05, true)
	_check_row(g, "Arrêt sur image aux impacts", "hitstop")
	var lv := Label.new()
	lv.text = "Vibrations de la manette"
	g.add_child(lv)
	vib_check = CheckButton.new()
	vib_check.toggled.connect(_on_vib_toggled)
	g.add_child(vib_check)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	var bd := _button("Options par défaut", _on_options_defaults)
	bd.custom_minimum_size = Vector2(240, 40)
	row.add_child(bd)
	var br := _button("Retour", _back_to_pause)
	br.custom_minimum_size = Vector2(160, 40)
	row.add_child(br)
	v.add_child(row)

func _section(g: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.78))
	l.add_theme_font_size_override("font_size", 16)
	g.add_child(l)
	g.add_child(Control.new())

func _slider_row(g: GridContainer, text: String, key: String, mn: float, mx: float, step: float, pct: bool) -> void:
	var l := Label.new()
	l.text = text
	g.add_child(l)
	var h := HBoxContainer.new()
	var sl := HSlider.new()
	sl.min_value = mn
	sl.max_value = mx
	sl.step = step
	sl.custom_minimum_size = Vector2(260, 28)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var vl := Label.new()
	vl.custom_minimum_size = Vector2(70, 0)
	sl.set_meta("value_label", vl)
	sl.set_meta("pct", pct)
	sl.value = float(Settings.get(key))
	_update_slider_label(sl)
	sl.value_changed.connect(_on_slider.bind(key, sl))
	h.add_child(sl)
	h.add_child(vl)
	g.add_child(h)
	option_widgets[key] = sl
	if first_option == null:
		first_option = sl

func _choice_row(g: GridContainer, text: String, key: String, labels: Array) -> void:
	var l := Label.new()
	l.text = text
	g.add_child(l)
	var o := OptionButton.new()
	for t in labels:
		o.add_item(t)
	o.selected = int(Settings.get(key))
	o.item_selected.connect(_on_choice.bind(key))
	g.add_child(o)
	option_widgets[key] = o

func _on_choice(index: int, key: String) -> void:
	Settings.set_value(key, index)
	_refresh()
	if key == "language":
		_update_info()
		if main and main.hud:
			main.hud.queue_redraw()

func _check_row(g: GridContainer, text: String, key: String) -> void:
	var l := Label.new()
	l.text = text
	g.add_child(l)
	var c := CheckButton.new()
	c.button_pressed = bool(Settings.get(key))
	c.toggled.connect(_on_check.bind(key))
	g.add_child(c)
	option_widgets[key] = c

func _update_slider_label(sl: HSlider) -> void:
	var vl: Label = sl.get_meta("value_label")
	if sl.get_meta("pct"):
		vl.text = "%d %%" % roundi(sl.value * 100.0)
	else:
		vl.text = "×%.2f" % sl.value

func _on_slider(value: float, key: String, sl: HSlider) -> void:
	_update_slider_label(sl)
	Settings.set_value(key, value)
	if key == "sfx_volume" or key == "master_volume":
		Audio.sfx("hit", 0.0)

func _on_check(on: bool, key: String) -> void:
	Settings.set_value(key, on)
	if key == "arena_mode" and main and main.has_method("refresh_arena"):
		main.refresh_arena()

func _on_options_defaults() -> void:
	Settings.reset_defaults()
	_sync_options()

func _sync_options() -> void:
	for key in option_widgets:
		var w = option_widgets[key]
		if w is HSlider:
			w.set_value_no_signal(float(Settings.get(key)))
			_update_slider_label(w)
		elif w is OptionButton:
			w.selected = int(Settings.get(key))
		else:
			w.set_pressed_no_signal(bool(Settings.get(key)))
	vib_check.set_pressed_no_signal(Controls.vibration)

func _open_options() -> void:
	_go(options_panel)
	_sync_options()
	first_option.grab_focus()

# Taille des menus : chaque panneau est agrandi/réduit autour de son centre
func _apply_scale() -> void:
	var s: float = Settings.menu_scale
	for p in _panels():
		if p:
			p.pivot_offset = p.size / 2.0 if p != title_panel else Vector2(0, p.size.y / 2.0)
			p.scale = Vector2(s, s)

func _on_vib_toggled(on: bool) -> void:
	Controls.vibration = on
	Controls.save_settings()
	if on:
		Controls.rumble(0.5, 0.5, 0.2)

func _on_defaults() -> void:
	Controls.reset_defaults()
	status.text = "Touches par défaut rétablies."

# ---------------------------------------------------------------- ouverture / fermeture
func _show(on: bool) -> void:
	visible = on
	dim.visible = on
	_go(pause_panel if on else null)

func open() -> void:
	_update_info()
	_show(true)
	Engine.time_scale = Settings.speed()
	get_tree().paused = true
	first_pause_button.grab_focus()

func close() -> void:
	_cancel_wait()
	_show(false)
	get_tree().paused = false

func _open_controls() -> void:
	_go(controls_panel)
	status.text = "Choisis une case puis appuie sur la nouvelle touche (clavier ou souris). Suppr : effacer."
	_refresh()
	cells["%s:0" % Controls.ACTIONS[0]].grab_focus()

func _back_to_pause() -> void:
	_cancel_wait()
	_go(home_panel)
	(first_title_button if title_mode else first_pause_button).grab_focus()

func _restart() -> void:
	GameState.restart_level()

# ---------------------------------------------------------------- affichage
func _refresh() -> void:
	if grid == null:
		return
	for a in Controls.ACTIONS:
		for slot in 3:
			var b = cells["%s:%d" % [a, slot]]
			b.glyph = {}
			b.caption = ""
			if a == waiting_action and slot == waiting_slot:
				b.text = "…"
			elif slot < 2:
				var k: int = Controls.keys[a][slot]
				b.text = "—" if k == KEY_NONE else ""
				if k != KEY_NONE:
					b.glyph = {"key": k}
			else:
				var pd: Dictionary = Controls.pad[a]
				b.text = "—" if pd.is_empty() else ""
				if not pd.is_empty():
					b.glyph = {"pad": pd}
					b.caption = Controls.pad_name(pd)
			b.queue_redraw()
	pad_info.text = Controls.pad_description()
	if pad_header:
		pad_header.text = "PlayStation" if Controls.pad_style() == "ps" else "Manette Xbox"
	vib_check.set_pressed_no_signal(Controls.vibration)

func _on_joy_changed(device: int, connected: bool) -> void:
	_refresh()
	if main:
		var n := Input.get_joy_name(device)
		main.show_message((tr("Manette connectée : ") + n) if connected else "Manette déconnectée", 2.5)
		if connected:
			Controls.rumble(0.4, 0.4, 0.25)

# ---------------------------------------------------------------- capture d'une touche
func _start_wait(action: String, slot: int) -> void:
	waiting_action = action
	waiting_slot = slot
	wait_t = 0.15   # ignore la pression qui a validé le bouton
	status.text = tr("Appuie sur un bouton de la manette…" if slot == 2 else "Appuie sur une touche ou clique avec un bouton de la souris…") + tr("  (Échap ou Menu/Options : annuler)")
	_refresh()

func _cancel_wait() -> void:
	waiting_action = ""
	waiting_slot = -1
	if grid:
		_refresh()

func _cell_gui_input(event: InputEvent, action: String, slot: int) -> void:
	# Suppr / Retour arrière sur une case clavier : l'effacer
	if waiting_action == "" and slot < 2 and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			Controls.clear_key(action, slot)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	wait_t = maxf(wait_t - delta, 0.0)
	_process_title_intro(delta)

func _input(event: InputEvent) -> void:
	if waiting_action != "":
		if wait_t > 0.0:
			if not (event is InputEventMouseMotion):
				get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode == KEY_ESCAPE:
				status.text = "Annulé."
			elif waiting_slot < 2:
				Controls.rebind_key(waiting_action, waiting_slot, event.physical_keycode)
				status.text = "%s → %s" % [tr(Controls.LABELS[waiting_action]), Controls.key_name(event.physical_keycode)]
			else:
				status.text = "Utilise la manette pour cette case (Échap : annuler)."
				get_viewport().set_input_as_handled()
				return
			_finish_wait()
		elif event is InputEventMouseButton and event.pressed and waiting_slot < 2:
			var code: int = Controls.mouse_code(event)
			if code != 0:
				Controls.rebind_key(waiting_action, waiting_slot, code)
				status.text = "%s → %s" % [tr(Controls.LABELS[waiting_action]), Controls.key_name(code)]
				_finish_wait()
		elif waiting_slot == 2 and (event is InputEventJoypadButton or event is InputEventJoypadMotion):
			if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
				status.text = "Annulé."
				_finish_wait()
				return
			var d: Dictionary = Controls.event_to_pad(event)
			if not d.is_empty():
				Controls.rebind_pad(waiting_action, d)
				Controls.rumble(0.3, 0.0, 0.1)
				status.text = "%s → %s" % [tr(Controls.LABELS[waiting_action]), Controls.pad_name(d)]
				_finish_wait()
		if not (event is InputEventMouseMotion):
			get_viewport().set_input_as_handled()
		return
	# B à la manette : retour (comme Échap), uniquement quand le menu est ouvert
	if visible and event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		if not _holder(home_panel).visible:
			_back_to_pause()
		elif not title_mode and not game_over:
			close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause_menu"):
		if not visible:
			if main and main.inventory and main.inventory.visible:
				return
			open()
		elif not _holder(home_panel).visible:
			_back_to_pause()
		elif not title_mode and not game_over:
			close()
		get_viewport().set_input_as_handled()

func _finish_wait() -> void:
	var a := waiting_action
	var s := waiting_slot
	waiting_action = ""
	waiting_slot = -1
	wait_t = 0.2
	_refresh()
	var b: Button = cells.get("%s:%d" % [a, s])
	if b:
		b.grab_focus()
	get_viewport().set_input_as_handled()

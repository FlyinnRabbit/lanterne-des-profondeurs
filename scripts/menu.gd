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
var title_mode := false
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
var ach_panel: PanelContainer
var ach_list: VBoxContainer
var ach_back: Button
var route: Label
var save_label: Label

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
	_build_pause(root)
	_build_controls(root)
	_build_options(root)
	_build_title(root)
	_build_difficulty(root)
	_build_achievements(root)
	home_panel = pause_panel
	for p in _panels():
		p.resized.connect(_apply_scale)
	Settings.changed.connect(_apply_scale)
	_show(false)
	Controls.bindings_changed.connect(_refresh)
	Controls.device_changed.connect(func(_p): _refresh())
	Input.joy_connection_changed.connect(_on_joy_changed)

func _panels() -> Array:
	return [pause_panel, controls_panel, options_panel, title_panel, diff_panel, ach_panel]

# Affiche un seul panneau
func _go(panel: PanelContainer) -> void:
	for p in _panels():
		if p:
			p.get_parent().visible = (p == panel)
	_apply_scale()

# ---------------------------------------------------------------- écran titre et difficulté
func _build_title(root: Control) -> void:
	title_panel = _centered_panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	title_panel.add_child(v)
	var logo := TextureRect.new()
	logo.texture = load("res://art/lantern_logo.png")
	logo.custom_minimum_size = Vector2(150, 150)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(logo)
	var t := _title("Lanterne des Profondeurs")
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", Color(1.0, 0.88, 0.6))
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Un metroidvania aux profondeurs changeantes"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	v.add_child(sub)
	v.add_child(Control.new())
	if GameState.has_save():
		first_title_button = _button("Continuer", func(): GameState.continue_game())
		v.add_child(first_title_button)
		var sv := Label.new()
		save_label = sv
		sv.text = GameState.save_summary()
		sv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sv.add_theme_font_size_override("font_size", 14)
		sv.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
		v.add_child(sv)
		v.add_child(_button("Nouvelle partie", func(): _open_difficulty()))
	else:
		first_title_button = _button("Jouer", func(): _open_difficulty())
		v.add_child(first_title_button)
	v.add_child(_button("Commandes", _open_controls))
	v.add_child(_button("Options", _open_options))
	v.add_child(_button("Succès", _open_achievements))
	v.add_child(_button("Quitter le jeu", func(): get_tree().quit()))

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
	if GameState.has_save():
		var warn := Label.new()
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
	skip_tuto_check = CheckButton.new()
	skip_tuto_check.text = "Passer le tutoriel"
	v.add_child(skip_tuto_check)
	var br := _button("Retour", _back_to_pause)
	br.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(br)
	v.add_child(row)
	diff_back_row = row

func _open_difficulty() -> void:
	_go(diff_panel)
	diff_buttons[GameState.difficulty].grab_focus()

func _start_game(diff: int) -> void:
	GameState.new_game(skip_tuto_check.button_pressed, diff)

# Mort définitive : récapitulatif de la partie puis choix d'une nouvelle partie
func open_game_over(summary: String) -> void:
	game_over = true
	home_panel = diff_panel
	visible = true
	dim.visible = true
	dim.color = Color(0.05, 0.0, 0.02, 0.86)
	diff_header.text = summary
	diff_header.visible = true
	diff_back_row.visible = false
	skip_tuto_check.button_pressed = true
	_go(diff_panel)
	get_tree().paused = true
	diff_buttons[GameState.difficulty].grab_focus()

# Écran titre au lancement : le jeu reste en pause derrière
func open_title() -> void:
	title_mode = true
	home_panel = title_panel
	visible = true
	dim.visible = true
	dim.color = Color(0.0, 0.0, 0.03, 0.82)
	_go(title_panel)
	get_tree().paused = true
	first_title_button.grab_focus()
	Audio.play_boss("res://music/sanctuaire.ogg")

# ---------------------------------------------------------------- construction
func _make_theme() -> Theme:
	var th := Theme.new()
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.05, 0.06, 0.1, 0.96)
	panel.border_color = Color(0.45, 0.55, 0.7)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(20)
	th.set_stylebox("panel", "PanelContainer", panel)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.1, 0.12, 0.18)
	normal.border_color = Color(0.25, 0.3, 0.42)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.16, 0.2, 0.3)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color(0.2, 0.26, 0.4)
	focus.border_color = Color(0.85, 0.9, 1.0)
	focus.set_border_width_all(2)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.3, 0.38, 0.55)
	for t in ["Button", "CheckButton"]:
		th.set_stylebox("normal", t, normal)
		th.set_stylebox("hover", t, hover)
		th.set_stylebox("focus", t, focus)
		th.set_stylebox("pressed", t, pressed)
		th.set_font_size("font_size", t, 18)
		th.set_color("font_color", t, Color(0.88, 0.91, 1.0))
	th.set_font_size("font_size", "Label", 20)
	th.set_color("font_color", "Label", Color(0.8, 0.85, 0.95))
	return th

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
	v.add_child(_button("Nouvelle partie…", _open_difficulty))
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
		save_label.text = GameState.save_summary()

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
	_check_row(g, "Afficher les FPS", "show_fps")
	_check_row(g, "Barres de vie des ennemis", "enemy_bars")
	_check_row(g, "Dégâts infligés (coin de l'écran)", "damage_numbers")
	_check_row(g, "Mini-carte", "minimap")
	_check_row(g, "Annonces d'attaque ennemies (!)", "telegraphs")
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
			p.pivot_offset = p.size / 2.0
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
		if not home_panel.get_parent().visible:
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
		elif not home_panel.get_parent().visible:
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

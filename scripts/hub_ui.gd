extends CanvasLayer
# Interfaces du hub : boutique du marchand et ascenseur (choix du palier).

var main
var dim: ColorRect
var shop_panel: PanelContainer
var lift_panel: PanelContainer
var shop_list: VBoxContainer
var shop_geo: Label
var shop_desc: Label
var shop_status: Label
var lift_list: VBoxContainer
var lift_info: Label
var ars_panel: PanelContainer
var ars_list: VBoxContainer
var ars_geo: Label
var ars_desc: Label
var ars_status: Label
const Weapons = preload("res://scripts/weapons.gd")

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = main.menu._make_theme()
	add_child(root)
	dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.03, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_build_shop(root)
	_build_lift(root)
	_build_arsenal(root)
	for p in [shop_panel, lift_panel, ars_panel]:
		p.resized.connect(_apply_scale)
	Settings.changed.connect(_apply_scale)
	visible = false

func _panel(root: Control) -> PanelContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(c)
	var p := PanelContainer.new()
	c.add_child(p)
	return p

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _apply_scale() -> void:
	var s: float = Settings.menu_scale
	for p in [shop_panel, lift_panel, ars_panel]:
		p.pivot_offset = p.size / 2.0
		p.scale = Vector2(s, s)

# ---------------------------------------------------------------- boutique
func _build_shop(root: Control) -> void:
	shop_panel = _panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	shop_panel.add_child(v)
	v.add_child(_label("Le marchand", 32, Color(1.0, 0.88, 0.6)))
	v.add_child(_label("« Des éclats contre des merveilles, petit veilleur. »", 15, Color(0.65, 0.7, 0.82)))
	shop_geo = _label("", 20, Color(0.8, 0.9, 1.0))
	v.add_child(shop_geo)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	v.add_child(scroll)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 6)
	scroll.add_child(shop_list)
	shop_desc = _label("", 16, Color(0.8, 0.82, 0.9))
	shop_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_desc.custom_minimum_size = Vector2(620, 44)
	v.add_child(shop_desc)
	shop_status = _label("", 16, Color(1.0, 0.85, 0.55))
	v.add_child(shop_status)
	var close: Button = main.menu._button("Fermer", close_all)
	close.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(close)
	v.add_child(row)

func _shop_items() -> Array:
	var items := []
	items.append({"kind": "hp", "id": 0, "name": "Fragment de vie (%d / %d)" % [GameState.max_hp_bonus(), GameState.MAX_BONUS_HP],
		"price": GameState.hp_price(), "desc": "Ajoute un fragment de vie maximum, pour toujours.",
		"sold_out": GameState.max_hp_bonus() >= GameState.MAX_BONUS_HP})
	items.append({"kind": "notch", "id": 0, "name": "Encoche d'emblème (vous en avez %d)" % int(GameState.prog["notches"]),
		"price": GameState.notch_price(), "desc": "Permet d'équiper davantage d'emblèmes.", "sold_out": false})
	for id in GameState.charm_count():
		if not GameState.owns(id):
			var c: Dictionary = GameState.charm(id)
			items.append({"kind": "charm", "id": id, "name": "Emblème : %s (coût %d encoche%s)" % [c["name"], c["cost"], "s" if c["cost"] > 1 else ""],
				"price": GameState.charm_price(id), "desc": c["desc"], "sold_out": false})
	return items

func _refresh_shop() -> void:
	for ch in shop_list.get_children():
		ch.queue_free()
	shop_geo.text = "Éclats : %d" % main.player.geo
	var first: Button = null
	for it in _shop_items():
		var b := Button.new()
		b.text = ("%s — VENDU" % it["name"]) if it["sold_out"] else ("%s — %d éclats" % [it["name"], it["price"]])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(600, 38)
		b.disabled = it["sold_out"]
		if not it["sold_out"] and main.player.geo < int(it["price"]):
			b.add_theme_color_override("font_color", Color(0.6, 0.55, 0.55))
		b.pressed.connect(_buy.bind(it["kind"], it["id"]))
		b.focus_entered.connect(func(): shop_desc.text = it["desc"])
		b.mouse_entered.connect(func(): shop_desc.text = it["desc"])
		shop_list.add_child(b)
		if first == null and not it["sold_out"]:
			first = b
	if first:
		first.grab_focus()

func _buy(kind: String, id: int) -> void:
	var err: String = GameState.buy(kind, id, main.player)
	if err != "":
		shop_status.text = err
		return
	Audio.sfx("pickup", 0.0)
	Controls.rumble(0.3, 0.0, 0.1)
	shop_status.text = "Merci, petit veilleur."
	if kind == "charm":
		shop_status.text = "Emblème acheté ! Équipe-le au banc depuis l'inventaire."
	_refresh_shop()

func open_shop() -> void:
	shop_status.text = ""
	shop_desc.text = ""
	_open(shop_panel)
	_refresh_shop()

# ---------------------------------------------------------------- ascenseur
func _build_lift(root: Control) -> void:
	lift_panel = _panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	lift_panel.add_child(v)
	v.add_child(_label("Ascenseur", 32, Color(0.7, 0.88, 1.0)))
	lift_info = _label("", 16, Color(0.65, 0.7, 0.82))
	lift_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lift_info.custom_minimum_size = Vector2(560, 0)
	v.add_child(lift_info)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	v.add_child(scroll)
	lift_list = VBoxContainer.new()
	lift_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lift_list.add_theme_constant_override("separation", 6)
	scroll.add_child(lift_list)
	var close: Button = main.menu._button("Rester au Sanctuaire", close_all)
	close.custom_minimum_size = Vector2(280, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(close)
	v.add_child(row)

func open_elevator() -> void:
	_open(lift_panel)
	for ch in lift_list.get_children():
		ch.queue_free()
	lift_info.text = "Difficulté : %s — record : palier %d.\nChaque palier : 2 niveaux puis un boss. Plus on descend, plus les ennemis sont coriaces.\nMourir ramène ici et fait perdre le butin de la descente." % [GameState.diff_name(), GameState.record]
	var last: Button = null
	for p in range(GameState.unlocked, 0, -1):
		var boss: String = GameState.boss_name_for(p)
		var b := Button.new()
		b.text = "Palier %d — boss : %s%s" % [p, boss, "  (nouveau !)" if p > GameState.record else ""]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(540, 40)
		b.pressed.connect(_descend.bind(p))
		lift_list.add_child(b)
		if last == null:
			last = b
	last.grab_focus()

func _descend(p: int) -> void:
	Audio.sfx("door", 0.0)
	GameState.start_descent(p, main.player)

# ---------------------------------------------------------------- arsenal
func _build_arsenal(root: Control) -> void:
	ars_panel = _panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	ars_panel.add_child(v)
	v.add_child(_label("L'arsenal", 32, Color(1.0, 0.75, 0.45)))
	v.add_child(_label("Choisis l'arme de base de ta descente.", 15, Color(0.65, 0.7, 0.82)))
	ars_geo = _label("", 20, Color(0.8, 0.9, 1.0))
	v.add_child(ars_geo)
	ars_list = VBoxContainer.new()
	ars_list.add_theme_constant_override("separation", 6)
	v.add_child(ars_list)
	ars_desc = _label("", 16, Color(0.8, 0.82, 0.9))
	ars_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ars_desc.custom_minimum_size = Vector2(620, 66)
	v.add_child(ars_desc)
	ars_status = _label("", 16, Color(1.0, 0.85, 0.55))
	v.add_child(ars_status)
	var close: Button = main.menu._button("Fermer", close_all)
	close.custom_minimum_size = Vector2(200, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(close)
	v.add_child(row)

func open_arsenal() -> void:
	ars_status.text = ""
	ars_desc.text = ""
	_open(ars_panel)
	_refresh_arsenal()

func _refresh_arsenal(focus_id: String = "") -> void:
	for ch in ars_list.get_children():
		ars_list.remove_child(ch)
		ch.queue_free()
	ars_geo.text = "Éclats : %d" % main.player.geo
	var cur: String = GameState.weapon()
	var to_focus: Button = null
	for id in Weapons.ORDER:
		var w: Dictionary = Weapons.W[id]
		var b := Button.new()
		var state := ""
		if id == cur:
			state = "ÉQUIPÉE"
		elif GameState.owns_weapon(id):
			state = "équiper"
		else:
			state = "%d éclats" % int(w["price"])
		b.text = "%s — %s" % [w["name"], state]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(600, 40)
		b.add_theme_color_override("font_color", w["color"] if id != cur else Color(1.0, 0.9, 0.55))
		if not GameState.owns_weapon(id) and main.player.geo < int(w["price"]):
			b.add_theme_color_override("font_color", Color(0.6, 0.55, 0.55))
		b.pressed.connect(_pick_weapon.bind(id))
		b.focus_entered.connect(func(): ars_desc.text = w["desc"])
		b.mouse_entered.connect(func(): ars_desc.text = w["desc"])
		ars_list.add_child(b)
		if (focus_id == "" and id == cur) or id == focus_id:
			to_focus = b
	if to_focus:
		to_focus.grab_focus()

func _pick_weapon(id: String) -> void:
	if GameState.owns_weapon(id):
		GameState.equip_weapon(id)
		ars_status.text = "%s équipée." % Weapons.W[id]["name"]
		Audio.sfx("pickup", 0.0, -3.0)
	else:
		var err: String = GameState.buy_weapon(id, main.player)
		if err != "":
			ars_status.text = err
			return
		Audio.sfx("pickup", 0.0)
		Controls.rumble(0.3, 0.0, 0.1)
		ars_status.text = "%s achetée et équipée !" % Weapons.W[id]["name"]
	_refresh_arsenal(id)

# ---------------------------------------------------------------- commun
func _open(panel: PanelContainer) -> void:
	visible = true
	shop_panel.get_parent().visible = panel == shop_panel
	lift_panel.get_parent().visible = panel == lift_panel
	ars_panel.get_parent().visible = panel == ars_panel
	_apply_scale()
	get_tree().paused = true

func close_all() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("inventory") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		close_all()
		get_viewport().set_input_as_handled()

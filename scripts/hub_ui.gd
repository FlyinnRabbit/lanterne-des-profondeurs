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
var npc_panel: PanelContainer
var npc_name: Label
var npc_text: Label
var npc_buttons: VBoxContainer
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
	_build_npc(root)
	for p in [shop_panel, lift_panel, ars_panel, npc_panel]:
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
	for p in [shop_panel, lift_panel, ars_panel, npc_panel]:
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
	items.append({"kind": "hp", "id": 0, "name": tr("Fragment de vie (%d / %d)") % [GameState.max_hp_bonus(), GameState.MAX_BONUS_HP],
		"price": GameState.hp_price(), "desc": "Ajoute un fragment de vie maximum, pour toujours.",
		"sold_out": GameState.max_hp_bonus() >= GameState.MAX_BONUS_HP})
	items.append({"kind": "notch", "id": 0, "name": tr("Encoche d'emblème (vous en avez %d)") % int(GameState.prog["notches"]),
		"price": GameState.notch_price(), "desc": "Permet d'équiper davantage d'emblèmes.", "sold_out": false})
	for id in GameState.charm_count():
		if not GameState.owns(id):
			var c: Dictionary = GameState.charm(id)
			items.append({"kind": "charm", "id": id, "name": tr("Emblème : %s (coût %d encoches)" if c["cost"] > 1 else "Emblème : %s (coût %d encoche)") % [tr(c["name"]), c["cost"]],
				"price": GameState.charm_price(id), "desc": c["desc"], "sold_out": false})
	return items

func _refresh_shop() -> void:
	for ch in shop_list.get_children():
		ch.queue_free()
	shop_geo.text = tr("Éclats : %d") % main.player.geo
	var first: Button = null
	for it in _shop_items():
		var b := Button.new()
		b.text = (tr("%s — VENDU") % it["name"]) if it["sold_out"] else (tr("%s — %d éclats") % [it["name"], it["price"]])
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
	_clear(lift_list)
	lift_info.text = tr("Difficulté : %s — record : palier %d.\nChaque palier : 2 niveaux puis un boss. Plus on descend, plus les ennemis sont coriaces.\nMourir ramène ici et fait perdre le butin de la descente.") % [GameState.diff_name(), GameState.record]
	var first: Button = null
	for p in range(GameState.unlocked, 0, -1):
		var boss: String = GameState.boss_name_for(p)
		var b := _lift_button(tr("Palier %d — boss : %s%s") % [p, boss, tr("  (nouveau !)") if p > GameState.record else ""], _choose_curse.bind(p))
		if first == null:
			first = b
	# modes spéciaux
	var dkey := "daily_%d" % GameState.today_seed()
	var dbest := float(Achievements.counters.get(dkey, 0.0))
	var dl := tr("Descente du jour (même niveau pour tous, aujourd'hui)") + " " + tr("— butin non conservé")
	if dbest > 0.0:
		dl += "  — " + tr("meilleur : %d:%02d") % [int(dbest) / 60, int(dbest) % 60]
	var db := _lift_button(dl, _daily)
	db.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	if GameState.record >= 6:
		var rbest := float(Achievements.counters.get("rush_best", 0.0))
		var rl := tr("Défi des boss : les %d boss à la suite") % GameState.RUSH_ORDER.size()
		if rbest > 0.0:
			rl += "  — " + tr("meilleur : %d:%02d") % [int(rbest) / 60, int(rbest) % 60]
		var rb := _lift_button(rl, _rush)
		rb.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
	else:
		var lk := _lift_button(tr("Défi des boss : termine le palier 6 pour le débloquer"), func(): pass)
		lk.disabled = true
	first.grab_focus()

func _clear(box: Control) -> void:
	for ch in box.get_children():
		box.remove_child(ch)
		ch.queue_free()

func _lift_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(540, 40)
	b.pressed.connect(cb)
	lift_list.add_child(b)
	return b

# Deuxième étape : malédiction facultative (plus d'éclats)
func _choose_curse(p: int) -> void:
	_clear(lift_list)
	lift_info.text = tr("Palier %d : choisis une malédiction (facultatif). Plus de risques, plus d'éclats.") % p
	var first: Button = null
	for id in GameState.CURSES:
		var c: Dictionary = GameState.CURSES[id]
		var b := _lift_button("%s — %s" % [tr(c["name"]), tr(c["desc"])], _descend.bind(p, id))
		if id != "":
			b.add_theme_color_override("font_color", Color(1.0, 0.6, 0.55))
		if first == null:
			first = b
	_lift_button(tr("Retour"), open_elevator)
	first.grab_focus()

func _descend(p: int, curse_id := "") -> void:
	Audio.sfx("door", 0.0)
	GameState.start_descent(p, main.player, curse_id)

func _daily() -> void:
	Audio.sfx("door", 0.0)
	GameState.start_daily(main.player)

func _rush() -> void:
	Audio.sfx("door", 0.0)
	GameState.start_rush(main.player)

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
	ars_geo.text = tr("Éclats : %d") % main.player.geo
	var cur: String = GameState.weapon()
	var to_focus: Button = null
	var forge: bool = GameState.record >= 1
	for id in Weapons.ORDER:
		var w: Dictionary = Weapons.W[id]
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		var b := Button.new()
		var state := ""
		if id == cur:
			state = tr("ÉQUIPÉE")
		elif GameState.owns_weapon(id):
			state = tr("équiper")
		else:
			state = tr("%d éclats") % int(w["price"])
		var lvl: int = GameState.weapon_level(id)
		b.text = "%s%s — %s" % [tr(w["name"]), (" " + tr("niv. 2")) if lvl >= 2 else "", state]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(430, 40)
		b.add_theme_color_override("font_color", w["color"] if id != cur else Color(1.0, 0.9, 0.55))
		if not GameState.owns_weapon(id) and main.player.geo < int(w["price"]):
			b.add_theme_color_override("font_color", Color(0.6, 0.55, 0.55))
		b.pressed.connect(_pick_weapon.bind(id))
		var full := func() -> String:
			return tr(w["desc"]) + "\n" + tr(Weapons.UP[id]["desc"]) + ("" if lvl >= 2 else (" " + tr("(forgeronne : palier 1 terminé)") if not forge else ""))
		b.focus_entered.connect(func(): ars_desc.text = full.call())
		b.mouse_entered.connect(func(): ars_desc.text = full.call())
		line.add_child(b)
		# Essayer : arme prêtée le temps de rester au Sanctuaire (mannequin à droite)
		var tb := Button.new()
		tb.text = "Essayer" if GameState.trial_weapon != id else "Essai…"
		tb.custom_minimum_size = Vector2(80, 40)
		tb.disabled = GameState.owns_weapon(id)
		tb.pressed.connect(_try_weapon.bind(id))
		tb.focus_entered.connect(func(): ars_desc.text = full.call())
		line.add_child(tb)
		# Améliorer (forgeronne)
		var ub := Button.new()
		ub.text = tr("Niv. 2 ✓") if lvl >= 2 else tr("Améliorer — %d") % int(Weapons.UP[id]["price"])
		ub.custom_minimum_size = Vector2(150, 40)
		ub.disabled = lvl >= 2 or not forge or not GameState.owns_weapon(id)
		ub.pressed.connect(_upgrade_weapon.bind(id))
		ub.focus_entered.connect(func(): ars_desc.text = full.call())
		line.add_child(ub)
		ars_list.add_child(line)
		if (focus_id == "" and id == cur) or id == focus_id:
			to_focus = b
	if to_focus:
		to_focus.grab_focus()

func _try_weapon(id: String) -> void:
	GameState.trial_weapon = "" if GameState.trial_weapon == id else id
	ars_status.text = (tr("Essai : %s. Frappe le mannequin à droite pour voir ses dégâts.") % tr(Weapons.W[id]["name"])) if GameState.trial_weapon != "" else "Essai terminé."
	_refresh_arsenal(id)

func _upgrade_weapon(id: String) -> void:
	var err: String = GameState.upgrade_weapon(id, main.player)
	if err != "":
		ars_status.text = err
		return
	Audio.sfx("pickup", 0.0, 3.0)
	Controls.rumble(0.4, 0.2, 0.15)
	ars_status.text = tr("%s améliorée : niveau 2 !") % tr(Weapons.W[id]["name"])
	_refresh_arsenal(id)

func _pick_weapon(id: String) -> void:
	GameState.trial_weapon = ""
	if GameState.owns_weapon(id):
		GameState.equip_weapon(id)
		ars_status.text = tr("%s équipée.") % tr(Weapons.W[id]["name"])
		Audio.sfx("pickup", 0.0, -3.0)
	else:
		var err: String = GameState.buy_weapon(id, main.player)
		if err != "":
			ars_status.text = err
			return
		Audio.sfx("pickup", 0.0)
		Controls.rumble(0.3, 0.0, 0.1)
		ars_status.text = tr("%s achetée et équipée !") % tr(Weapons.W[id]["name"])
	_refresh_arsenal(id)

# ---------------------------------------------------------------- habitants du Sanctuaire
const ELDER_LINES := [
	"Autrefois, la Lanterne des Profondeurs éclairait chaque palier jusqu'au fond du monde.",
	"Le Gardien du Puits fut le premier à veiller sur sa flamme. Il ne sait plus pourquoi il garde.",
	"L'Abbesse priait pour la lumière. L'eau est montée, et ses prières se sont noyées.",
	"La Reine Essaim a cru que la flamme était une fleur. Son peuple bourdonne encore autour du vide.",
	"Le Colosse est fait des os de ceux qui sont descendus avant toi. Ne lui en donne pas d'autres.",
	"Le Ver creuse là où la lumière ne va plus. Il a mangé le chemin du retour.",
	"Le Chevalier a juré de rallumer la Lanterne. Il a oublié son serment, pas son épée.",
	"Au septième palier, la Lanterne elle-même t'attend. Son ombre a pris sa place. Rallume-la, petit veilleur.",
]

func _build_npc(root: Control) -> void:
	npc_panel = _panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	npc_panel.add_child(v)
	npc_name = _label("", 30, Color(1.0, 0.85, 0.6))
	v.add_child(npc_name)
	npc_text = _label("", 17, Color(0.85, 0.87, 0.95))
	npc_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	npc_text.custom_minimum_size = Vector2(600, 90)
	v.add_child(npc_text)
	npc_buttons = VBoxContainer.new()
	npc_buttons.add_theme_constant_override("separation", 6)
	v.add_child(npc_buttons)

func _npc_button(text: String, cb: Callable) -> Button:
	var b: Button = main.menu._button(text, cb)
	b.custom_minimum_size = Vector2(560, 40)
	npc_buttons.add_child(b)
	return b

func open_npc(kind: String) -> void:
	_open(npc_panel)
	_clear(npc_buttons)
	var first: Button = null
	match kind:
		"smith":
			npc_name.text = "La forgeronne"
			npc_text.text = "« Tu reviens vivant du premier palier ? Alors tes armes méritent mieux. Je les forge au niveau 2 : passe par l'arsenal. »"
			first = _npc_button("Voir les améliorations (arsenal)", open_arsenal)
		"cartographer":
			npc_name.text = "Le cartographe"
			if GameState.prog.get("map_full", false):
				npc_text.text = "« Ma plume trace déjà tout pour toi. Ouvre ta carte en descente : chaque recoin y est. »"
			else:
				npc_text.text = tr("« Je dessine les paliers avant que tu y poses le pied. Ma plume : %d éclats, et ta carte montrera tout le niveau dès l'arrivée. »") % CARTO_PRICE
				first = _npc_button(tr("Acheter la Plume du cartographe — %d éclats") % CARTO_PRICE, _buy_map)
		"elder":
			npc_name.text = "L'ancien"
			var lines := []
			for i in mini(GameState.record + 1, ELDER_LINES.size()):
				lines.append(tr(ELDER_LINES[i]))
			npc_text.text = "\n\n".join(lines.slice(maxi(lines.size() - 3, 0)))
	var close := _npc_button("Fermer", close_all)
	if first == null:
		first = close
	first.grab_focus()

const CARTO_PRICE := 180

func _buy_map() -> void:
	if main.player.geo < CARTO_PRICE:
		npc_text.text = tr("Pas assez d'éclats (%d nécessaires).") % CARTO_PRICE
		return
	main.player.geo -= CARTO_PRICE
	GameState.prog["geo"] = main.player.geo
	GameState.prog["map_full"] = true
	GameState.snapshot = GameState.prog.duplicate(true)
	GameState.save_game()
	Audio.sfx("pickup", 0.0)
	open_npc("cartographer")

# ---------------------------------------------------------------- commun
func _open(panel: PanelContainer) -> void:
	visible = true
	shop_panel.get_parent().visible = panel == shop_panel
	lift_panel.get_parent().visible = panel == lift_panel
	ars_panel.get_parent().visible = panel == ars_panel
	npc_panel.get_parent().visible = panel == npc_panel
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

extends CanvasLayer
const LoadingScript = preload("res://scripts/loading.gd")
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
var ward_panel: PanelContainer
var ward_list: VBoxContainer
var ward_geo: Label
var ward_status: Label
var ward_cat := "cape"
var ward_tabs := {}
const Weapons = preload("res://scripts/weapons.gd")
const CharmIcon = preload("res://scripts/charm_icon.gd")

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
	_build_wardrobe(root)
	for p in [shop_panel, lift_panel, ars_panel, npc_panel, ward_panel]:
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
	for p in [shop_panel, lift_panel, ars_panel, npc_panel, ward_panel]:
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
		# icône à gauche : médaillon de l'emblème, du fragment de vie ou de l'encoche
		var img := Image.create(30, 30, false, Image.FORMAT_RGBA8)
		b.icon = ImageTexture.create_from_image(img)
		var ic := Control.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.position = Vector2(4, 2)
		ic.size = Vector2(34, 34)
		var kind_s: String = it["kind"]
		var iid: int = it["id"]
		ic.draw.connect(func():
			if kind_s == "charm":
				CharmIcon.draw(ic, Vector2(17, 17), 15.0, iid, GameState.charm(iid)["color"])
			else:
				CharmIcon.draw_item(ic, Vector2(17, 17), 15.0, kind_s))
		b.add_child(ic)
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
	var cb := _lift_button(tr("Classement du jour (en ligne)"), _show_board)
	cb.add_theme_color_override("font_color", Color(0.75, 0.95, 0.85))
	if GameState.record >= 6:
		var rbest := float(Achievements.counters.get("rush_best", 0.0))
		var rl := tr("Défi des boss : les %d boss à la suite") % GameState.RUSH_ORDER.size()
		if not bool(GameState.prog.get("rush_cleared", false)):
			rl += tr(" — 1re victoire : +1 encoche")
		if rbest > 0.0:
			rl += "  — " + tr("meilleur : %d:%02d") % [int(rbest) / 60, int(rbest) % 60]
		var rb := _lift_button(rl, _rush)
		rb.add_theme_color_override("font_color", Color(1.0, 0.7, 0.5))
	else:
		var lk := _lift_button(tr("Défi des boss : termine le palier 6 pour le débloquer"), func(): pass)
		lk.disabled = true
	first.grab_focus()

# ---------------------------------------------------------------- classement du jour
var _board_status: Label
var _board_rows: VBoxContainer

static func _fmt_time(t: float) -> String:
	var cs := int(round(t * 100.0))
	return "%d:%02d.%02d" % [cs / 6000, (cs / 100) % 60, cs % 100]

func _show_board() -> void:
	_clear(lift_list)
	var seed := GameState.today_seed()
	lift_info.text = tr("Classement du jour — %s — même niveau pour tous, meilleur temps de chacun.") % GameState.diff_name()
	# pseudo
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var pl := Label.new()
	pl.text = tr("Pseudo :")
	row.add_child(pl)
	var le := LineEdit.new()
	le.text = String(Settings.player_name)
	le.placeholder_text = GameState.LeaderboardScript.player_name()
	le.max_length = 16
	le.custom_minimum_size = Vector2(260, 38)
	var save_name := func(_t = ""):
		Settings.set_value("player_name", le.text.strip_edges())
	le.text_submitted.connect(save_name)
	le.focus_exited.connect(save_name)
	row.add_child(le)
	lift_list.add_child(row)
	var on := CheckButton.new()
	on.text = tr("Envoyer mes temps au classement")
	on.button_pressed = bool(Settings.board_online)
	on.toggled.connect(func(v: bool): Settings.set_value("board_online", v))
	lift_list.add_child(on)
	_board_status = _label(tr("Chargement du classement…"), 16, Color(0.65, 0.7, 0.82))
	lift_list.add_child(_board_status)
	_board_rows = VBoxContainer.new()
	_board_rows.add_theme_constant_override("separation", 2)
	lift_list.add_child(_board_rows)
	var back := _lift_button(tr("Retour"), open_elevator)
	back.grab_focus()
	var rows_ref := _board_rows
	GameState.board.fetch_top(seed, GameState.difficulty, func(d: Dictionary):
		if not is_instance_valid(rows_ref) or not rows_ref.is_inside_tree():
			return
		_fill_board(d))

func _fill_board(d: Dictionary) -> void:
	if d.has("error"):
		_board_status.text = tr("Classement indisponible (pas de connexion ?).")
		return
	var top: Array = d.get("top", [])
	if top.is_empty():
		_board_status.text = tr("Personne n'a encore terminé la descente d'aujourd'hui dans cette difficulté.")
		return
	_board_status.text = tr("%d joueurs aujourd'hui") % int(d.get("total", top.size()))
	var you_shown := false
	for e in top:
		var you: bool = bool(e.get("you", false))
		you_shown = you_shown or you
		_board_rows.add_child(_board_line(int(e["rank"]), String(e["name"]), float(e["time"]), you))
	var me = d.get("me")
	if me is Dictionary and not you_shown:
		_board_rows.add_child(_label("…", 16, Color(0.5, 0.55, 0.65)))
		_board_rows.add_child(_board_line(int(me["rank"]), String(me["name"]), float(me["time"]), true))

func _board_line(rank: int, name: String, t: float, you: bool) -> Control:
	var h := HBoxContainer.new()
	var col := Color(1.0, 0.88, 0.5) if you else (Color(0.95, 0.8, 0.45) if rank == 1 else Color(0.82, 0.85, 0.95))
	var a := _label("%d." % rank, 18, col)
	a.custom_minimum_size = Vector2(56, 0)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(a)
	var b := _label("  " + name + (tr("  (toi)") if you else ""), 18, col)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	h.add_child(b)
	var c := _label(_fmt_time(t), 18, col)
	c.custom_minimum_size = Vector2(110, 0)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(c)
	return h

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

# L'ascenseur descend (écran animé, cliquetis de chaînes) ; le niveau se charge pendant la descente.
func _ride(to_palier: int, go: Callable) -> void:
	visible = false              # le jeu reste en pause sous l'écran de l'ascenseur
	get_tree().paused = true
	LoadingScript.lift(get_tree(), to_palier, false, go)

func _descend(p: int, curse_id := "") -> void:
	var pl = main.player
	_ride(p, func(): GameState.start_descent(p, pl, curse_id))

func _daily() -> void:
	var pl = main.player
	_ride(3, func(): GameState.start_daily(pl))

func _rush() -> void:
	var pl = main.player
	_ride(6, func(): GameState.start_rush(pl))

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
		var wimg := Image.create(30, 30, false, Image.FORMAT_RGBA8)
		b.icon = ImageTexture.create_from_image(wimg)
		var wic := Control.new()
		wic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wic.position = Vector2(4, 3)
		wic.size = Vector2(34, 34)
		var wid_s: String = id
		wic.draw.connect(func(): CharmIcon.draw_weapon(wic, Vector2(17, 17), 15.0, wid_s))
		b.add_child(wic)
		b.pressed.connect(_pick_weapon.bind(id))
		var full := func() -> String:
			return tr(w["desc"]) + "\n" + tr(Weapons.UP[id]["desc"]) + ("" if lvl >= 2 else (" " + (tr("(forgeronne : palier 1 terminé)") if not forge else tr("(à forger chez la forgeronne)"))))
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
		ars_list.add_child(line)
		if (focus_id == "" and id == cur) or id == focus_id:
			to_focus = b
	if to_focus:
		to_focus.grab_focus()

func _try_weapon(id: String) -> void:
	GameState.trial_weapon = "" if GameState.trial_weapon == id else id
	ars_status.text = (tr("Essai : %s. Frappe le mannequin à droite pour voir ses dégâts.") % tr(Weapons.W[id]["name"])) if GameState.trial_weapon != "" else "Essai terminé."
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
			npc_text.text = tr("« Tu reviens vivant du premier palier ? Alors tes armes méritent mieux. Choisis une arme : je la forge au niveau 2. »")
			for id in Weapons.ORDER:
				if not GameState.owns_weapon(id):
					continue
				var wname: String = tr(Weapons.W[id]["name"])
				var b: Button
				if GameState.weapon_level(id) >= 2:
					b = _npc_button(tr("%s — niveau 2 ✓") % wname, func(): pass)
					b.disabled = true
				else:
					b = _npc_button(tr("Améliorer : %s — %d éclats") % [wname, int(Weapons.UP[id]["price"])], _smith_upgrade.bind(id))
				var up_desc: String = tr(Weapons.UP[id]["desc"])
				b.focus_entered.connect(func(): npc_text.text = wname + " — " + up_desc)
				b.mouse_entered.connect(func(): npc_text.text = wname + " — " + up_desc)
				if first == null and not b.disabled:
					first = b
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

func _smith_upgrade(id: String) -> void:
	var err: String = GameState.upgrade_weapon(id, main.player)
	if err != "":
		npc_text.text = tr(err)
		return
	Audio.sfx("pickup", 0.0, 3.0)
	Controls.rumble(0.4, 0.2, 0.15)
	open_npc("smith")
	npc_text.text = tr("%s améliorée : niveau 2 !") % tr(Weapons.W[id]["name"])


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
	ward_panel.get_parent().visible = panel == ward_panel
	_apply_scale()
	get_tree().paused = true

func close_all() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible:
		return
	# en tapant le pseudo, seules Échap / Entrée comptent (B, P… sont des lettres)
	if get_viewport().gui_get_focus_owner() is LineEdit and event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_viewport().gui_release_focus()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("inventory") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		close_all()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- garde-robe (la tailleuse)
# Aperçu animé du héros avec les cosmétiques portés.
class HeroPreview extends Control:
	var t := 0.0
	func _process(delta: float) -> void:
		t += delta
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c + Vector2(0, 6), 78.0, Color(0.07, 0.055, 0.045))
		draw_arc(c + Vector2(0, 6), 78.0, 0.0, TAU, 48, Color(0.85, 0.7, 0.35), 2.0)
		draw_set_transform(c + Vector2(4, 62), 0.0, Vector2(3.0, 3.0))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(0, -3), Vector2(14, 0), Vector2(0, 3)]), Color(0, 0, 0, 0.45))
		GameState.cos.draw_hero(self, sin(t * 2.5) * 0.6, sin(t * 2.0) * 1.0, t, false, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

class Swatch extends Control:
	var item_id := ""
	func _draw() -> void:
		GameState.cos.draw_swatch(self, item_id, size / 2.0, 15.0)

func _build_wardrobe(root: Control) -> void:
	ward_panel = _panel(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	ward_panel.add_child(v)
	v.add_child(_label("La tailleuse", 30, Color(1.0, 0.85, 0.6)))
	var quote := _label("« Une cape, c'est une promesse. Choisis la tienne, petit veilleur. »", 14, Color(0.65, 0.7, 0.82))
	v.add_child(quote)
	ward_geo = _label("", 17, Color(0.7, 0.88, 1.0))
	v.add_child(ward_geo)
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 6)
	v.add_child(tabs)
	for cat in GameState.cos.CATS:
		var tb: Button = main.menu._button(GameState.cos.CAT_NAMES[cat], _ward_tab.bind(cat))
		tb.custom_minimum_size = Vector2(118, 36)
		tb.add_theme_font_size_override("font_size", 14)
		tabs.add_child(tb)
		ward_tabs[cat] = tb
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	v.add_child(h)
	var prev := HeroPreview.new()
	prev.custom_minimum_size = Vector2(190, 300)
	h.add_child(prev)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	h.add_child(scroll)
	ward_list = VBoxContainer.new()
	ward_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ward_list.add_theme_constant_override("separation", 5)
	scroll.add_child(ward_list)
	ward_status = _label("", 15, Color(1.0, 0.8, 0.55))
	v.add_child(ward_status)
	var close: Button = main.menu._button("Fermer", close_all)
	close.custom_minimum_size = Vector2(280, 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(close)
	v.add_child(row)

func open_wardrobe() -> void:
	var ev: String = GameState.CosmeticsScript.current_event()
	ward_status.text = tr("Les cosmétiques de fête ne se vendent que pendant leur fête.") if ev == "" else tr("C'est %s : la collection de la fête est en vente !") % tr(GameState.CosmeticsScript.EVENTS[ev]["name"])
	_open(ward_panel)
	_refresh_wardrobe(true)

func _ward_tab(cat: String) -> void:
	ward_cat = cat
	_refresh_wardrobe(true)

# Comment obtenir (ou état) d'un cosmétique.
func _ward_state(id: String) -> String:
	var cos = GameState.cos
	var it: Dictionary = cos.item(id)
	if cos.eq(it["cat"]) == id:
		return tr("✔ porté")
	if cos.has(id):
		return tr("possédé")
	if it.get("gift", false):
		return tr("cadeau de %s") % tr(GameState.CosmeticsScript.EVENTS[String(it["season"])]["name"])
	if it.has("ach"):
		return tr("succès : %s") % tr(Achievements.info(it["ach"])[1])
	if it.has("boss"):
		return tr("butin rare : %s") % tr(GameState.BOSSES[it["boss"]]["name"])
	if it.has("price"):
		if not GameState.CosmeticsScript.season_on(String(it.get("season", ""))):
			return tr("de retour pour %s") % tr(GameState.CosmeticsScript.EVENTS[String(it["season"])]["name"])
		return tr("%d éclats") % int(it["price"])
	return ""

func _refresh_wardrobe(focus_first := false) -> void:
	var cos = GameState.cos
	ward_geo.text = tr("Éclats : %d") % main.player.geo + "   —   " + tr("Cosmétiques : %d / %d") % [cos.owned_count(), cos.ITEMS.size() - cos.CATS.size()]
	for cat in ward_tabs:
		ward_tabs[cat].add_theme_color_override("font_color", Color(1.0, 0.88, 0.55) if cat == ward_cat else Color(0.75, 0.75, 0.8))
	_clear(ward_list)
	var first: Button = null
	for id in cos.items_of(ward_cat):
		var it: Dictionary = cos.item(id)
		var b: Button = main.menu._button("", _ward_pick.bind(id))
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = "        " + tr(it["name"]) + "  —  " + _ward_state(id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(540, 40)
		var col := Color(0.9, 0.88, 0.82)
		if cos.eq(ward_cat) == id:
			col = Color(1.0, 0.88, 0.55)
		elif not cos.has(id):
			col = Color(0.62, 0.64, 0.72)
			if it.has("season"):
				col = Color(0.75, 0.9, 1.0) if GameState.CosmeticsScript.season_on(String(it["season"])) else Color(0.5, 0.55, 0.62)
		b.add_theme_color_override("font_color", col)
		var sw := Swatch.new()
		sw.item_id = id
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sw.position = Vector2(6, 3)
		sw.size = Vector2(34, 34)
		b.add_child(sw)
		ward_list.add_child(b)
		if first == null or cos.eq(ward_cat) == id:
			first = b
	if focus_first and first:
		first.grab_focus()

func _ward_pick(id: String) -> void:
	var cos = GameState.cos
	var it: Dictionary = cos.item(id)
	if cos.has(id):
		cos.equip(id)
		ward_status.text = tr("%s : porté.") % tr(it["name"])
		Audio.sfx("pickup", 0.1, -6.0)
	elif it.has("price") and GameState.CosmeticsScript.season_on(String(it.get("season", ""))) and not it.get("gift", false):
		var price := int(it["price"])
		if main.player.geo < price:
			ward_status.text = tr("Pas assez d'éclats (%d nécessaires).") % price
			return
		main.player.geo -= price
		GameState.prog["geo"] = main.player.geo
		GameState.snapshot = GameState.prog.duplicate(true)
		GameState.save_game()
		Achievements.give_cosmetic(id)
		cos.equip(id)
		ward_status.text = tr("%s : acheté et porté.") % tr(it["name"])
		Audio.sfx("pickup", 0.0)
	else:
		ward_status.text = tr(it["name"]) + " — " + _ward_state(id)
		return
	Achievements.check_wardrobe()
	var keep := id
	_refresh_wardrobe()
	for b in ward_list.get_children():
		if b is Button and b.get_child_count() > 0 and b.get_child(0).item_id == keep:
			b.grab_focus()

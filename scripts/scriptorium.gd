extends CanvasLayer
# Le Scriptorium de Maître Plume : un grand livre ouvert. Page de gauche : le menu (statistiques,
# records, bestiaire, gardiens, emblèmes) ; page de droite : le contenu. Tout est dessiné en code ;
# les créatures et les boss sont de vrais ennemis du jeu, figés en simple portrait (display).

const DU = preload("res://scripts/draw_util.gd")
const CharmIcon = preload("res://scripts/charm_icon.gd")
const W := 1280.0
const H := 720.0

var main
var page := 0              # 0 stats, 1 records, 2 bestiaire, 3 gardiens, 4 emblèmes
var focus_grid := false    # la sélection est dans la grille de la page de droite
var sel := 0
var t := 0.0
var canvas: Control
var stage: Node2D          # portraits des créatures et des boss
var portraits := []        # [noeud, id, est_grand]
var _menu_rects := []
var _cell_rects := []
var _close_rect := Rect2()

const PAGES := ["Statistiques de la partie", "Records", "Bestiaire", "Gardiens", "Emblèmes"]
const PAGE_SUBS := ["tout depuis la création de ta sauvegarde", "tes meilleurs exploits", "les créatures vaincues", "les boss vaincus", "ta collection"]

const MOBS := ["crawler", "flyer", "spitter", "hopper", "guard", "bomber", "weaver", "lancer", "wraith", "monkey", "mimic", "moth", "mole", "slime", "scorpion", "goblin"]
const MOB_NAMES := {"crawler": "Rampant", "flyer": "Volant", "spitter": "Cracheur", "hopper": "Sauteur", "guard": "Garde",
	"bomber": "Bulbe", "weaver": "Tisseuse", "lancer": "Lancier", "wraith": "Spectre",
	"monkey": "Singe", "mimic": "Mimique", "moth": "Mite", "mole": "Taupe",
	"slime": "Slime", "scorpion": "Scorpion", "goblin": "Gobelin"}
const MOB_DESC := {
	"crawler": "Patrouille au sol ; quand il te voit, il se ramasse puis charge tête baissée.",
	"flyer": "Tourne en l'air puis plonge droit sur toi.",
	"spitter": "Plante enracinée qui crache des spores en cloche.",
	"hopper": "Bondit vers toi par grands sauts.",
	"guard": "Avance derrière son bouclier, bloque les coups de face et te repousse d'un coup de bouclier (parable).",
	"bomber": "Roule vers toi, s'allume… et explose.",
	"weaver": "Crache une toile qui englue (la ruée l'arrache), tombe sur sa proie puis remonte à son fil.",
	"lancer": "Se met en garde et lance une longue estocade.",
	"wraith": "Disparaît et réapparaît près de toi.",
	"monkey": "Bondit partout, lance des fruits durs et te vole des éclats avant de s'enfuir.",
	"mimic": "Se fait passer pour une cachette au trésor, puis mord et sautille vers toi.",
	"moth": "Attirée par ta lanterne : en tournant autour de toi, elle assombrit tout.",
	"mole": "Creuse sous le sol jusqu'à toi, puis jaillit sous tes pieds.",
	"slime": "Avance par bonds écrasés ; tué, il se divise en deux petits slimes.",
	"scorpion": "Arme son dard puis pique en avant : le venin te coûte un masque de plus un peu après.",
	"goblin": "Lance des dagues de loin, frappe deux fois de près, et s'enfuit quand il faiblit."}
const MOB_TIPS := {
	"crawler": "Un rebond sur sa carapace l'arrête net.",
	"flyer": "Recule au moment du piqué, puis frappe vers le haut.",
	"spitter": "Ses spores se détruisent d'un coup d'aiguille.",
	"hopper": "Pare au moment où il retombe sur toi.",
	"guard": "Frappe-le de dessus (rebond) ou passe dans son dos d'une ruée.",
	"bomber": "Éloigne-toi dès qu'il clignote : son explosion blesse aussi ses voisins.",
	"weaver": "Ne t'attarde pas sous les plafonds, puis frappe vers le haut.",
	"lancer": "Pare son estocade : il reste étourdi un long moment.",
	"wraith": "Il ne fait mal que lorsqu'il est bien visible.",
	"monkey": "Frappe-le avant qu'il ne file : il rend tout ce qu'il a volé.",
	"mimic": "Son couvercle tressaille parfois : une vraie cachette ne bouge jamais.",
	"moth": "Fragile : un coup suffit. Vise-la quand elle s'arrête avant de foncer.",
	"mole": "Écarte-toi quand le sol se fissure, puis frappe-la pendant qu'elle est sortie.",
	"slime": "Un rebond dessus l'écrase net ; garde de la place pour ses petits.",
	"scorpion": "Ses pinces parent les coups bas : frappe-le de dessus. Repose-toi pour chasser le venin.",
	"goblin": "Pare ses dagues pour les lui renvoyer ; s'il fuit, achève-le avant qu'il ne revienne."}

const BOSSES := ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre", "cerbere", "centaure", "oeil"]
const BOSS_NAMES := {"gardien": "Le Gardien du Puits", "abbesse": "L'Abbesse Engloutie", "reine": "La Reine Essaim",
	"colosse": "Le Colosse d'Os", "ver": "Le Ver des Profondeurs", "chevalier": "Le Chevalier Spectral",
	"ombre": "L'Ombre de la Lanterne", "cerbere": "Le Cerbère des Profondeurs", "centaure": "Le Centaure Archer", "oeil": "L'Œil d'en Dessous"}
const BOSS_DESC := {
	"gardien": "Scarabée cuirassé : charge annoncée, bond écrasant ; ondes de choc en phase 2.",
	"abbesse": "Reine des spores : charge, bond, salves en éventail et anneau de spores.",
	"reine": "Guêpe géante volante : piqués, salves de dards, anneaux en spirale ; elle appelle des volants.",
	"colosse": "Géant d'ossements : coups de poing qui font tomber des rochers, balayage du bras ; bond et piliers d'os en phase 2.",
	"ver": "Ver fouisseur : une traînée de poussière le trahit avant qu'il surgisse sous toi en crachant de l'acide.",
	"chevalier": "Duelliste fantôme : estocs éclair, téléportation dans ton dos, piliers spectraux.",
	"ombre": "La flamme éteinte elle-même, entourée de ses sbires.",
	"cerbere": "Molosse à trois têtes : morsures, souffle de braises, il appelle des rampants.",
	"centaure": "Archer des profondeurs : pluies de flèches et charge à la lance.",
	"oeil": "Un œil immense, tapi sous le sol, qui fait jaillir des tentacules."}
const BOSS_TIPS := {
	"gardien": "Saute par-dessus sa charge et frappe pendant qu'il freine.",
	"abbesse": "Détruis les spores d'un coup d'aiguille pour te faire de la place.",
	"reine": "Après un piqué, elle reste un instant au sol : c'est le moment.",
	"colosse": "Accroupis-toi sous son balayage ; recule quand il lève le poing.",
	"ver": "Suis la poussière et saute quand elle s'arrête.",
	"chevalier": "Après sa téléportation, retourne-toi et pare.",
	"ombre": "Garde ton ultime pour la deuxième phase.",
	"cerbere": "Ses morsures sont hautes : accroupis-toi pour les éviter.",
	"centaure": "Sa charge à la lance est haute : accroupis-toi, puis frappe.",
	"oeil": "Le sol tremble avant chaque tentacule : bouge aussitôt."}

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.draw.connect(_draw_book)
	canvas.gui_input.connect(_on_gui_input)
	add_child(canvas)
	stage = Node2D.new()
	add_child(stage)

# ---------------------------------------------------------------- ouverture
var _open_t := 0.0
func open() -> void:
	# reçoit les évènements avant le Sanctuaire et les menus
	get_parent().move_child(self, -1)
	_open_t = 0.15
	_b_was = Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	_hold_dir = Vector2i(0, -1) if Input.is_action_pressed("up") else Vector2i.ZERO
	visible = true
	page = 0
	focus_grid = false
	sel = 0
	get_tree().paused = true
	Audio.sfx("door", 0.05, -6.0)
	_build_portraits()

func close() -> void:
	visible = false
	_clear_portraits()
	get_tree().paused = false

func _process(delta: float) -> void:
	if not visible:
		return
	if _open_t > 0.0:
		_open_t -= delta          # ignore la touche qui vient d'ouvrir le livre
	else:
		_nav_input(delta)
	t += delta
	var k := _k()
	stage.scale = Vector2(k, k)
	stage.position = _off()
	for pt in portraits:
		var n = pt[0]
		if is_instance_valid(n):
			n.anim_t += delta
			n.queue_redraw()
	canvas.queue_redraw()

func _k() -> float:
	var vp: Vector2 = canvas.size
	return minf(vp.x / W, vp.y / H)

func _off() -> Vector2:
	return (canvas.size - Vector2(W, H) * _k()) / 2.0

# ---------------------------------------------------------------- données
func _c(key: String, def = 0):
	return GameState.j_get(key, def)

func _mob_data(id: String) -> Dictionary:
	return (GameState.journal.get("mobs", {}) as Dictionary).get(id, {})

func _boss_data(id: String) -> Dictionary:
	return (GameState.journal.get("bosses", {}) as Dictionary).get(id, {})

func _boss_beaten(id: String) -> bool:
	if int(_boss_data(id).get("w", 0)) > 0:
		return true
	# avant les registres : les gardiens des paliers déjà terminés sont forcément vaincus
	for p in range(1, mini(GameState.record, 6) + 1):
		if GameState.boss_for(p) == id:
			return true
	return false

static func fmt_time(s: float) -> String:
	var n := int(s)
	if n >= 3600:
		return "%d h %02d min" % [n / 3600, (n % 3600) / 60]
	return "%d:%02d" % [n / 60, n % 60]

static func fmt_n(v) -> String:
	var s := str(int(v))
	var out := ""
	while s.length() > 3:
		out = " " + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _grid_count() -> int:
	return [0, 0, MOBS.size(), BOSSES.size(), GameState.charm_count()][page]

func _grid_cols() -> int:
	return [1, 1, 4, 5, 7][page]

# ---------------------------------------------------------------- portraits (vrais ennemis figés)
func _clear_portraits() -> void:
	for pt in portraits:
		if is_instance_valid(pt[0]):
			pt[0].queue_free()
	portraits.clear()

func _make(script_path: String, variant := 0, elite := false):
	var n := CharacterBody2D.new()
	n.set_script(load(script_path))
	n.display = true
	n.main = main
	if variant > 0:
		n.variant = variant
	n.elite = elite
	n.process_mode = Node.PROCESS_MODE_DISABLED
	stage.add_child(n)
	return n

func _boss_script(id: String) -> Array:
	var m := {"reine": "boss_queen", "colosse": "boss_colossus", "ver": "boss_worm", "chevalier": "boss_knight", "ombre": "boss_lantern",
		"cerbere": "boss_cerberus", "centaure": "boss_centaur", "oeil": "boss_eye"}
	if m.has(id):
		return ["res://scripts/%s.gd" % m[id], 0]
	return ["res://scripts/boss.gd", 2 if id == "abbesse" else 1]

func _build_portraits() -> void:
	_clear_portraits()
	if page == 2:
		for i in MOBS.size():
			var id: String = MOBS[i]
			var n = _make("res://scripts/%s.gd" % id)
			var seen := int(_mob_data(id).get("k", 0)) > 0
			n.modulate = Color(1, 1, 1) if seen else Color(0, 0, 0, 0.3)
			portraits.append([n, i, false])
		var big = _make("res://scripts/%s.gd" % MOBS[sel])
		portraits.append([big, -1, true])
		if int(_mob_data(MOBS[sel]).get("e", 0)) > 0:
			var el = _make("res://scripts/%s.gd" % MOBS[sel], 0, true)
			portraits.append([el, -2, true])
		big.modulate = Color(1, 1, 1) if int(_mob_data(MOBS[sel]).get("k", 0)) > 0 else Color(0, 0, 0, 0.3)
	elif page == 3:
		for i in BOSSES.size():
			var id: String = BOSSES[i]
			var sc := _boss_script(id)
			var n = _make(sc[0], sc[1])
			n.modulate = Color(1, 1, 1) if _boss_beaten(id) else Color(0, 0, 0, 0.3)
			portraits.append([n, i, false])
		var sc2 := _boss_script(BOSSES[sel])
		var big = _make(sc2[0], sc2[1])
		big.modulate = Color(1, 1, 1) if _boss_beaten(BOSSES[sel]) else Color(0, 0, 0, 0.3)
		portraits.append([big, -1, true])
	_place_portraits()

func _place_portraits() -> void:
	for pt in portraits:
		var n = pt[0]
		if not is_instance_valid(n):
			continue
		if page == 2:
			if pt[1] >= 0:
				var cell := _cell_rect(pt[1])
				n.position = cell.position + Vector2(cell.size.x / 2.0, 42)
				n.scale = Vector2(1.3, 1.3)
			else:
				n.position = Vector2(1000 + (-40 if pt[1] == -1 and portraits.size() > MOBS.size() + 1 else 0) + (50 if pt[1] == -2 else 0), 200)
				n.scale = Vector2(2.6, 2.6) if pt[1] == -1 else Vector2(2.0, 2.0)
		elif page == 3:
			# taille du portrait d'après la taille réelle du boss (son dessin déborde un peu)
			var big: float = maxf(n.size.x, n.size.y)
			if pt[1] >= 0:
				var cell := _cell_rect(pt[1])
				var sc := 56.0 / maxf(big, 50.0)
				n.scale = Vector2(sc, sc)
				n.position = cell.position + Vector2(cell.size.x / 2.0, 48)
			else:
				var sc := 132.0 / maxf(big, 60.0)
				n.scale = Vector2(sc, sc)
				n.position = Vector2(1035, 205)

# ---------------------------------------------------------------- dessin
func _draw_book() -> void:
	var c := canvas
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.03, 0.02, 0.02, 0.88))
	c.draw_set_transform(_off(), 0.0, Vector2(_k(), _k()))
	var f := ThemeDB.fallback_font
	# couverture et pages
	var book := Rect2(70, 40, 1140, 640)
	c.draw_rect(book.grow(4), Color(0.55, 0.42, 0.24))
	c.draw_rect(book, Color(0.23, 0.14, 0.08))
	var lp := Rect2(90, 60, 300, 600)
	var rp := Rect2(400, 60, 790, 600)
	for pr in [lp, rp]:
		c.draw_rect(pr, Color(0.93, 0.88, 0.76))
		c.draw_rect(Rect2(pr.position, Vector2(pr.size.x, 6)), Color(0.86, 0.79, 0.64))
	# ombre de la reliure
	for i in 10:
		c.draw_rect(Rect2(390 - i, 60, 1, 600), Color(0.3, 0.2, 0.1, 0.05 * (10 - i)))
		c.draw_rect(Rect2(400 + i, 60, 1, 600), Color(0.3, 0.2, 0.1, 0.05 * (10 - i)))
	var ink := Color(0.24, 0.16, 0.1)
	var red := Color(0.48, 0.2, 0.08)
	var soft := Color(0.45, 0.36, 0.26)
	# page de gauche : titre et menu
	c.draw_string(f, Vector2(116, 106), tr("Le Scriptorium"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, red)
	c.draw_string(f, Vector2(118, 132), tr("Les registres de Maître Plume"), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, soft)
	_menu_rects.clear()
	for i in PAGES.size():
		var r := Rect2(108, 160 + i * 74, 264, 64)
		_menu_rects.append(r)
		if i == page:
			c.draw_rect(r, Color(0.64, 0.33, 0.16, 0.14))
			c.draw_rect(r, Color(0.64, 0.33, 0.16, 0.9 if not focus_grid else 0.45), false, 2.0)
		c.draw_string(f, r.position + Vector2(14, 28), tr(PAGES[i]), HORIZONTAL_ALIGNMENT_LEFT, 240, 19, red if i == page else ink)
		c.draw_string(f, r.position + Vector2(14, 50), _menu_sub(i), HORIZONTAL_ALIGNMENT_LEFT, 240, 12, soft)
	_wrap_draw(c, tr("« Ce qui n'est pas écrit est oublié. Ce qui est écrit ici ne l'est jamais. »"), Vector2(116, 590), 250, 13, soft)
	# fermeture
	_close_rect = Rect2(560, 668, 160, 34)
	c.draw_rect(_close_rect, Color(0.18, 0.11, 0.06))
	c.draw_rect(_close_rect, Color(0.75, 0.6, 0.32), false, 1.5)
	c.draw_string(f, _close_rect.position + Vector2(0, 23), tr("Fermer"), HORIZONTAL_ALIGNMENT_CENTER, 160, 16, Color(0.95, 0.9, 0.8))
	match page:
		0: _draw_stats(c, f, ink, red, soft)
		1: _draw_records(c, f, ink, red, soft)
		2: _draw_bestiary(c, f, ink, red, soft)
		3: _draw_bosses(c, f, ink, red, soft)
		4: _draw_charms(c, f, ink, red, soft)

func _menu_sub(i: int) -> String:
	match i:
		2:
			var n := 0
			for id in MOBS:
				if int(_mob_data(id).get("k", 0)) > 0:
					n += 1
			return tr("créatures vaincues : %d / %d") % [n, MOBS.size()]
		3:
			var b := 0
			for id in BOSSES:
				if _boss_beaten(id):
					b += 1
			return tr("gardiens vaincus : %d / %d") % [b, BOSSES.size()]
		4:
			return tr("ta collection : %d / %d") % [GameState.prog["owned"].size(), GameState.charm_count()]
	return tr(PAGE_SUBS[i])

func _row(c: Control, f: Font, pos: Vector2, w: float, label: String, value: String, ink: Color) -> void:
	var vw: float = f.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var lw := w - vw - 10.0
	var fs := 15
	while fs > 11 and f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > lw:
		fs -= 1
	c.draw_string(f, pos, label, HORIZONTAL_ALIGNMENT_LEFT, lw, fs, ink)
	c.draw_string(f, pos, value, HORIZONTAL_ALIGNMENT_RIGHT, w, 15, ink)
	for x in range(0, int(w), 6):
		c.draw_rect(Rect2(pos.x + x, pos.y + 7, 2, 1), Color(0.4, 0.3, 0.2, 0.3))

func _heading(c: Control, f: Font, pos: Vector2, w: float, text: String, red: Color) -> void:
	c.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, red)
	c.draw_rect(Rect2(pos.x, pos.y + 7, w, 1.5), Color(0.48, 0.24, 0.1, 0.4))

func _draw_stats(c: Control, f: Font, ink: Color, red: Color, soft: Color) -> void:
	var x1 := 430.0
	var x2 := 820.0
	var w := 340.0
	c.draw_string(f, Vector2(x1, 100), tr("Statistiques de la partie"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, red)
	c.draw_string(f, Vector2(x1, 124), tr("%s · temps de jeu : %s") % [tr(GameState.DIFFS[GameState.difficulty]["name"]), fmt_time(float(_c("time", 0.0)))], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, soft)
	_heading(c, f, Vector2(x1, 162), w, tr("Combat"), red)
	var rows1 := [["Ennemis vaincus", fmt_n(_c("kills"))], ["dont élites", fmt_n(_c("elites"))], ["Gardiens vaincus", fmt_n(_c("bosses"))],
		["Dégâts infligés", fmt_n(_c("damage"))], ["Coups critiques", fmt_n(_c("crits"))],
		["Parades (dont parfaites)", "%s (%s)" % [fmt_n(_c("parries")), fmt_n(_c("perfect"))]],
		["Soins / sorts / ultimes", "%s / %s / %s" % [fmt_n(_c("heals")), fmt_n(_c("spells")), fmt_n(_c("ults"))]],
		["Coups reçus", fmt_n(_c("hurt"))], ["Chutes", fmt_n(_c("deaths"))]]
	for i in rows1.size():
		_row(c, f, Vector2(x1, 192 + i * 27), w, tr(rows1[i][0]), rows1[i][1], ink)
	# arme favorite : part des coups
	_heading(c, f, Vector2(x1, 452), w, tr("Arme favorite"), red)
	var wh: Dictionary = GameState.journal.get("w", {})
	var total := 0
	for k in wh:
		total += int(wh[k])
	if total == 0:
		c.draw_string(f, Vector2(x1, 482), tr("Pas encore de coups portés."), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, soft)
	else:
		var ids := wh.keys()
		ids.sort_custom(func(a, b): return int(wh[a]) > int(wh[b]))
		for i in mini(ids.size(), 4):
			var id: String = ids[i]
			var pct := 100.0 * int(wh[id]) / float(total)
			var y := 476.0 + i * 38.0
			c.draw_string(f, Vector2(x1, y), "%s — %d %%" % [tr(GameState.WeaponsData.W[id]["name"]) if GameState.WeaponsData.W.has(id) else id, roundi(pct)], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, ink)
			c.draw_rect(Rect2(x1, y + 7, w, 8), Color(0.4, 0.3, 0.2, 0.15))
			c.draw_rect(Rect2(x1, y + 7, w * pct / 100.0, 8), Color(0.75, 0.42, 0.2))
	_heading(c, f, Vector2(x2, 162), w, tr("Mouvements"), red)
	var rows2 := [["Sauts", fmt_n(_c("jumps"))], ["Ruées", fmt_n(_c("dashes"))], ["Rebonds", fmt_n(_c("pogos"))],
		["Estocs (dont repoussants)", "%s (%s)" % [fmt_n(_c("thrusts")), fmt_n(_c("pushes"))]], ["Attaques plongées", fmt_n(_c("plunges"))]]
	for i in rows2.size():
		_row(c, f, Vector2(x2, 192 + i * 27), w, tr(rows2[i][0]), rows2[i][1], ink)
	_heading(c, f, Vector2(x2, 352), w, tr("Exploration"), red)
	var rows3 := [["Palier le plus profond", str(GameState.record)], ["Descentes terminées", fmt_n(_c("descents"))],
		["Trésors trouvés", fmt_n(_c("chests"))], ["Treuils empruntés", fmt_n(_c("winches"))],
		["Éclats gagnés / dépensés", "%s / %s" % [fmt_n(_c("geo_in")), fmt_n(_c("geo_out"))]],
		["Emblèmes trouvés", "%d / %d" % [GameState.prog["owned"].size(), GameState.charm_count()]]]
	for i in rows3.size():
		_row(c, f, Vector2(x2, 382 + i * 27), w, tr(rows3[i][0]), rows3[i][1], ink)

func _draw_records(c: Control, f: Font, ink: Color, red: Color, soft: Color) -> void:
	var x := 440.0
	var w := 700.0
	var rec: Dictionary = GameState.journal.get("rec", {})
	c.draw_string(f, Vector2(x, 100), tr("Records"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, red)
	c.draw_string(f, Vector2(x, 124), tr("Tes meilleurs exploits dans cette partie."), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, soft)
	var rush := float(Achievements.counters.get("rush_best", 0.0))
	var rows := [
		["Palier le plus profond", str(GameState.record)],
		["Palier terminé le plus vite", fmt_time(float(rec["fast_palier"])) if float(rec.get("fast_palier", 0.0)) > 0.0 else "—"],
		["Le plus d'ennemis en une descente", fmt_n(rec.get("kills_run", 0))],
		["Le plus de dégâts en une descente", fmt_n(rec.get("dmg_run", 0))],
		["Le plus de critiques en une descente", fmt_n(rec.get("crits_run", 0))],
		["Plus longue série de parades parfaites", fmt_n(rec.get("streak", 0))],
		["Paliers terminés sans coup reçu", fmt_n(_c("flawless"))],
		["Meilleur temps au Défi des boss", fmt_time(rush) if rush > 0.0 else "—"]]
	for i in rows.size():
		var y := 176.0 + i * 50.0
		c.draw_rect(Rect2(x, y - 26, w, 42), Color(0.64, 0.33, 0.16, 0.06 if i % 2 == 0 else 0.0))
		c.draw_string(f, Vector2(x + 16, y), tr(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, ink)
		c.draw_string(f, Vector2(x, y), rows[i][1], HORIZONTAL_ALIGNMENT_RIGHT, w - 16, 20, red)

func _cell_rect(i: int) -> Rect2:
	match page:
		2:
			return Rect2(420 + (i % 4) * 114, 108 + (i / 4) * 120, 110, 114)
		3:
			return Rect2(420 + (i % 5) * 92, 112 + (i / 5) * 156, 88, 148)
		4:
			return Rect2(420 + (i % 7) * 76, 112 + (i / 7) * 104, 72, 98)
	return Rect2()

func _sel_frame(c: Control, r: Rect2, on: bool) -> void:
	if on:
		c.draw_rect(r, Color(0.64, 0.33, 0.16, 0.14))
		c.draw_rect(r, Color(0.64, 0.33, 0.16, 0.9 if focus_grid else 0.5), false, 2.0)

func _draw_bestiary(c: Control, f: Font, ink: Color, red: Color, soft: Color) -> void:
	_cell_rects.clear()
	var seen := 0
	for id in MOBS:
		if int(_mob_data(id).get("k", 0)) > 0:
			seen += 1
	c.draw_string(f, Vector2(430, 96), tr("Bestiaire — %d / %d créatures") % [seen, MOBS.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, red)
	for i in MOBS.size():
		var r := _cell_rect(i)
		_cell_rects.append(r)
		_sel_frame(c, r, i == sel)
		var d := _mob_data(MOBS[i])
		var k := int(d.get("k", 0))
		c.draw_string(f, r.position + Vector2(0, 86), tr(MOB_NAMES[MOBS[i]]) if k > 0 else "???", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 14, ink)
		c.draw_string(f, r.position + Vector2(0, 104), (tr("%s vaincus") % fmt_n(k)) if k > 0 else tr("jamais vaincu"), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, soft)
	# fiche
	var id: String = MOBS[sel]
	var d2 := _mob_data(id)
	var known := int(d2.get("k", 0)) > 0
	var x := 890.0
	var w := 280.0
	c.draw_circle(Vector2(1010, 200), 90, Color(0.64, 0.33, 0.16, 0.08))
	c.draw_string(f, Vector2(x, 330), tr(MOB_NAMES[id]) if known else "???", HORIZONTAL_ALIGNMENT_CENTER, w, 22, red)
	if not known:
		_wrap_draw(c, tr("Maître Plume n'a encore rien écrit sur cette créature. Va la vaincre !"), Vector2(x, 362), w, 14, soft)
		return
	var y := _wrap_draw(c, tr(MOB_DESC[id]), Vector2(x, 360), w, 14, ink)
	var biomes: Array = d2.get("b", [])
	var bl := []
	for b in biomes:
		bl.append(tr(String(b)))
	var rows := [["Vaincus", fmt_n(d2.get("k", 0))], ["dont élites", fmt_n(d2.get("e", 0))], ["Coups reçus de lui", fmt_n(d2.get("hurt", 0))]]
	for i in rows.size():
		_row(c, f, Vector2(x, y + 14 + i * 24), w, tr(rows[i][0]), rows[i][1], ink)
	y += 14 + rows.size() * 24
	if not bl.is_empty():
		y = _wrap_draw(c, tr("Rencontré : %s") % ", ".join(bl), Vector2(x, y + 6), w, 13, soft)
	_tip(c, f, Vector2(x, y + 14), w, tr(MOB_TIPS[id]), red, ink)

func _tip(c: Control, f: Font, pos: Vector2, w: float, text: String, red: Color, ink: Color) -> void:
	var lines := _wrap(tr("Astuce de Maître Plume : ") + text, w - 16, 13)
	var h := 12.0 + lines.size() * 18.0
	c.draw_rect(Rect2(pos, Vector2(w, h)), Color(0.64, 0.33, 0.16, 0.12))
	c.draw_rect(Rect2(pos, Vector2(3, h)), Color(0.64, 0.33, 0.16))
	for i in lines.size():
		c.draw_string(f, pos + Vector2(10, 20 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)

func _draw_bosses(c: Control, f: Font, ink: Color, red: Color, soft: Color) -> void:
	_cell_rects.clear()
	var beaten := 0
	for id in BOSSES:
		if _boss_beaten(id):
			beaten += 1
	c.draw_string(f, Vector2(430, 96), tr("Gardiens — %d / %d vaincus") % [beaten, BOSSES.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, red)
	for i in BOSSES.size():
		var r := _cell_rect(i)
		_cell_rects.append(r)
		_sel_frame(c, r, i == sel)
		var id: String = BOSSES[i]
		var ok := _boss_beaten(id)
		var lines := _wrap(tr(BOSS_NAMES[id]) if ok else "???", r.size.x - 4, 12)
		for li in mini(lines.size(), 2):
			c.draw_string(f, r.position + Vector2(0, 94 + li * 14), lines[li], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, ink)
		var d := _boss_data(id)
		var sub := ""
		if ok:
			sub = "×%d" % maxi(int(d.get("w", 0)), 1)
			if float(d.get("best", 0.0)) > 0.0:
				sub += " · " + fmt_time(float(d["best"]))
		else:
			sub = tr("à vaincre")
		c.draw_string(f, r.position + Vector2(0, 132), sub, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, soft)
	c.draw_string(f, Vector2(430, 452), tr("Les quatre derniers gardiens attendent tout au fond, au palier 7 et au-delà."), HORIZONTAL_ALIGNMENT_LEFT, 440, 12, Color(0.55, 0.22, 0.15))
	# fiche
	var bid: String = BOSSES[sel]
	var ok2 := _boss_beaten(bid)
	var x := 900.0
	var w := 270.0
	c.draw_circle(Vector2(1035, 205), 100, Color(0.64, 0.33, 0.16, 0.08))
	var ny := _wrap_draw(c, tr(BOSS_NAMES[bid]) if ok2 else "???", Vector2(x, 352), w, 20, red, true)
	if not ok2:
		_wrap_draw(c, tr("Personne n'en est revenu pour le décrire… pour l'instant."), Vector2(x, ny + 6), w, 14, soft)
		return
	var y := _wrap_draw(c, tr(BOSS_DESC[bid]), Vector2(x, ny + 4), w, 13, ink)
	var d2 := _boss_data(bid)
	var rows := [["Victoires", fmt_n(maxi(int(d2.get("w", 0)), 1))], ["Meilleur temps", fmt_time(float(d2["best"])) if float(d2.get("best", 0.0)) > 0.0 else "—"],
		["Combats perdus", fmt_n(d2.get("l", 0))], ["Victoire sans coup reçu", tr("oui") if bool(d2.get("nohit", false)) else tr("pas encore")]]
	for i in rows.size():
		_row(c, f, Vector2(x, y + 12 + i * 22), w, tr(rows[i][0]), rows[i][1], ink)
	_tip(c, f, Vector2(x, y + 14 + rows.size() * 22), w, tr(BOSS_TIPS[bid]), red, ink)

func _draw_charms(c: Control, f: Font, ink: Color, red: Color, soft: Color) -> void:
	_cell_rects.clear()
	var n: int = GameState.charm_count()
	c.draw_string(f, Vector2(430, 96), tr("Emblèmes — %d / %d trouvés") % [GameState.prog["owned"].size(), n], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, red)
	for i in n:
		var r := _cell_rect(i)
		_cell_rects.append(r)
		_sel_frame(c, r, i == sel)
		var cc := r.position + Vector2(r.size.x / 2.0, 34)
		if GameState.owns(i):
			CharmIcon.draw(c, cc, 25.0, i, GameState.charm(i)["color"], GameState.has_charm(i), t)
			var nm := _wrap(tr(GameState.charm(i)["name"]), r.size.x, 11)
			for li in mini(nm.size(), 2):
				c.draw_string(f, r.position + Vector2(0, 76 + li * 13), nm[li], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, ink)
		else:
			c.draw_circle(cc, 24.0, Color(0.8, 0.74, 0.6))
			c.draw_arc(cc, 24.0, 0.0, TAU, 32, Color(0.6, 0.5, 0.36), 1.5)
			c.draw_string(f, cc + Vector2(-8, 9), "?", HORIZONTAL_ALIGNMENT_CENTER, 16, 24, Color(0.55, 0.46, 0.33))
			c.draw_string(f, r.position + Vector2(0, 76), "???", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, soft)
	# fiche
	var x := 960.0
	var w := 210.0
	var id := sel
	if not GameState.owns(id):
		c.draw_circle(Vector2(x + w / 2.0, 170), 54.0, Color(0.8, 0.74, 0.6))
		c.draw_string(f, Vector2(x, 186), "?", HORIZONTAL_ALIGNMENT_CENTER, w, 46, Color(0.55, 0.46, 0.33))
		_wrap_draw(c, tr("Un emblème encore caché quelque part dans les profondeurs."), Vector2(x, 260), w, 14, soft)
		return
	var ch: Dictionary = GameState.charm(id)
	CharmIcon.draw(c, Vector2(x + w / 2.0, 170), 52.0, id, ch["color"], GameState.has_charm(id), t)
	var y := _wrap_draw(c, tr(ch["name"]), Vector2(x, 252), w, 19, red, true)
	for k in int(ch["cost"]):
		c.draw_circle(Vector2(x + w / 2.0 - (int(ch["cost"]) - 1) * 9.0 + k * 18.0, y + 10), 6.0, Color(0.7, 0.4, 0.2))
	y = _wrap_draw(c, tr(ch["desc"]), Vector2(x, y + 36), w, 13, ink)
	var info: Dictionary = (GameState.journal.get("charms", {}) as Dictionary).get(str(id), {})
	var lines := []
	if int(info.get("p", -1)) > 0:
		lines.append(tr("Trouvé : palier %d, %s") % [int(info["p"]), tr(String(info.get("b", "")))])
	elif int(info.get("p", -1)) == 0:
		lines.append(tr("Acheté au Sanctuaire"))
	var tot := float(_c("time", 0.0))
	var pct := 100.0 * float(info.get("t", 0.0)) / maxf(tot, 1.0)
	if tot > 60.0 and pct >= 0.5:
		lines.append(tr("Équipé pendant %d %% de ton temps de jeu") % roundi(pct))
	if GameState.has_charm(id):
		lines.append(tr("Équipé en ce moment"))
	if not lines.is_empty():
		c.draw_rect(Rect2(x, y + 6, w, 1), Color(0.4, 0.3, 0.2, 0.35))
		var ly := y + 26.0
		for i in lines.size():
			ly = _wrap_draw(c, lines[i], Vector2(x, ly), w, 12, soft) + 4.0

# ---------------------------------------------------------------- texte
func _wrap(text: String, width: float, fsize: int) -> Array:
	var f := ThemeDB.fallback_font
	var out := []
	var line := ""
	for word in text.split(" "):
		var test := word if line == "" else line + " " + word
		if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width and line != "":
			out.append(line)
			line = word
		else:
			line = test
	if line != "":
		out.append(line)
	return out

# écrit un paragraphe ; renvoie la position y sous la dernière ligne
func _wrap_draw(c: Control, text: String, pos: Vector2, width: float, fsize: int, col: Color, center := false) -> float:
	var f := ThemeDB.fallback_font
	var lines := _wrap(text, width, fsize)
	var lh := fsize * 1.4
	for i in lines.size():
		c.draw_string(f, pos + Vector2(0, i * lh), lines[i], HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT, width if center else -1, fsize, col)
	return pos.y + lines.size() * lh

# ---------------------------------------------------------------- commandes
func _set_page(p: int) -> void:
	if p == page:
		return
	page = p
	sel = 0
	Audio.sfx("door", 0.2, -12.0)
	_build_portraits()

func _set_sel(i: int) -> void:
	i = clampi(i, 0, _grid_count() - 1)
	if i == sel:
		return
	sel = i
	if page in [2, 3]:
		_build_portraits()

# Clavier et manette (croix, stick gauche, A, B) : lus à chaque image avec répétition quand on
# maintient la direction. Les évènements sont gardés pour le livre (le Sanctuaire derrière ne les
# reçoit pas) ; la souris passe par _on_gui_input.
var _hold_dir := Vector2i.ZERO
var _hold_t := 0.0

func _input(event: InputEvent) -> void:
	if visible and not (event is InputEventMouse):
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

func _nav_input(delta: float) -> void:
	var b_edge := _b_edge()
	if _pressed(["pause_menu", "ui_cancel", "inventory"]) or b_edge:
		if focus_grid:
			focus_grid = false
		else:
			close()
		return
	if _pressed(["jump", "ui_accept", "attack"]):
		if not focus_grid and _grid_count() > 0:
			focus_grid = true
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
		_hold_t = 0.35          # premier pas immédiat, puis répétition après une courte pause
		_step(d)
		return
	_hold_t -= delta
	if _hold_t <= 0.0:
		_hold_t = 0.12
		_step(d)

var _b_was := false
func _b_edge() -> bool:
	var now := Input.is_joy_button_pressed(0, JOY_BUTTON_B)
	var edge := now and not _b_was
	_b_was = now
	return edge

func _step(d: Vector2i) -> void:
	var grid := _grid_count() > 0
	var cols := _grid_cols()
	if d.y != 0:
		if focus_grid:
			var n := sel + d.y * cols
			if n >= 0 and n < _grid_count():
				_set_sel(n)
		else:
			_set_page(posmod(page + d.y, PAGES.size()))
	elif d.x > 0:
		if not focus_grid and grid:
			focus_grid = true
		elif focus_grid and sel % cols < cols - 1 and sel + 1 < _grid_count():
			_set_sel(sel + 1)
	elif d.x < 0 and focus_grid:
		if sel % cols == 0:
			focus_grid = false
		else:
			_set_sel(sel - 1)

func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var p: Vector2 = (event.position - _off()) / _k()
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventMouseMotion or click:
		for i in _menu_rects.size():
			if _menu_rects[i].has_point(p) and click:
				focus_grid = false
				_set_page(i)
				return
		for i in _cell_rects.size():
			if _cell_rects[i].has_point(p):
				focus_grid = true
				_set_sel(i)
				return
		if click and _close_rect.has_point(p):
			close()

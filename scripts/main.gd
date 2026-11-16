extends Node2D
# Lanterne des Profondeurs — scène principale.
# Construit le niveau à partir de la carte ASCII ci-dessous, crée le joueur,
# les ennemis, la caméra, l'éclairage et le HUD.
#
# Légende de la carte :
#   #  roche          ^  pics            P  départ du joueur
#   B  banc (repos)   c  rampant         f  volant        s  cracheur
#   D  orbe de Ruée   K  Gardien (boss)  Q  Abbesse (boss final)
#   O  passage vers le niveau suivant    E  sanctuaire (fin du jeu)
#   1-8 emblème (voir charms.gd)         N  encoche d'emblème supplémentaire
#   T  panneau du tutoriel               m  mannequin d'entraînement
#   M  marchand (hub)                    L  ascenseur (hub)
#   *  emblème au hasard (niveaux générés)    h  sauteur    g  garde à bouclier
#   b  bulbe explosif   l  lancier   w  tisseuse (plafond)   r  spectre
#   Y  grille d'entrée de l'arène        X  grille de sortie
# Les cartes sont dans scripts/levels.gd.

const TILE := 32
const DU = preload("res://scripts/draw_util.gd")
const PlayerScript = preload("res://scripts/player.gd")
const TrapScript = preload("res://scripts/trap.gd")
const PlatformScript = preload("res://scripts/platform.gd")
const CrawlerScript = preload("res://scripts/crawler.gd")
const FlyerScript = preload("res://scripts/flyer.gd")
const BossScript = preload("res://scripts/boss.gd")
const GateScript = preload("res://scripts/gate.gd")
const LevelArtScript = preload("res://scripts/level_art.gd")
const BackgroundScript = preload("res://scripts/background.gd")
const PropScript = preload("res://scripts/prop.gd")
const HudScript = preload("res://scripts/hud.gd")
const SpitterScript = preload("res://scripts/spitter.gd")
const ProjectileScript = preload("res://scripts/projectile.gd")
const RingScript = preload("res://scripts/fx_ring.gd")
const MenuScript = preload("res://scripts/menu.gd")
const InventoryScript = preload("res://scripts/inventory.gd")
const DummyScript = preload("res://scripts/dummy.gd")
const LoadingScript = preload("res://scripts/loading.gd")
const HopperScript = preload("res://scripts/hopper.gd")
const GuardScript = preload("res://scripts/guard.gd")
const Biomes = preload("res://scripts/biomes.gd")
const HubUIScript = preload("res://scripts/hub_ui.gd")
const PillarScript = preload("res://scripts/pillar.gd")
const BossQueen = preload("res://scripts/boss_queen.gd")
const BossColossus = preload("res://scripts/boss_colossus.gd")
const BossWorm = preload("res://scripts/boss_worm.gd")
const BossKnight = preload("res://scripts/boss_knight.gd")
const BossLantern = preload("res://scripts/boss_lantern.gd")
const BossCerberus = preload("res://scripts/boss_cerberus.gd")
const BossCentaur = preload("res://scripts/boss_centaur.gd")
const BossEye = preload("res://scripts/boss_eye.gd")
const EndingScript = preload("res://scripts/ending.gd")
const BomberScript = preload("res://scripts/bomber.gd")
const WeaverScript = preload("res://scripts/weaver.gd")
const LancerScript = preload("res://scripts/lancer.gd")
const WraithScript = preload("res://scripts/wraith.gd")

var MAP: Array = []

var solid := {}
var spikes: Array[Rect2] = []
var map_size := Vector2i.ZERO
var player
var camera: Camera2D
var hud
var boss
var bench_pos := Vector2.ZERO
var respawn_pos := Vector2.ZERO   # départ du niveau, puis dernier banc utilisé
var dash_orb
var shrine
var exit_door
var leaving := false
var flash := 0.0
var bench
var entry_gate
var exit_gate
var enemy_spawns := []   # [script, position, node]
var boss_started := false
var boss_dead := false
var won := false
var shake_amt := 0.0
var light_tex: GradientTexture2D
var menu
var inventory
var map_view
var challenge_start = null
var challenge_goal = null
var challenge_t := 0.0
var challenge_done := false
var altar_foes := []
var altar_state := ""     # "" / "fight" / "done"
var explored := PackedByteArray()   # cases découvertes (carte)
var _reveal_t := 0.0
const MapViewScript = preload("res://scripts/map_view.gd")
var signs := []     # [prop, données du panneau, déjà déclenché]
var sign_text := ""
var benches := []   # positions des bancs
var pal: Dictionary = {}
var level: Dictionary = {}
var interactables := []   # [prop, "merchant"/"elevator"]
var interact_hint := ""
var hub_ui
var pickups := []   # [prop, "charm"/"notch", id ou clé]

func _ready() -> void:
	randomize()
	level = GameState.current_level()
	MAP = level["map"]
	pal = level.get("palette", Biomes.all()[0]["pal"])
	RenderingServer.set_default_clear_color(pal["bg"])
	light_tex = DU.radial_texture()
	_build_level()
	_spawn_everything()
	_spawn_shade()
	_setup_camera_and_fx()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.set_script(HudScript)
	hud.main = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)
	menu = CanvasLayer.new()
	menu.set_script(MenuScript)
	menu.main = self
	add_child(menu)
	explored.resize(map_size.x * map_size.y)
	explored.fill(1 if (GameState.mode != "descent" or GameState.prog.get("map_full", false)) else 0)
	map_view = CanvasLayer.new()
	map_view.set_script(MapViewScript)
	map_view.main = self
	add_child(map_view)
	inventory = CanvasLayer.new()
	inventory.set_script(InventoryScript)
	inventory.main = self
	add_child(inventory)
	GameState.equipment_changed.connect(player.apply_equipment)
	hub_ui = CanvasLayer.new()
	hub_ui.set_script(HubUIScript)
	hub_ui.main = self
	add_child(hub_ui)
	if GameState.is_tutorial():
		player.can_dash = true
		show_message(level["name"], 3.0)
	elif GameState.is_hub():
		show_message(GameState.pending_message if GameState.pending_message != "" else level["name"], 4.5)
	elif GameState.mode == "rush":
		show_message(tr("Défi des boss — %d / %d\n%s") % [GameState.rush_i + 1, GameState.RUSH_ORDER.size(), GameState.boss_name_for_id(GameState.RUSH_ORDER[GameState.rush_i])], 3.0)
	else:
		var head := tr("Descente du jour") + " — " if GameState.daily else ""
		var cur := ("  —  " + tr(GameState.CURSES[GameState.curse]["name"])) if GameState.curse != "" else ""
		show_message(head + tr("Palier %d — niveau %d / %d%s\n%s — %s") % [GameState.palier, GameState.step, GameState.STEPS_PER_PALIER,
			tr("  (boss)") if GameState.is_boss_level() else "", tr(level["name"]), GameState.diff_name()] + cur, 3.5)
	GameState.pending_message = ""
	Audio.play_playlist(level.get("music", []))
	if GameState.show_title:
		LoadingScript.launch(get_tree())     # écran de lancement animé (une seule fois)
		menu.open_title()

# ---------------------------------------------------------------- niveau
func _build_level() -> void:
	var h := MAP.size()
	var w := 0
	for row in MAP:
		w = maxi(w, (row as String).length())
	map_size = Vector2i(w, h)
	var gate_cells := {"Y": [], "X": []}
	for y in h:
		var row: String = MAP[y]
		for x in w:
			var ch: String = row[x] if x < row.length() else "."
			match ch:
				"#":
					solid[Vector2i(x, y)] = true
				"^":
					spikes.append(Rect2(x * TILE + 3, y * TILE + 12, TILE - 6, TILE - 12))
				"Y", "X":
					gate_cells[ch].append(Vector2i(x, y))
	# Collisions : fusion gloutonne des cases en grands rectangles.
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var used := {}
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not solid.has(c) or used.has(c):
				continue
			var x2 := x
			while solid.has(Vector2i(x2 + 1, y)) and not used.has(Vector2i(x2 + 1, y)):
				x2 += 1
			var y2 := y
			var can_grow := true
			while can_grow:
				for xx in range(x, x2 + 1):
					var n := Vector2i(xx, y2 + 1)
					if not solid.has(n) or used.has(n):
						can_grow = false
						break
				if can_grow:
					y2 += 1
			for yy in range(y, y2 + 1):
				for xx in range(x, x2 + 1):
					used[Vector2i(xx, yy)] = true
			var shape := RectangleShape2D.new()
			shape.size = Vector2((x2 - x + 1) * TILE, (y2 - y + 1) * TILE)
			var cs := CollisionShape2D.new()
			cs.shape = shape
			cs.position = Vector2(x * TILE, y * TILE) + shape.size / 2.0
			body.add_child(cs)
	# Décor
	var bg := Node2D.new()
	bg.set_script(BackgroundScript)
	bg.main = self
	add_child(bg)
	var art := Node2D.new()
	art.set_script(LevelArtScript)
	art.main = self
	add_child(art)
	var amb := Node2D.new()
	amb.set_script(preload("res://scripts/ambience.gd"))
	amb.main = self
	add_child(amb)
	# Grilles de l'arène
	entry_gate = _make_gate(gate_cells["Y"], false)
	exit_gate = _make_gate(gate_cells["X"], true)

func _make_gate(cells: Array, closed: bool):
	if cells.is_empty():
		return null
	var r := Rect2(Vector2(cells[0] * TILE), Vector2(TILE, TILE))
	for c in cells:
		r = r.merge(Rect2(Vector2(c * TILE), Vector2(TILE, TILE)))
	var g := StaticBody2D.new()
	g.set_script(GateScript)
	g.rect = Rect2(Vector2(r.position.x + 8, r.position.y), Vector2(16, r.size.y))
	g.start_closed = closed
	add_child(g)
	return g

func _make_trap(kind: String, pos: Vector2, opts: Dictionary):
	var t := Node2D.new()
	t.set_script(TrapScript)
	t.main = self
	t.kind = kind
	t.position = pos
	for k in opts:
		t.set(k, opts[k])
	add_child(t)
	return t

func _make_platform(kind: String, pos: Vector2, sz: Vector2):
	var p := AnimatableBody2D.new()
	p.set_script(PlatformScript)
	p.main = self
	p.kind = kind
	p.size = sz
	p.position = pos
	add_child(p)
	return p

# vrai si le bloc fragile en x commence un groupe (groupes de 2 depuis le début de la rangée de C)
func _crumble_start(row: String, x: int) -> bool:
	var s := x
	while s > 0 and row[s - 1] == "C":
		s -= 1
	return (x - s) % 2 == 0

func _cell_feet(x: int, y: int, height: float) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - height / 2.0 - 1.0)

const ShadeScript = preload("res://scripts/shade.gd")
var shade_node = null
func _spawn_shade() -> void:
	var sh: Dictionary = GameState.prog.get("shade", {})
	if sh.is_empty() or GameState.mode != "descent" or int(sh["palier"]) != GameState.palier or int(sh["step"]) != GameState.step:
		return
	var e := CharacterBody2D.new()
	e.set_script(ShadeScript)
	e.main = self
	e.geo_kept = int(sh["geo"])
	e.position = Vector2(float(sh["x"]), float(sh["y"]) - 20.0)
	add_child(e)
	shade_node = e

func _spawn_everything() -> void:
	for y in map_size.y:
		var row: String = MAP[y]
		for x in row.length():
			match row[x]:
				"P":
					player = CharacterBody2D.new()
					player.set_script(PlayerScript)
					player.main = self
					player.position = _cell_feet(x, y, 34)
					add_child(player)
					player.geo = GameState.prog["geo"]
					player.can_dash = GameState.prog["can_dash"]
					player.apply_equipment()
					player.hp = player.max_hp
				"B":
					bench_pos = _cell_feet(x, y, 34)
					benches.append(bench_pos)
					bench = _make_prop("bench", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.5), 3.0)
				"D":
					dash_orb = _make_prop("orb", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), Color(0.5, 0.85, 1.0), 2.5)
				"1", "2", "3", "4", "5", "6", "7", "8":
					var id: int = (row[x] as String).to_int() - 1
					if not GameState.owns(id):
						var cp = _make_prop("charm", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), GameState.charm(id)["color"], 1.6)
						cp.color = GameState.charm(id)["color"]
						cp.charm_id = id
						pickups.append([cp, "charm", id])
				"*":
					var cid := _random_charm(x)
					if cid >= 0:
						var rp = _make_prop("charm", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), GameState.charm(cid)["color"], 1.6)
						rp.color = GameState.charm(cid)["color"]
						rp.charm_id = cid
						pickups.append([rp, "charm", cid])
				"N":
					var key := "%d-%d-%d:%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if not GameState.is_collected(key):
						var np = _make_prop("notch", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), Color(1.0, 0.9, 0.6), 1.6)
						pickups.append([np, "notch", key])
				"T":
					var sign_list: Array = GameState.current_level().get("signs", [])
					var sp = _make_prop("sign", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.85, 0.6), 1.4)
					var data: Dictionary = sign_list[signs.size()] if signs.size() < sign_list.size() else {"text": "..."}
					signs.append([sp, data, false])
				"m":
					enemy_spawns.append([DummyScript, _cell_feet(x, y, 44), null, false])
				"M":
					var mp = _make_prop("merchant", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.5), 2.5)
					interactables.append([mp, "merchant"])
				"W":
					_make_platform("breakable", Vector2(x * TILE, y * TILE), Vector2(TILE, TILE))
				"$":
					var gkey := "%d-%d-%d$%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if not GameState.is_collected(gkey):
						var cp2 = _make_prop("cache", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.85, 0.4), 1.8)
						pickups.append([cp2, "geo", gkey])
				"S":
					challenge_start = _make_prop("challenge", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.75, 0.35), 2.0)
				"G":
					challenge_goal = _make_prop("flag", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.75, 0.35), 2.0)
				"F", "J", "I":
					# habitants du Sanctuaire : arrivent au fil des paliers terminés
					var npc: String = {"F": "smith", "J": "cartographer", "I": "elder"}[row[x]]
					var need: int = {"smith": 1, "cartographer": 2, "elder": 3}[npc]
					if GameState.record >= need:
						var np2 = _make_prop(npc, Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.55), 2.0)
						interactables.append([np2, npc])
				"t":
					# la tailleuse (garde-robe) ; pendant l'évènement de Noël : sapin, cadeau et guirlandes
					var tp = _make_prop("tailor", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.6), 2.0)
					interactables.append([tp, "tailor"])
					var ev: String = GameState.CosmeticsScript.current_event()
					if ev != "":
						var sp2 = _make_prop("fete", Vector2((x + 7.2) * TILE, (y + 1) * TILE), Color(1.0, 0.85, 0.5), 2.4)
						sp2.event = ev
						for ch in sp2.get_children():
							if ch is PointLight2D:
								ch.energy = 0.3      # décor de fête : lumière douce
						sp2.lit = not GameState.cos.gift_open(ev)
						interactables.append([sp2, "gift"])
						var gl = _make_prop("garland", Vector2(TILE, 6 * TILE + 6.0), Color(1.0, 0.8, 0.5), 0.1)
						gl.event = ev
						gl.charm_id = (map_size.x - 2) * TILE
						gl.z_index = -1
				"R":
					var rp2 = _make_prop("altar", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.4, 0.35), 2.2)
					interactables.append([rp2, "altar"])
				"Z":
					# totem à fléchettes : tire vers le côté le plus dégagé
					var dl := 0
					while x - dl - 1 > 0 and row[x - dl - 1] != "#":
						dl += 1
					var dr := 0
					while x + dr + 1 < row.length() - 1 and row[x + dr + 1] != "#":
						dr += 1
					_make_trap("dart", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), {"dir": 1.0 if dr >= dl else -1.0})
				"U":
					var fy := y + 1
					while fy < map_size.y - 1 and not solid.has(Vector2i(x, fy)):
						fy += 1
					_make_trap("blade", Vector2(x * TILE + TILE / 2.0, y * TILE), {"floor_y": float(fy * TILE)})
				"V":
					_make_trap("stalactite", Vector2(x * TILE + TILE / 2.0, y * TILE), {})
				"H":
					var xe := x
					while xe + 1 < row.length() and row[xe + 1] != "#":
						xe += 1
					var mv = _make_platform("mover", Vector2(x * TILE, y * TILE), Vector2(3 * TILE, 16))
					mv.x_min = x * TILE
					mv.x_max = (xe + 1) * TILE - 3 * TILE
				"C":
					# blocs fragiles groupés par deux
					if _crumble_start(row, x):
						var n2 := 2 if x + 1 < row.length() and row[x + 1] == "C" else 1
						_make_platform("crumble", Vector2(x * TILE, y * TILE), Vector2(n2 * TILE, TILE))
				"A":
					var ap = _make_prop("arsenal", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.7, 0.4), 2.2)
					interactables.append([ap, "arsenal"])
				"L":
					var lp = _make_prop("elevator", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(0.6, 0.85, 1.0), 3.0)
					interactables.append([lp, "elevator"])
				"O":
					exit_door = _make_prop("door", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), PropScript.door_color(String(pal.get("id", ""))), 3.5)
				"E":
					shrine = _make_prop("shrine", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.85, 0.55), 4.0)
				"c":
					enemy_spawns.append([CrawlerScript, _cell_feet(x, y, 22), null, _roll_elite(x, y)])
				"f":
					enemy_spawns.append([FlyerScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				"s":
					enemy_spawns.append([SpitterScript, _cell_feet(x, y, 28), null, _roll_elite(x, y)])
				"h":
					enemy_spawns.append([HopperScript, _cell_feet(x, y, 22), null, _roll_elite(x, y)])
				"g":
					enemy_spawns.append([GuardScript, _cell_feet(x, y, 30), null, _roll_elite(x, y)])
				"b":
					enemy_spawns.append([BomberScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				"l":
					enemy_spawns.append([LancerScript, _cell_feet(x, y, 40), null, _roll_elite(x, y)])
				"w":
					enemy_spawns.append([WeaverScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				"r":
					enemy_spawns.append([WraithScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				"K", "Q":
					var bid: String = level.get("boss_id", "abbesse" if row[x] == "Q" else "gardien")
					var scripts := {"reine": BossQueen, "colosse": BossColossus, "ver": BossWorm, "chevalier": BossKnight, "ombre": BossLantern,
						"cerbere": BossCerberus, "centaure": BossCentaur, "oeil": BossEye}
					var heights := {"reine": 62, "colosse": 112, "ver": 54, "chevalier": 72, "ombre": 76, "cerbere": 84, "centaure": 96, "oeil": 96}
					boss = CharacterBody2D.new()
					boss.set_script(scripts.get(bid, BossScript))
					if not scripts.has(bid):
						boss.variant = 2 if bid == "abbesse" else 1
					boss.main = self
					boss.home = _cell_feet(x, y, heights.get(bid, 64))
					boss.position = boss.home
					add_child(boss)
	respawn_enemies()
	if player:
		move_child(player, get_child_count() - 1)
		respawn_pos = player.position

var _charms_in_level := []

# Version élite (plus forte, attaque spéciale) selon la difficulté — reproductible
func _roll_elite(x: int, y: int) -> bool:
	if GameState.is_tutorial():
		return false
	var r := RandomNumberGenerator.new()
	r.seed = int(level.get("seed", 0)) + x * 977 + y * 31
	return r.randf() < GameState.elite_chance()

# Emblème tiré au hasard parmi ceux pas encore possédés (reproductible pour un même niveau)
func _random_charm(x: int) -> int:
	var free := []
	for id in GameState.charm_count():
		if not GameState.owns(id) and not _charms_in_level.has(id):
			free.append(id)
	if free.is_empty():
		return -1
	var r := RandomNumberGenerator.new()
	r.seed = int(level.get("seed", 0)) + x * 131
	var id: int = free[r.randi_range(0, free.size() - 1)]
	_charms_in_level.append(id)
	return id

func _make_prop(kind: String, pos: Vector2, light_color: Color, light_scale: float):
	var p := Node2D.new()
	p.set_script(PropScript)
	p.kind = kind
	p.position = pos
	add_child(p)
	p.add_child(make_light(light_color, light_scale, 0.9, Vector2(0, -24) if kind != "orb" else Vector2.ZERO))
	return p

func respawn_enemies() -> void:
	for s in enemy_spawns:
		if s[2] == null or not is_instance_valid(s[2]):
			var e := CharacterBody2D.new()
			e.set_script(s[0])
			e.main = self
			e.elite = s[3]
			e.position = s[1]
			add_child(e)
			s[2] = e

func make_light(color: Color, sc: float, energy: float, offset: Vector2 = Vector2.ZERO) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = light_tex
	l.color = color
	l.texture_scale = sc
	l.energy = energy
	l.position = offset
	return l

func _setup_camera_and_fx() -> void:
	var mod := CanvasModulate.new()
	mod.color = pal["ambient"]
	if GameState.curse == "dark" and GameState.mode == "descent":
		mod.color = (pal["ambient"] as Color).darkened(0.65)
		_make_darkness()
	add_child(mod)
	_make_vignette()
	camera = Camera2D.new()
	camera.zoom = Vector2(Settings.zoom, Settings.zoom)
	Settings.changed.connect(func():
		camera.zoom = Vector2(Settings.zoom, Settings.zoom)
		for n in get_children():
			if n is Node2D and n.get_script() == LevelArtScript:
				n.redraw_all())
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_size.x * TILE
	camera.limit_bottom = map_size.y * TILE
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)
	camera.global_position = player.global_position
	camera.make_current()
	# Poussière lumineuse qui flotte dans l'air
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700, 420)
	var ddir: Vector2 = pal.get("dust_dir", Vector2(0.3, -1))
	dust.direction = ddir
	dust.spread = 60.0
	dust.gravity = Vector2(0, 6.0 * signf(ddir.y))
	dust.initial_velocity_min = 4.0
	dust.initial_velocity_max = 14.0
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.5
	dust.color = pal["dust"]
	camera.add_child(dust)
	player.add_child(make_light(pal.get("light", Color(1.0, 0.85, 0.6)), 1.3 if GameState.curse == "dark" and GameState.mode == "descent" else 2.2, 1.0 if GameState.curse == "dark" else 0.85, Vector2(0, -10)))
	var pet := Node2D.new()
	pet.set_script(preload("res://scripts/pet.gd"))
	pet.main = self
	add_child(pet)

# ---------------------------------------------------------------- boucle
# ---------------------------------------------------------------- salles spéciales
func _update_rooms(delta: float) -> void:
	if player == null or player.dead:
		return
	var pp: Vector2 = player.global_position
	# défi chronométré
	if challenge_start and not challenge_done:
		if challenge_t <= 0.0 and pp.distance_to(challenge_start.position + Vector2(0, -20)) < 40.0:
			challenge_t = 13.0
			challenge_start.lit = true
			Audio.sfx("door", 0.0, 2.0)
			show_message("Défi : atteins le drapeau avant la fin du temps !", 2.5)
		elif challenge_t > 0.0:
			challenge_t -= delta
			if challenge_goal and pp.distance_to(challenge_goal.position + Vector2(0, -20)) < 44.0:
				challenge_t = 0.0
				challenge_done = true
				challenge_goal.lit = true
				var reward := roundi((40 + 15 * GameState.palier) * GameState.geo_mult())
				player.geo += reward
				spawn_burst(challenge_goal.position, Color(1.0, 0.85, 0.4), 40, 260.0, 0.0)
				Audio.sfx("pickup", 0.0, 3.0)
				show_message(tr("Défi réussi ! +%d éclats") % reward, 3.0)
				Achievements.unlock("room")
			elif challenge_t <= 0.0:
				challenge_t = 0.0
				challenge_done = true
				show_message("Défi raté… le temps est écoulé.", 2.5)
	# arène d'élites
	if altar_state == "fight":
		altar_foes = altar_foes.filter(func(e): return is_instance_valid(e) and not e.dead)
		if altar_foes.is_empty():
			altar_state = "done"
			var reward2 := roundi((50 + 15 * GameState.palier) * GameState.geo_mult())
			player.geo += reward2
			var cid := _random_charm(int(pp.x))
			if cid >= 0:
				var rp = _make_prop("charm", pp + Vector2(0, -60), GameState.charm(cid)["color"], 1.6)
				rp.color = GameState.charm(cid)["color"]
				rp.charm_id = cid
				pickups.append([rp, "charm", cid])
			Audio.sfx("pickup", 0.0, 3.0)
			show_message(tr("Arène vaincue ! +%d éclats") % reward2, 3.0)
			Achievements.unlock("room")

func _start_altar(prop) -> void:
	if altar_state != "":
		return
	altar_state = "fight"
	prop.lit = true
	shake(10)
	Audio.sfx("ult", 0.0, -4.0)
	var pool := [GuardScript, LancerScript, HopperScript, CrawlerScript, SpitterScript]
	for i in 3:
		var e := CharacterBody2D.new()
		e.set_script(pool[(GameState.palier + i * 2) % pool.size()])
		e.main = self
		e.elite = true
		e.position = prop.position + Vector2(-220 + i * 220, -40)
		add_child(e)
		altar_foes.append(e)
		spawn_burst(e.position, Color(1.0, 0.35, 0.3), 16, 180.0, 0.0)

func is_explored(x: int, y: int) -> bool:
	var i := y * map_size.x + x
	return i >= 0 and i < explored.size() and explored[i] == 1

func _reveal() -> void:
	var c := Vector2i(floori(player.global_position.x / TILE), floori(player.global_position.y / TILE))
	for y in range(maxi(c.y - 9, 0), mini(c.y + 10, map_size.y)):
		for x in range(maxi(c.x - 13, 0), mini(c.x + 14, map_size.x)):
			explored[y * map_size.x + x] = 1

# Malédiction « Obscurité » : voile noir sur tout l'écran (décor compris), sauf un petit
# cercle de lumière autour du héros. Indépendant de la difficulté.
var dark_rect: ColorRect
const DARK_SHADER := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5);
uniform float radius = 150.0;
uniform float soft = 110.0;
uniform vec2 screen = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * screen;
	float d = distance(p, center);
	float a = smoothstep(radius, radius + soft, d);
	COLOR = vec4(0.0, 0.0, 0.02, a * 0.94);
}
"""
const VIGNETTE_SHADER := """
shader_type canvas_item;
void fragment() {
	vec2 q = SCREEN_UV - 0.5;
	q.x *= 1.25;
	float d = length(q);
	COLOR = vec4(0.0, 0.0, 0.01, smoothstep(0.42, 0.95, d) * 0.55);
}
"""
# Vignette : bords de l'écran assombris (profondeur, ambiance)
func _make_vignette() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 4
	add_child(cl)
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	r.material = mat
	cl.add_child(r)

func _make_darkness() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5          # au-dessus du niveau, sous le HUD (10) et les menus
	add_child(cl)
	dark_rect = ColorRect.new()
	dark_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = DARK_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	dark_rect.material = mat
	cl.add_child(dark_rect)

func _update_darkness() -> void:
	if dark_rect == null or player == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var mat: ShaderMaterial = dark_rect.material
	var sp: Vector2 = player.get_global_transform_with_canvas().origin + Vector2(0, -10) * camera.zoom.x
	mat.set_shader_parameter("center", sp)
	mat.set_shader_parameter("screen", vp)
	mat.set_shader_parameter("radius", 120.0 * camera.zoom.x)
	mat.set_shader_parameter("soft", 90.0 * camera.zoom.x)

var clock := 0.0   # temps de jeu (suit la vitesse du jeu et la pause)

# Ce qui est loin de l'écran est mis en sommeil (ni logique, ni redessin) : sans ça, tous les
# ennemis, pièges et objets du niveau tournaient en permanence, même à l'autre bout de la carte.
var _sleep_t := 0.0

func _update_sleep() -> void:
	var view: Vector2 = get_viewport_rect().size / maxf(camera.zoom.x, 0.1)
	var half := view / 2.0 + Vector2(420.0, 320.0)
	var c: Vector2 = camera.global_position
	for n in get_tree().get_nodes_in_group("sleepy"):
		if not is_instance_valid(n) or (n.get("is_boss") == true):
			continue
		var d: Vector2 = (n.global_position - c).abs()
		var far := d.x > half.x or d.y > half.y
		var want := Node.PROCESS_MODE_DISABLED if far else Node.PROCESS_MODE_INHERIT
		if n.process_mode != want:
			n.process_mode = want

func _process(delta: float) -> void:
	if not get_tree().paused:
		clock += delta
	_update_darkness()
	_reveal_t -= delta
	_update_rooms(delta)
	if GameState.mode in ["descent", "rush"] and not get_tree().paused:
		Achievements.run["time"] = float(Achievements.run.get("time", 0.0)) + delta
	if player and player.geo >= 1000:
		Achievements.unlock("rich")
	if _reveal_t <= 0.0 and player:
		_reveal_t = 0.15
		_reveal()
	if player == null:
		return
	_sleep_t -= delta
	if _sleep_t <= 0.0:
		_sleep_t = 0.2
		_update_sleep()
	# Caméra : suit le joueur, regarde un peu devant lui
	camera.global_position = player.global_position + Vector2(player.facing * 50.0, -40.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	shake_amt = move_toward(shake_amt, 0.0, delta * 40.0)
	flash = move_toward(flash, 0.0, delta * 3.0)

	var pp: Vector2 = player.global_position
	# Marchand et ascenseur (hub)
	interact_hint = ""
	for it in interactables:
		if pp.distance_to(it[0].position + Vector2(0, -20)) < 60.0 and not player.dead:
			var verbs := {"merchant": "parler au marchand", "arsenal": "ouvrir l'arsenal", "elevator": "appeler l'ascenseur",
				"altar": "réveiller l'autel (3 élites)", "smith": "parler à la forgeronne", "cartographer": "parler au cartographe", "elder": "écouter l'ancien",
				"tailor": "ouvrir la garde-robe", "gift": "ouvrir ton cadeau"}
			if it[1] == "altar" and altar_state != "":
				continue
			if it[1] == "gift" and not it[0].lit:
				continue
			interact_hint = tr("{up|1} : %s") % tr(verbs[it[1]])
			if Input.is_action_just_pressed("up") and player.is_on_floor() and not get_tree().paused:
				# écran d'entrée animé : battants de bois qui s'ouvrent sur la boutique
				var shop_names := {"merchant": ["shop", "Marchand"], "arsenal": ["arsenal", "Arsenal"], "smith": ["smith", "Forgeronne"],
					"cartographer": ["cartographer", "Cartographe"], "elder": ["elder", "Ancien"], "tailor": ["tailor", "Tailleuse"]}
				if shop_names.has(it[1]):
					LoadingScript.shop(get_tree(), shop_names[it[1]][0], tr(shop_names[it[1]][1]))
				if it[1] == "merchant":
					hub_ui.open_shop()
				elif it[1] == "arsenal":
					hub_ui.open_arsenal()
				elif it[1] == "altar":
					_start_altar(it[0])
				elif it[1] in ["smith", "cartographer", "elder"]:
					hub_ui.open_npc(it[1])
				elif it[1] == "tailor":
					hub_ui.open_wardrobe()
				elif it[1] == "gift":
					_open_gift(it[0])
				else:
					hub_ui.open_elevator()
	# Banc le plus proche
	for bp in benches:
		if pp.distance_to(bp) < pp.distance_to(bench_pos):
			bench_pos = bp
	# Banc
	if not player.dead and not player.sitting and pp.distance_to(bench_pos) < 48 and player.is_on_floor() and Input.is_action_just_pressed("up"):
		player.sit(bench_pos)
		respawn_pos = bench_pos
		respawn_enemies()
		show_message("Vous vous reposez. Santé restaurée.", 2.5)
	# Orbe de Ruée
	if dash_orb and is_instance_valid(dash_orb) and pp.distance_to(dash_orb.position) < 36:
		player.can_dash = true
		spawn_burst(dash_orb.position, Color(0.6, 0.9, 1.0), 40, 260.0)
		dash_orb.queue_free()
		dash_orb = null
		shake(8)
		show_message("Cape d'Ombre-Vive obtenue !\n{dash} pour faire une Ruée", 4.0)
	# Déclenchement du boss
	if boss and not boss_started and not boss_dead and entry_gate and pp.x > entry_gate.rect.end.x + TILE * 3:
		boss_started = true
		entry_gate.set_closed(true)
		boss.wake()
		Audio.play_boss(level.get("boss_music", "res://music/boss_gardien_du_puits.ogg"))
		shake(10)
		show_message(tr(boss.boss_name).to_upper(), 3.0)
	# Panneaux du tutoriel
	sign_text = ""
	for sg in signs:
		if pp.distance_to(sg[0].position + Vector2(0, -20)) < 70.0:
			sign_text = tr(sg[1]["text"])   # les {action} sont dessinés en icônes par le HUD
			if not sg[2]:
				sg[2] = true
				sg[0].lit = true
				if sg[1].get("fill_ult", false):
					player.ult = player.ULT_MAX
			break
	# Emblèmes et encoches à ramasser
	for pk in pickups.duplicate():
		var prop = pk[0]
		if is_instance_valid(prop) and pp.distance_to(prop.position) < 34:
			if pk[1] == "geo":
				var amount := roundi((40 + 15 * GameState.palier) * GameState.geo_mult())
				player.geo += amount
				GameState.prog["collected"].append(pk[2])     # cachette vidée
				Audio.sfx("pickup", 0.0)
				show_message(tr("Trésor caché : +%d éclats !") % amount, 3.0)
				Achievements.unlock("room")
			elif pk[1] == "charm":
				GameState.add_charm(pk[2])
				Audio.sfx("pickup", 0.0)
				show_message(tr("Emblème obtenu : %s\nÉquipe-le depuis l'inventaire ({inventory|1}) en te reposant sur un banc.") % tr(GameState.charm(pk[2])["name"]), 4.5)
			else:
				GameState.add_notch(pk[2])
				Audio.sfx("pickup", 0.0)
				show_message(tr("Encoche d'emblème obtenue !\nEncoches : %d") % GameState.prog["notches"], 3.5)
			spawn_burst(prop.position, Color(1.0, 0.92, 0.65), 30, 220.0, 0.0)
			shake(6)
			prop.queue_free()
			pickups.erase(pk)
	# Passage vers le niveau suivant
	if exit_door and not leaving and pp.distance_to(exit_door.position + Vector2(0, -20)) < 40:
		leaving = true
		show_message("…", 1.0)
		spawn_burst(exit_door.position + Vector2(0, -30), PropScript.door_color(String(pal.get("id", ""))), 40, 200.0, -50.0)
		await get_tree().create_timer(0.6).timeout
		Audio.sfx("door", 0.0)
		GameState.go_next_level(player)
		return
	# Sanctuaire = fin
	if shrine and not won and pp.distance_to(shrine.position) < 60:
		won = true
		spawn_burst(shrine.position + Vector2(0, -40), Color(1.0, 0.9, 0.6), 60, 300.0)
		Audio.play_boss("res://music/sanctuaire.ogg")
		Audio.sfx("door", 0.0)
		show_message(tr("Vous avez rallumé la Lanterne des Profondeurs.\nPartie n° %d terminée — merci d'avoir joué !  ({pause|1} : nouvelle partie)") % GameState.run_seed, 9999.0)

# ---------------------------------------------------------------- utilitaires
# Remplace {action} par les touches actuellement réglées
func fmt(text: String) -> String:
	var out := text
	for a in Controls.ACTIONS:
		out = out.replace("{%s}" % a, Controls.label_all(a))
	out = out.replace("{pause}", Controls.pause_label())
	return out

func is_solid_at(p: Vector2) -> bool:
	return solid.has(Vector2i(floori(p.x / TILE), floori(p.y / TILE)))

# Y a-t-il de la roche entre deux points ? (on ignore les extrémités : les corps touchent le sol)
func wall_between(a: Vector2, b: Vector2) -> bool:
	var d := b - a
	var n := int(ceil(d.length() / 8.0))
	for i in range(1, n):
		var q := a + d * (float(i) / n)
		if q.distance_to(a) < 14.0 or q.distance_to(b) < 14.0:
			continue
		if is_solid_at(q):
			return true
	return false

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount * Settings.shake)
	# Vibration de la manette (XInput) proportionnelle à la secousse
	Controls.rumble(amount / 20.0, amount / 16.0 if amount >= 8.0 else 0.0, 0.08 + amount / 80.0)

func hit_stop(duration: float) -> void:
	if not Settings.hitstop:
		return
	Engine.time_scale = 0.05 * Settings.speed()
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = Settings.speed()

func show_message(text: String, duration: float = 2.5) -> void:
	if hud:
		hud.message = tr(text)
		hud.message_t = duration

var _spark: Texture2D
func _spark_tex() -> Texture2D:
	if _spark == null:
		_spark = DU.radial_texture(32)
	return _spark

func spawn_burst(pos: Vector2, color: Color, amount: int = 12, speed: float = 160.0, grav: float = 300.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.7
	p.spread = 180.0
	p.gravity = Vector2(0, grav)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.26
	p.texture = _spark_tex()
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.lightened(0.3), 1.0))
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

const FxScript = preload("res://scripts/fx.gd")
func spawn_fx(kind: String, pos: Vector2, color := Color(1, 1, 1), dir := Vector2.RIGHT, facing := 1) -> void:
	var f := Node2D.new()
	f.set_script(FxScript)
	f.main = self
	f.kind = kind
	f.color = color
	f.dir = dir
	f.facing = facing
	f.seed_v = randi()
	f.position = pos
	add_child(f)

# ---------------------------------------------------------------- événements
func on_enemy_killed(e, geo: int) -> void:
	player.geo += roundi(geo * GameState.geo_mult())
	Achievements.stat("kills")
	Achievements.on_kill(e.elite and not e.is_boss)
	if player.plunge_kill_t > 0.0:
		Achievements.unlock("plunge")
	Audio.sfx("kill")
	spawn_burst(e.global_position, Color(0.95, 0.9, 0.75), 18, 220.0)
	spawn_fx("death", e.global_position, e.fx_color() if e.has_method("fx_color") else Color(0.7, 0.65, 0.75))
	if geo > 0:
		spawn_fx("shards", e.global_position, Color(0.75, 0.85, 1.0), Vector2(clampi(geo / 2 + 1, 1, 8), 0))
	shake(4)

func on_player_hurt() -> void:
	Achievements.on_hurt()
	Audio.sfx("hurt")
	shake(12)
	hit_stop(0.12)
	spawn_burst(player.global_position, Color(0.1, 0.08, 0.15), 16, 200.0)

func on_player_died() -> void:
	show_message("Vous avez sombré...", 2.0)
	spawn_burst(player.global_position, Color(0.15, 0.1, 0.2), 40, 260.0)
	await get_tree().create_timer(1.6).timeout
	# En descente : retour au hub, le butin de la descente est perdu
	if not GameState.is_tutorial():
		Audio.stop_music()
		GameState.die_in_descent(player.geo, respawn_pos if player.global_position.y > map_size.y * TILE else player.global_position)
		return
	if boss_started and not boss_dead:
		boss_started = false
		boss.reset()
		entry_gate.set_closed(false)
		Audio.resume_level()
	player.geo = player.geo / 2
	player.respawn(respawn_pos)
	respawn_enemies()

# Cadeau de la fête en cours, au Sanctuaire : une fois par an, le couvre-chef de la fête et quelques éclats.
func _open_gift(tree) -> void:
	var ev: String = tree.event
	tree.lit = false
	GameState.cos.mark_gift(ev)
	var item_id := String(GameState.CosmeticsScript.EVENTS[ev]["gift"])
	var got: bool = Achievements.give_cosmetic(item_id)
	player.geo += 50
	GameState.prog["geo"] = player.geo
	GameState.snapshot = GameState.prog.duplicate(true)
	GameState.save_game()
	if ev == "noel":
		Achievements.unlock("gift")
	if GameState.cos.gifts.size() >= GameState.CosmeticsScript.EVENTS.size():
		Achievements.unlock("calendar")
	spawn_burst(tree.position + Vector2(33, -20), Color(1.0, 0.9, 0.5), 40, 260.0)
	Audio.sfx("pickup", 0.0)
	show_message((tr("Cadeau : %s et 50 éclats !") % tr(GameState.cos.item(item_id)["name"])) if got else tr("Cadeau : 50 éclats !"), 3.5)

# Butin rare : chaque boss a une chance de laisser son cosmétique (une fois obtenu, plus de tirage).
func _boss_cosmetic() -> void:
	for item_id in GameState.cos.for_boss(String(level.get("boss_id", ""))):
		if not GameState.cos.has(item_id) and randf() < GameState.cos.BOSS_DROP_CHANCE:
			if Achievements.give_cosmetic(item_id):
				Achievements.unlock("trophy")

func on_boss_killed() -> void:
	boss_dead = true
	_boss_cosmetic()
	for m in minions:
		if is_instance_valid(m) and not m.dead:
			m.die()
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile:
			pr.pop()
	player.geo += roundi((60 + 20 * GameState.palier) * GameState.geo_mult())
	spawn_burst(boss.global_position, Color(1.0, 0.7, 0.4), 70, 380.0)
	shake(18)
	hit_stop(0.25)
	if entry_gate:
		entry_gate.set_closed(false)
	if exit_gate:
		exit_gate.set_closed(false)
	Audio.resume_level()
	var bname: String = boss.boss_name
	if level.get("boss_id", "") in GameState.FINALS and GameState.mode == "descent":
		Achievements.unlock("final")
		Achievements.counters["final_" + str(level["boss_id"])] = true
		Achievements.save()
		if GameState.FINALS.all(func(fid): return Achievements.counters.get("final_" + fid, false)):
			Achievements.unlock("finals4")
		await get_tree().create_timer(2.5).timeout
		play_ending(level["boss_id"])
		return
	var fem := bname.begins_with("La ") or bname.begins_with("L'Abbesse")
	show_message(tr("%s est vaincue.\nLa voie est ouverte." if fem else "%s est vaincu.\nLa voie est ouverte.") % tr(bname), 4.0)

# Animation de fin (après un boss final) ; le jeu continue ensuite (paliers sans fin)
func play_ending(boss_id: String) -> void:
	var e := CanvasLayer.new()
	e.set_script(EndingScript)
	e.main = self
	e.boss_id = boss_id
	add_child(e)

func on_parry(pos: Vector2) -> void:
	Audio.sfx("parry")
	spawn_burst(pos, Color(1, 1, 1), 14, 260.0, 0.0)
	shake(7)
	hit_stop(0.09)
	Controls.rumble(0.8, 0.3, 0.12)

func on_ultimate_charge(p) -> void:
	var ul: Dictionary = GameState.cos.look("ult")
	spawn_burst(p.global_position, ul["c2"] if GameState.cos.eq("ult") == "ult_eclipse" else ul["c"], 20, 140.0, -200.0)
	Controls.rumble(0.3, 0.0, ULT_RUMBLE)

const ULT_RADIUS := 260.0
const ULT_DAMAGE := 8
const ULT_RUMBLE := 0.5

# Onde de choc de l'ultime : gros dégâts à tout ce qui est dans le rayon, détruit les spores.
func ultimate_blast(pos: Vector2) -> void:
	Audio.sfx("ult", 0.0)
	var ring := Node2D.new()
	ring.set_script(RingScript)
	var ul: Dictionary = GameState.cos.look("ult")
	ring.radius = ULT_RADIUS
	ring.position = pos
	ring.style = GameState.cos.eq("ult")
	ring.c1 = ul["c"]
	ring.c2 = ul["c2"]
	add_child(ring)
	flash = 1.0
	shake(18)
	hit_stop(0.12)
	spawn_burst(pos, ul["c2"] if ring.style == "ult_eclipse" else ul["c"], 60, 420.0, 0.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var c: Vector2 = e.get_rect().get_center()
		if c.distance_to(pos) <= ULT_RADIUS + e.size.x / 2.0:
			e.take_hit(ULT_DAMAGE, (c - pos).normalized())
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile and pr.global_position.distance_to(pos) <= ULT_RADIUS:
			pr.pop()

# Journal des dégâts infligés (coin de l'écran)
const ENEMY_NAMES := {"crawler.gd": "Rampant", "flyer.gd": "Volant", "spitter.gd": "Cracheur", "hopper.gd": "Sauteur",
	"guard.gd": "Garde", "bomber.gd": "Bulbe", "weaver.gd": "Tisseuse", "lancer.gd": "Lancier", "wraith.gd": "Spectre",
	"dummy.gd": "Mannequin", "shade.gd": "Ombre"}
func on_damage_dealt(e, dmg: int) -> void:
	if player and e.get_script() != DummyScript:
		player.combat_t = 0.0
	if dmg <= 0 or hud == null:
		return
	var n := ""
	if "boss_name" in e:
		n = tr(e.boss_name)
	else:
		n = tr(ENEMY_NAMES.get(e.get_script().resource_path.get_file(), "Ennemi"))
	if e.elite:
		n += tr(" (élite)")
	var kind: String = player.attack_kind if player.attack_t > 0.0 or player.thrust_t > 0.0 else "autre"
	if player.last_crit_t > 0.0:
		kind = "crit"
		Achievements.on_crit()
	Achievements.stat("damage", dmg)
	hud.add_damage(dmg, n, kind, e.hp <= 0)

# Coquille Épineuse : riposte quand le joueur est touché
func thorns_burst(pos: Vector2) -> void:
	spawn_burst(pos, Color(0.6, 0.85, 0.5), 24, 300.0, 0.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get_rect().get_center().distance_to(pos) < 110.0:
			e.take_hit(3, (e.get_rect().get_center() - pos).normalized())

# opts : {"kind": "spore"/"rock"/"wave"/"acid"/"ember", "gravity": float, "radius": float, "life": float}
func spawn_projectile(pos: Vector2, vel: Vector2, opts: Dictionary = {}) -> void:
	var pr := Node2D.new()
	pr.set_script(ProjectileScript)
	pr.main = self
	pr.vel = vel
	pr.position = pos
	for k in opts:
		pr.set(k, opts[k])
	add_child(pr)
	pr.add_child(make_light(pr._color(), 0.6, 0.8))

# Pilier qui jaillit du sol en x (sol à floor_y) après un avertissement
func spawn_pillar(x: float, floor_y: float, delay: float = 0.0, opts: Dictionary = {}) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	if not is_instance_valid(self) or boss_dead:
		return
	var pl := Node2D.new()
	pl.set_script(PillarScript)
	pl.main = self
	pl.position = Vector2(x, floor_y)
	for k in opts:
		pl.set(k, opts[k])
	add_child(pl)

# Sbire invoqué par un boss (pas de réapparition au banc)
var minions := []
func spawn_minion(script, pos: Vector2) -> void:
	var alive := minions.filter(func(m): return is_instance_valid(m))
	minions = alive
	if minions.size() >= 4:
		return
	var e := CharacterBody2D.new()
	e.set_script(script)
	e.main = self
	e.position = pos
	add_child(e)
	minions.append(e)
	spawn_burst(pos, Color(0.9, 0.8, 0.4), 12, 160.0, 0.0)

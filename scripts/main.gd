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
var bg: Node2D          # arrière-plan en parallaxe
var vignette: ColorRect
const LevelArtScript = preload("res://scripts/level_art.gd")
const BackgroundScript = preload("res://scripts/background.gd")
const PropScript = preload("res://scripts/prop.gd")
const WinchScript = preload("res://scripts/winch.gd")
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
const MonkeyScript = preload("res://scripts/monkey.gd")
const MimicScript = preload("res://scripts/mimic.gd")
const MothScript = preload("res://scripts/moth.gd")
const MoleScript = preload("res://scripts/mole.gd")
const SlimeScript = preload("res://scripts/slime.gd")
const ScorpionScript = preload("res://scripts/scorpion.gd")
const AnglerScript = preload("res://scripts/angler.gd")
const PuffballScript = preload("res://scripts/puffball.gd")
const DrownedScript = preload("res://scripts/drowned.gd")
const TurtleScript = preload("res://scripts/turtle.gd")
const ImpScript = preload("res://scripts/imp.gd")
const TomeScript = preload("res://scripts/tome.gd")
const GolemScript = preload("res://scripts/golem.gd")
const SkeletonScript = preload("res://scripts/skeleton.gd")
const GoblinScript = preload("res://scripts/goblin.gd")
# Champions des biomes (mini-boss) : une version géante et coriace de la créature du biome
const CHAMPIONS := {
	"profondeurs": ["angler", "La Grande Baudroie"], "jardins": ["puffball", "La Vesse-Mère"],
	"citadelle": ["drowned", "Le Capitaine Noyé"], "cristal": ["turtle", "La Tortue Ancestrale"],
	"forge": ["imp", "Le Diablotin Forgeron"], "bibliotheque": ["tome", "Le Grimoire Interdit"],
	"glace": ["golem", "Le Golem du Glacier"], "ossuaire": ["skeleton", "Le Roi Squelette"],
	"ruche": ["flyer", "Le Bourdon Gardien"], "jungle": ["monkey", "Le Roi Singe"],
	"desert": ["scorpion", "Le Scorpion Empereur"], "antique": ["goblin", "Le Chef Gobelin"]}
const CHAMP_SCALE := 2.0
const CHAMP_AIR := ["angler", "tome", "flyer"]
var champ = null          # champion vivant (barre de vie en bas de l'écran)
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
var used_benches := {}     # bancs qui ont déjà soigné dans cette zone
var exit_gate
var enemy_spawns := []   # [script, position, node]
var boss_started := false
var boss_id := ""
var boss_t0 := 0.0          # début du combat (registres : meilleur temps)
var boss_hurt0 := 0         # coups reçus au début du combat (victoire sans coup reçu)
var arena_entry_pos := Vector2.ZERO   # où le héros est entré dans l'arène (filet de sécurité)
var boss_dead := false
var won := false
var shake_amt := 0.0
var light_tex: GradientTexture2D
var menu
var inventory
var scriptorium
var elder_ui                       # les Mémoires de l'Ancien (elder.gd)
const ScriptoriumScript = preload("res://scripts/scriptorium.gd")
var map_view
var challenge_start = null
var challenge_key := ""   # clés « déjà fait » des salles spéciales (refaire un palier ne les rejoue pas)
var altar_key := ""
var challenge_goal = null
var challenge_t := 0.0
var challenge_done := false
var altar_foes := []
var breakable_cells := {}   # case → dalle fissurée
var veiled := {}            # cases cachées sous un voile de roche (comptent comme roche pour l'ombrage)
var memory_cells := []      # cases des fragments de mémoire (chambres secrètes à voiler)
var levers := []          # salle des leviers : props « lever » (meta rune / ordre)
var lever_order := []     # runes dans l'ordre à tirer (montré sur la plaque)
var lever_done := []      # runes déjà tirées
var lever_gate            # herse du caveau
var lever_key := ""
var lever_reset_t := 0.0
var altar_state := ""     # "" / "fight" / "done"
var explored := PackedByteArray()   # cases découvertes (carte)
var _reveal_t := 0.0
const MapViewScript = preload("res://scripts/map_view.gd")
var signs := []     # [prop, données du panneau, déjà déclenché]
var sign_text := ""
var benches := []   # positions des bancs
var pal: Dictionary = {}
var level: Dictionary = {}
var winch_low := []    # pieds de corde (« ~ »)
var winch_top := []    # arrivées en haut (« u »)
var interactables := []   # [prop, "merchant"/"elevator"]
var interact_hint := ""
var hub_ui
var pickups := []   # [prop, "charm"/"notch", id ou clé]

func _ready() -> void:
	randomize()
	# au lancement, l'écran titre se dessine devant le Sanctuaire (et non le tutoriel)
	if GameState.show_title and GameState.mode == "tutorial":
		GameState.mode = "hub"
	level = GameState.current_level()
	MAP = level["map"]
	pal = level.get("palette", Biomes.all()[0]["pal"])
	RenderingServer.set_default_clear_color(pal["bg"])
	light_tex = DU.radial_texture()
	_build_level()
	_spawn_everything()
	_veil_secrets()
	_make_winches()
	_spawn_shade()
	_setup_camera_and_fx()
	apply_quality.call_deferred()
	Settings.changed.connect(apply_quality)
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
	scriptorium = CanvasLayer.new()
	scriptorium.set_script(ScriptoriumScript)
	scriptorium.main = self
	add_child(scriptorium)
	elder_ui = CanvasLayer.new()
	elder_ui.set_script(load("res://scripts/elder.gd"))
	elder_ui.main = self
	add_child(elder_ui)
	GameState.equipment_changed.connect(player.apply_equipment)
	hub_ui = CanvasLayer.new()
	hub_ui.set_script(HubUIScript)
	hub_ui.main = self
	add_child(hub_ui)
	if GameState.mode == "duel":
		hud.visible = false
		duel_hud = Control.new()
		duel_hud.set_script(preload("res://scripts/duel_hud.gd"))
		duel_hud.main = self
		duel_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
		duel_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(duel_hud)
		_duel_start_round.call_deferred()
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
	Audio.play_ambience("hub" if GameState.is_hub() else String(pal.get("id", "")))
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
	var gate_cells := {"Y": [], "X": [], "9": []}
	for y in h:
		var row: String = MAP[y]
		for x in w:
			var ch: String = row[x] if x < row.length() else "."
			match ch:
				"#":
					solid[Vector2i(x, y)] = true
				"^":
					spikes.append(Rect2(x * TILE + 3, y * TILE + 12, TILE - 6, TILE - 12))
				"Y", "X", "9":
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
	bg = Node2D.new()
	bg.set_script(BackgroundScript)
	bg.main = self
	add_child(bg)
	# troisième plan (étangs, rivières, fontaines…) entre l'arrière-plan et le décor
	if not GameState.is_hub():
		var mid := Node2D.new()
		mid.set_script(preload("res://scripts/midground.gd"))
		mid.main = self
		add_child(mid)
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
	if not gate_cells["9"].is_empty():
		var c0: Vector2i = gate_cells["9"][0]
		lever_key = "%d-%d-%d#%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, c0.x, c0.y]
		var solved := GameState.mode == "descent" and GameState.is_collected(lever_key)
		lever_gate = _make_gate(gate_cells["9"], not solved)
		var lr := RandomNumberGenerator.new()
		lr.seed = hash(lever_key)
		lever_order = [0, 1, 2]
		for i in range(2, 0, -1):
			var j := lr.randi_range(0, i)
			var tmp = lever_order[i]
			lever_order[i] = lever_order[j]
			lever_order[j] = tmp
		var top := 99999
		for c in gate_cells["9"]:
			top = mini(top, c.y)
		var plq = _make_prop("lever_plaque", Vector2(c0.x * TILE + TILE / 2.0, top * TILE - 4), Color(0.6, 0.85, 1.0), 0.9)
		plq.set_meta("order", lever_order)
		plq.lit = solved
		levers.append(plq)

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
				"~":
					winch_low.append(Vector2i(x, y))
				"u":
					winch_top.append(Vector2i(x, y))
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
					if GameState.carry_hp > 0 and GameState.mode == "descent" and GameState.step > 1:
						player.hp = mini(GameState.carry_hp, player.max_hp)
						# l'âme et l'ultime suivent aussi le héros à travers le portail
						if GameState.carry_soul >= 0:
							player.soul = mini(GameState.carry_soul, player.SOUL_MAX)
						if GameState.carry_ult >= 0:
							player.ult = mini(GameState.carry_ult, player.ULT_MAX)
					GameState.carry_hp = -1
					GameState.carry_soul = -1
					GameState.carry_ult = -1
					if GameState.mode == "duel":
						_duel_setup_player(player, 1)
				"@":
					# duel : le second joueur
					if GameState.mode == "duel":
						var p2 := CharacterBody2D.new()
						p2.set_script(PlayerScript)
						p2.main = self
						p2.pid = 2
						p2.position = _cell_feet(x, y, 34)
						add_child(p2)
						p2.can_dash = true
						p2.apply_equipment()
						_duel_setup_player(p2, 2)
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
					# emblème au hasard : une seule fois par emplacement (refaire le palier ne le fait pas
					# réapparaître sous la forme d'un autre emblème)
					var skey := "%d-%d-%d*%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					var cid := -1 if GameState.mode == "descent" and GameState.is_collected(skey) else _random_charm(x)
					if cid >= 0:
						var rp = _make_prop("charm", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), GameState.charm(cid)["color"], 1.6)
						rp.color = GameState.charm(cid)["color"]
						rp.charm_id = cid
						pickups.append([rp, "charm", cid, skey])
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
				"{":
					# Arène des Ombres : bannière aux lames croisées, entrée du duel local
					# (seulement si l'option « Arène des Ombres » est activée)
					arena_spot = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
					refresh_arena.call_deferred()
				"j":
					# le Scriptorium de Maître Plume (Sanctuaire, sur sa plateforme)
					var scp = _make_prop("scriptorium", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(0.85, 0.7, 0.55), 1.3)
					interactables.append([scp, "scriptorium"])
				"M":
					var mp = _make_prop("merchant", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.5), 2.5)
					interactables.append([mp, "merchant"])
				"W":
					breakable_cells[Vector2i(x, y)] = _make_platform("breakable", Vector2(x * TILE, y * TILE), Vector2(TILE, TILE))
				"$":
					var gkey := "%d-%d-%d$%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if not GameState.is_collected(gkey):
						var cp2 = _make_prop("cache", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.85, 0.4), 1.8)
						pickups.append([cp2, "geo", gkey])
				"|":
					# fragment de mémoire (chambre secrète) : l'Ancien en fait des souvenirs
					var mkey := "%d-%d-%d|%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if not GameState.is_collected(mkey):
						var mp2 = _make_prop("memory", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(0.75, 0.65, 1.0), 1.4)
						pickups.append([mp2, "memory", mkey])
					memory_cells.append(Vector2i(x, y))
				"S":
					challenge_start = _make_prop("challenge", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.75, 0.35), 2.0)
					challenge_key = "%d-%d-%d~%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if GameState.mode == "descent" and GameState.is_collected(challenge_key):
						challenge_done = true     # défi déjà réussi lors d'un passage précédent
						challenge_start.lit = true
				"0":
					var lv = _make_prop("lever", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(0.6, 0.85, 1.0), 0.6)
					lv.set_meta("rune", levers.filter(func(o): return o.kind == "lever").size())
					levers.append(lv)
					interactables.append([lv, "lever"])
				"G":
					challenge_goal = _make_prop("flag", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.75, 0.35), 2.0)
				"F", "J", "I", "]":
					# habitants du Sanctuaire : arrivent au fil des paliers terminés
					var npc: String = {"F": "smith", "J": "cartographer", "I": "elder", "]": "jeweler"}[row[x]]
					var need: int = {"smith": 1, "cartographer": 2, "elder": 1, "jeweler": 2}[npc]
					if GameState.record >= need:
						# le joaillier, juste sous la lumière, était tout blanc : lumière plus douce
						var np2 = _make_prop(npc, Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(1.0, 0.8, 0.55), 0.8 if npc == "jeweler" else 2.0)
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
					altar_key = "%d-%d-%d!%d,%d" % [GameState.run_seed, GameState.palier, GameState.step, x, y]
					if GameState.mode == "descent" and GameState.is_collected(altar_key):
						altar_state = "done"      # autel déjà vaincu lors d'un passage précédent
					else:
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
				"k", "q", "v", "y", "x", "z", "a":
					var tk: String = {"k": "spikes", "q": "gas", "v": "geyser", "y": "geyser", "x": "crystal", "z": "book", "a": "hand"}[row[x]]
					_make_trap(tk, Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), {"element": "ice" if row[x] == "y" else "fire"})
				"i":
					_make_trap("iceplate", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), {})
				"+":
					_make_trap("crystalplate", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), {})
				"o":
					# jet de vapeur : bouche posée au sol, souffle vers le côté le plus dégagé
					var ol := 0
					while x - ol - 1 > 0 and row[x - ol - 1] != "#" and ol < 6:
						ol += 1
					var orr := 0
					while x + orr + 1 < row.length() - 1 and row[x + orr + 1] != "#" and orr < 6:
						orr += 1
					_make_trap("steam", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), {"dir": 1.0 if orr >= ol else -1.0})
				"d":
					# goutte acide : accrochée au plafond au-dessus de cette case
					var cy := y
					while cy > 0 and row != "" and not solid.has(Vector2i(x, cy - 1)) and y - cy < 12:
						cy -= 1
					_make_trap("drip", Vector2(x * TILE + TILE / 2.0, cy * TILE), {"floor_y": (y + 1) * TILE})
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
				"n":
					enemy_spawns.append([MonkeyScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				"&":
					enemy_spawns.append([MimicScript, _cell_feet(x, y, 22), null, _roll_elite(x, y)])
				"p":
					enemy_spawns.append([MoleScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				"(":
					enemy_spawns.append([SlimeScript, _cell_feet(x, y, 22), null, _roll_elite(x, y)])
				")":
					enemy_spawns.append([ScorpionScript, _cell_feet(x, y, 20), null, _roll_elite(x, y)])
				"%":
					enemy_spawns.append([GoblinScript, _cell_feet(x, y, 30), null, _roll_elite(x, y)])
				"e":
					# mites : arrivent par deux ou trois
					var nm := 2 + int(fposmod(float(x * 7 + y * 3), 2.0))
					for k in nm:
						enemy_spawns.append([MothScript, Vector2(x * TILE + 16 + (k - 1) * 22, y * TILE + 16 + (k % 2) * 14), null, _roll_elite(x + k, y)])
				"`":
					var cid := String(pal.get("id", ""))
					var ckey := "%d-%d-%d#champ" % [GameState.run_seed, GameState.palier, GameState.step]
					if CHAMPIONS.has(cid) and not (GameState.mode == "descent" and GameState.is_collected(ckey)):
						var csc = load("res://scripts/%s.gd" % CHAMPIONS[cid][0])
						var floor_pos := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
						enemy_spawns.append([csc, floor_pos, null, true, {"name": CHAMPIONS[cid][1], "key": ckey, "air": CHAMPIONS[cid][0] in CHAMP_AIR}])
				"<":
					enemy_spawns.append([AnglerScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				"?":
					enemy_spawns.append([TomeScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				";":
					enemy_spawns.append([PuffballScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				">":
					enemy_spawns.append([DrownedScript, _cell_feet(x, y, 40), null, _roll_elite(x, y)])
				"=":
					enemy_spawns.append([TurtleScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				"!":
					enemy_spawns.append([ImpScript, _cell_feet(x, y, 24), null, _roll_elite(x, y)])
				":":
					enemy_spawns.append([GolemScript, _cell_feet(x, y, 42), null, _roll_elite(x, y)])
				"/":
					enemy_spawns.append([SkeletonScript, _cell_feet(x, y, 40), null, _roll_elite(x, y)])
				"r":
					enemy_spawns.append([WraithScript, Vector2(x * TILE + 16, y * TILE + 16), null, _roll_elite(x, y)])
				"K", "Q":
					var bid: String = level.get("boss_id", "abbesse" if row[x] == "Q" else "gardien")
					boss_id = bid
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

# Ce que fait {haut} devant un habitant ou un objet du Sanctuaire (appelé après l'écran d'entrée
# pour les boutiques, une fois les battants fermés).
func _do_interact(it: Array) -> void:
	if it[1] == "arena":
		hub_ui.open_npc("arena")
	elif it[1] == "merchant":
		hub_ui.open_shop()
	elif it[1] == "arsenal":
		hub_ui.open_arsenal()
	elif it[1] == "altar":
		_start_altar(it[0])
	elif it[1] == "lever":
		_pull_lever(it[0])
	elif it[1] == "elder":
		elder_ui.open()
	elif it[1] in ["smith", "cartographer", "jeweler"]:
		hub_ui.open_npc(it[1])
	elif it[1] == "tailor":
		hub_ui.open_wardrobe()
	elif it[1] == "scriptorium":
		scriptorium.open()
	elif it[1] == "gift":
		_open_gift(it[0])
	elif it[1] == "winch":
		if player.can_grab_rope():
			_grab_winch(it[0], player.global_position.y)
	else:
		hub_ui.open_elevator()

# Corde des treuils : en plus du pied de corde ({haut} au sol), on s'y accroche en l'air en
# appuyant {haut} contre la corde, et d'en haut avec {bas} au bord du puits. Sur la corde, l'aide
# rappelle les commandes.
func _grab_winch(wn, y: float) -> void:
	player.grab_rope(wn, y)
	GameState.j_add("winches")
	# Nœud de Grimpeur : la première prise de chaque corde rend de l'âme
	if player.eq(player.C.CLIMBER) and not wn.has_meta("soul_given"):
		wn.set_meta("soul_given", true)
		player.soul = mini(player.soul + int(player.clv(player.C.CLIMBER, [33, 45, 60])), player.SOUL_MAX)

func _winch_ropes(pp: Vector2) -> void:
	if player.rope != null:
		interact_hint = tr("{up|1}{down|1} : monter / descendre    {jump|1} : sauter    {down|1}+{jump|1} : lâcher")
		return
	if get_tree().paused or not player.can_grab_rope():
		return
	for it in interactables:
		if it[1] != "winch":
			continue
		var wn = it[0]
		var dx := absf(pp.x - wn.position.x)
		# en l'air, contre la corde
		if not player.is_on_floor() and dx < 20.0 and pp.y > wn.top.y and pp.y < wn.position.y:
			if Input.is_action_just_pressed("up"):
				_grab_winch(wn, pp.y)
				return
		# en haut, au bord du puits
		var at_top: bool = absf(pp.y + player.SIZE.y / 2.0 - wn.top.y) < 10.0 and (dx < 56.0 or absf(pp.x - wn.arrive.x) < 40.0)
		if player.is_on_floor() and at_top:
			interact_hint = tr("{down|1} : descendre par la corde")
			if Input.is_action_just_pressed("down"):
				_grab_winch(wn, -INF)
				return

# Treuils : chaque pied de corde est relié à l'arrivée « u » la plus proche au-dessus.
func _make_winches() -> void:
	for lo in winch_low:
		var best := Vector2i(-1, -1)
		for tp in winch_top:
			if tp.y < lo.y and absi(tp.x - lo.x) <= 8 and (best.x < 0 or tp.y > best.y):
				best = tp
		if best.x < 0:
			continue
		var w := Node2D.new()
		w.set_script(WinchScript)
		w.main = self
		w.position = Vector2(lo.x * TILE + TILE / 2.0, (lo.y + 1) * TILE)
		w.top = Vector2(lo.x * TILE + TILE / 2.0, (best.y + 1) * TILE)
		w.arrive = _cell_feet(best.x, best.y, 34)
		add_child(w)
		interactables.append([w, "winch"])

func _make_prop(kind: String, pos: Vector2, light_color: Color, light_scale: float):
	var p := Node2D.new()
	p.set_script(PropScript)
	p.kind = kind
	p.position = pos
	add_child(p)
	p.add_child(make_light(light_color, light_scale, 0.9, Vector2(0, -24) if kind != "orb" else Vector2.ZERO, kind == "bench"))
	return p

func respawn_enemies() -> void:
	for s in enemy_spawns:
		if s[2] == null or not is_instance_valid(s[2]):
			var e := CharacterBody2D.new()
			e.set_script(s[0])
			e.main = self
			e.elite = s[3]
			e.position = s[1]
			if s.size() > 4:
				# champion : il ne revient pas une fois vaincu
				if GameState.mode == "descent" and GameState.is_collected(s[4]["key"]):
					continue
				if s[4]["name"] == "Le Bourdon Gardien":
					e.set("bee", true)
			add_child(e)
			s[2] = e
			if s.size() > 4:
				_make_champion(e, s[4])

func _make_champion(e, info: Dictionary) -> void:
	e.champion = info["name"]
	e.set_meta("champ_key", info["key"])
	e.scale = Vector2(CHAMP_SCALE, CHAMP_SCALE)
	var floor_pos: Vector2 = info.get("floor", e.position)
	info["floor"] = floor_pos
	e.position = floor_pos - Vector2(0, e.size.y * CHAMP_SCALE / 2.0 + 1.0 + (110.0 if info["air"] else 0.0))
	if e.get("home") != null:
		e.home = e.position
	e.hp = int(e.hp * (5 + GameState.palier))
	e.hp_max = e.hp
	e.geo_value = e.geo_value * 6
	e.show_bar = false             # sa vie s'affiche en bas de l'écran
	for k in e.get_children():
		if k.get_script() == e.HpBarScript:
			k.queue_free()
	champ = e

func make_light(color: Color, sc: float, energy: float, offset: Vector2 = Vector2.ZERO, shadows := false) -> PointLight2D:
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
	player.add_child(make_light(pal.get("light", Color(1.0, 0.85, 0.6)), 1.3 if GameState.curse == "dark" and GameState.mode == "descent" else 2.2, 1.0 if GameState.curse == "dark" else 0.85, Vector2(0, -10), true))
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
				_mark_collected(challenge_key)
				var reward := roundi((40 + 15 * GameState.palier) * GameState.geo_mult())
				player.geo += reward
				GameState.j_add("geo_in", reward)
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
			_mark_collected(altar_key)
			var reward2 := roundi((50 + 15 * GameState.palier) * GameState.geo_mult())
			player.geo += reward2
			GameState.j_add("geo_in", reward2)
			var cid := _random_charm(int(pp.x))
			if cid >= 0:
				var rp = _make_prop("charm", pp + Vector2(0, -60), GameState.charm(cid)["color"], 1.6)
				rp.color = GameState.charm(cid)["color"]
				rp.charm_id = cid
				pickups.append([rp, "charm", cid, altar_key])
			Audio.sfx("pickup", 0.0, 3.0)
			show_message(tr("Arène vaincue ! +%d éclats") % reward2, 3.0)
			Achievements.unlock("room")

func _mark_collected(key: String) -> void:
	if key != "" and GameState.mode == "descent" and not GameState.is_collected(key):
		GameState.prog["collected"].append(key)

# Salle des leviers : tirer les trois leviers dans l'ordre des runes de la plaque.
# Une erreur : les leviers se relèvent ; le bon ordre ouvre la herse du caveau.
# Chambres secrètes : un voile de roche cache la chambre (remplissage depuis le fragment, fermé
# par la roche et les dalles fissurées) jusqu'à ce que la dalle cède ou que le héros y entre.
func _veil_secrets() -> void:
	for start in memory_cells:
		var seen := {start: true}
		var todo: Array = [start]
		var walls := []
		var ok := true
		while not todo.is_empty() and ok:
			var c: Vector2i = todo.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if seen.has(n) or solid.has(n):
					continue
				if breakable_cells.has(n):
					if not breakable_cells[n] in walls:
						walls.append(breakable_cells[n])
					continue
				if n.x < 0 or n.y < 0 or n.x >= map_size.x or n.y >= map_size.y:
					ok = false
					break
				seen[n] = true
				todo.append(n)
				if seen.size() > 90:
					ok = false
		if not ok or walls.is_empty():
			continue
		for c in seen:
			veiled[c] = true
		var v := Node2D.new()
		v.set_script(preload("res://scripts/secret_veil.gd"))
		v.main = self
		v.cells = seen.keys()
		v.walls = walls
		add_child(v)
	if not veiled.is_empty():
		for n in get_children():
			if n is Node2D and n.get_script() == LevelArtScript and not n.is_chunk:
				n.depth.clear()
				n._compute_depth()
				n.redraw_all()
				for v in get_children():
					if v.has_method("set_art"):
						v.set_art(n)

func _pull_lever(lv) -> void:
	if lv.lit or lever_reset_t > 0.0 or lever_gate == null or not lever_gate.closed:
		return
	lv.lit = true
	var rune: int = lv.get_meta("rune")
	lever_done.append(rune)
	Audio.sfx("door", 0.1, -6.0)
	shake(3)
	if rune != lever_order[lever_done.size() - 1]:
		lever_reset_t = 0.7
		show_message(tr("Mauvais ordre… les leviers se relèvent."), 2.0)
		return
	if lever_done.size() == lever_order.size():
		lever_gate.set_closed(false)
		for o in levers:
			if o.kind == "lever_plaque":
				o.lit = true
		shake(8)
		Audio.sfx("lift_chains", 0.0, -2.0)
		Audio.sfx("achievement", 0.0, -6.0)
		spawn_burst(lever_gate.rect.get_center(), Color(0.6, 0.85, 1.0), 18, 160.0, 0.0)
		show_message(tr("La herse du caveau se lève !"), 2.5)
		if GameState.mode == "descent":
			_mark_collected(lever_key)

func _lever_tick(delta: float) -> void:
	if lever_reset_t <= 0.0:
		return
	lever_reset_t -= delta
	if lever_reset_t <= 0.0:
		lever_done.clear()
		Audio.sfx("hit", 0.1, -10.0)
		for o in levers:
			if o.kind == "lever":
				o.lit = false
				spawn_burst(o.position + Vector2(0, -20), Color(0.7, 0.7, 0.75), 6, 80.0, 0.0)

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
uniform float strength = 1.0;
void fragment() {
	vec2 p = SCREEN_UV * screen;
	float d = distance(p, center);
	float a = smoothstep(radius, radius + soft, d);
	COLOR = vec4(0.0, 0.0, 0.02, a * 0.94 * strength);
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
	vignette = r

# Qualité graphique (Options) : appliquée tout de suite, sans recharger le niveau.
#  équilibrée : sans rayons ni brume d'arrière-plan, moitié moins de particules
#  basse : plan lointain seul, plus de lumières 2D (sauf celles du héros), plus de particules ni de vignette
func apply_quality() -> void:
	var q := int(Settings.gfx_quality)
	if bg and bg.has_method("apply_quality"):
		bg.apply_quality()
	if vignette:
		vignette.visible = q < 2
	_lights_on(self, q < 2)

func _lights_on(n: Node, on: bool) -> void:
	for c in n.get_children():
		if c == player:
			continue
		if c is Light2D:
			c.enabled = on
		_lights_on(c, on)

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

# Mites-éteignoirs : plus elles tournent près du héros, plus la lumière se resserre
var moth_dim := 0.0
func _update_moths(delta: float) -> void:
	var target := 0.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_script() == MothScript:
			target += e.dim()
	target = minf(target, 0.8)
	moth_dim = move_toward(moth_dim, target, delta * (1.2 if target > moth_dim else 0.6))
	if GameState.curse == "dark" and GameState.mode == "descent":
		return
	if moth_dim > 0.01 and dark_rect == null:
		_make_darkness()
	if dark_rect:
		dark_rect.visible = moth_dim > 0.01
		(dark_rect.material as ShaderMaterial).set_shader_parameter("strength", moth_dim)

func _update_darkness() -> void:
	if dark_rect == null or player == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var mat: ShaderMaterial = dark_rect.material
	var sp: Vector2 = player.get_global_transform_with_canvas().origin + Vector2(0, -10) * camera.zoom.x
	mat.set_shader_parameter("center", sp)
	mat.set_shader_parameter("screen", vp)
	var cursed: bool = GameState.curse == "dark" and GameState.mode == "descent"
	mat.set_shader_parameter("radius", (120.0 if cursed else 150.0 - 40.0 * moth_dim) * camera.zoom.x)
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

# Sanctuaire : les habitants parlent quand on passe près d'eux (bulle, une fois par passage)
const LoreScript = preload("res://scripts/lore.gd")
var _chat_cd := {}
var _bubble: Node2D = null

func _npc_chatter(delta: float) -> void:
	if not GameState.is_hub() or player == null or get_tree().paused:
		return
	for k in _chat_cd.keys():
		_chat_cd[k] -= delta
	# pas de bulle par-dessus un message (bilan de descente, trésor…) ou un panneau d'aide :
	# celle qui parle se tait ; et une seule bulle à la fois
	var busy: bool = (hud != null and hud.message_t > 0.0) or sign_text != ""
	if is_instance_valid(_bubble):
		if busy and _bubble.life > _bubble.t + 0.4:
			_bubble.life = _bubble.t + 0.4
		return
	if busy:
		return
	for it in interactables:
		var kind: String = it[1]
		if not LoreScript.AMBIENT.has(kind) or not is_instance_valid(it[0]):
			continue
		var d: float = player.global_position.distance_to(it[0].global_position)
		if d < 110.0 and float(_chat_cd.get(kind, 0.0)) <= 0.0:
			var line := LoreScript.ambient_line(kind)
			if line == "":
				continue
			_chat_cd[kind] = 25.0
			var b := Node2D.new()
			b.set_script(preload("res://scripts/bubble.gd"))
			b.text = tr(line)
			b.position = it[0].global_position + Vector2(0, -92)
			add_child(b)
			_bubble = b
			LoreScript.hear(LoreScript.NPC_NAMES[kind], tr(line))
		elif d > 220.0 and float(_chat_cd.get(kind, 0.0)) > 0.0 and float(_chat_cd[kind]) < 20.0:
			_chat_cd[kind] = minf(_chat_cd[kind], 6.0)

func _process(delta: float) -> void:
	_npc_chatter(delta)
	_lever_tick(delta)
	if not get_tree().paused:
		clock += delta
	_update_moths(delta)
	_update_darkness()
	_reveal_t -= delta
	_update_rooms(delta)
	_enemy_spikes(delta)
	_ghost_tick(delta)
	if GameState.mode in ["descent", "rush"] and not get_tree().paused:
		Achievements.run["time"] = float(Achievements.run.get("time", 0.0)) + delta
	if not get_tree().paused:
		GameState.j_tick(delta)
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
	# Caméra : suit le joueur, regarde un peu devant lui (en duel : cadre les deux joueurs)
	if GameState.mode == "duel":
		_duel_tick(delta)
	else:
		camera.global_position = player.global_position + Vector2(player.facing * 50.0, -40.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	shake_amt = move_toward(shake_amt, 0.0, delta * 40.0)
	flash = move_toward(flash, 0.0, delta * 3.0)

	var pp: Vector2 = player.global_position
	# Marchand et ascenseur (hub)
	interact_hint = ""
	# seulement le plus proche : un marchand à côté d'un treuil ne vole plus la corde
	var closest = null
	var best_d := 60.0
	for it0 in interactables:
		if it0[1] == "winch" and player.rope != null:
			continue
		var dd := pp.distance_to(it0[0].position + Vector2(0, -20))
		if dd < best_d:
			best_d = dd
			closest = it0
	for it in ([closest] if closest != null else []):
		if not player.dead:
			var verbs := {"merchant": "parler au marchand", "arsenal": "ouvrir l'arsenal", "elevator": "appeler l'ascenseur",
				"altar": "réveiller l'autel (3 élites)", "smith": "parler à la forgeronne", "jeweler": "parler au joaillier", "arena": "Arène des Ombres (duel à deux)", "cartographer": "parler au cartographe", "elder": "écouter l'ancien",
				"tailor": "ouvrir la garde-robe", "gift": "ouvrir ton cadeau", "winch": "s'accrocher à la corde", "lever": "actionner le levier",
				"scriptorium": "consulter les registres"}
			if it[1] == "altar" and altar_state != "":
				continue
			if it[1] == "gift" and not it[0].lit:
				continue
			if it[1] == "lever" and (it[0].lit or lever_reset_t > 0.0 or (lever_gate and not lever_gate.closed)):
				continue
			interact_hint = tr("{up|1} : %s") % tr(verbs[it[1]])
			if Input.is_action_just_pressed("up") and player.is_on_floor() and not get_tree().paused:
				# écran d'entrée animé : battants de bois qui s'ouvrent sur la boutique
				var shop_names := {"merchant": ["shop", "Marchand"], "arsenal": ["arsenal", "Arsenal"], "smith": ["smith", "Forgeronne"], "jeweler": ["jeweler", "Joaillier"],
					"cartographer": ["cartographer", "Cartographe"], "elder": ["elder", "Ancien"], "tailor": ["tailor", "Tailleuse"],
					"scriptorium": ["scriptorium", "Scriptorium"]}
				if shop_names.has(it[1]):
					LoadingScript.shop(get_tree(), shop_names[it[1]][0], tr(shop_names[it[1]][1]), _do_interact.bind(it))
				else:
					_do_interact(it)
	_winch_ropes(pp)
	# Banc le plus proche
	for bp in benches:
		if pp.distance_to(bp) < pp.distance_to(bench_pos):
			bench_pos = bp
	# Banc
	if not player.dead and not player.sitting and pp.distance_to(bench_pos) < 48 and player.is_on_floor() and Input.is_action_just_pressed("up") \
			and player.bench_lock_t > 0.0:
		show_message("Trop agité pour se reposer…", 1.2)
	elif not player.dead and not player.sitting and pp.distance_to(bench_pos) < 48 and player.is_on_floor() and Input.is_action_just_pressed("up"):
		# Un banc ne soigne qu'une fois par zone (sauf au Sanctuaire) : sinon on pouvait
		# s'asseoir en boucle en plein combat pour regagner toute sa vie.
		var key := "%d,%d" % [int(bench_pos.x), int(bench_pos.y)]
		var fresh: bool = GameState.mode == "hub" or not used_benches.has(key)
		used_benches[key] = true
		player.sit(bench_pos, fresh)
		respawn_pos = bench_pos
		if fresh:
			respawn_enemies()
			show_message("Vous vous reposez. Santé restaurée.", 2.5)
		else:
			show_message("Ce banc ne soigne plus. Point de réapparition enregistré.", 2.5)
	# Orbe de Ruée
	if dash_orb and is_instance_valid(dash_orb) and pp.distance_to(dash_orb.position) < 36:
		player.can_dash = true
		spawn_burst(dash_orb.position, Color(0.6, 0.9, 1.0), 40, 260.0)
		dash_orb.queue_free()
		dash_orb = null
		shake(8)
		show_message("Cape d'Ombre-Vive obtenue !\n{dash} pour faire une Ruée", 4.0)
	# Filet de sécurité : pendant le combat, un héros qui se retrouve hors de l'arène (bug de
	# collision, recul…) est remis à l'intérieur, là où il est entré, au lieu d'être bloqué dehors.
	if boss_started and not boss_dead and entry_gate and is_instance_valid(entry_gate) and entry_gate.closed \
			and not player.dead and not in_arena(pp) and arena_entry_pos != Vector2.ZERO:
		spawn_burst(player.global_position, Color(0.8, 0.85, 1.0), 14, 160.0)
		player.global_position = arena_entry_pos
		player.velocity = Vector2.ZERO
		player.invuln_t = maxf(player.invuln_t, 0.8)
		spawn_burst(arena_entry_pos, Color(0.8, 0.85, 1.0), 14, 160.0)
	# Déclenchement du boss
	if boss and not boss_started and not boss_dead and entry_gate and pp.x > entry_gate.rect.end.x + TILE * 3 and in_arena(pp):
		boss_started = true
		boss_t0 = clock
		boss_hurt0 = int(GameState.j_get("hurt"))
		arena_entry_pos = player.global_position
		entry_gate.set_closed(true)
		# aucun ennemi ordinaire ne reste enfermé avec le boss
		for e in get_tree().get_nodes_in_group("enemies"):
			if e != boss and not e.is_boss and in_arena(e.global_position):
				e.queue_free()
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
				var amount := roundi((40 + 15 * GameState.palier) * GameState.geo_mult() * float(player.clv(player.C.PLUNDERER, [1.6, 1.9, 2.2], 1.0)))
				player.geo += amount
				GameState.j_add("geo_in", amount)
				GameState.j_add("chests")
				GameState.prog["collected"].append(pk[2])     # cachette vidée
				Audio.sfx("pickup", 0.0)
				show_pickup(tr("Trésor caché : +%d éclats !") % amount, 3.0)
				Achievements.unlock("room")
			elif pk[1] == "memory":
				GameState.prog["memories"] = int(GameState.prog.get("memories", 0)) + 1
				GameState.prog["collected"].append(pk[2])
				Audio.sfx("soul_level", 0.0)
				show_pickup(tr("Fragment de mémoire (%d) — l'Ancien saura quoi en faire.") % int(GameState.prog["memories"]), 3.5)
			elif pk[1] == "charm":
				GameState.add_charm(pk[2])
				if pk.size() > 3:
					_mark_collected(String(pk[3]))
				GameState.j_charm_found(int(pk[2]), String(level.get("name", "")))
				Audio.sfx("pickup", 0.0)
				show_pickup(tr("Emblème obtenu : %s\nÉquipe-le depuis l'inventaire ({inventory|1}) en te reposant sur un banc.") % tr(GameState.charm(pk[2])["name"]), 4.5)
			else:
				GameState.add_notch(pk[2])
				Audio.sfx("pickup", 0.0)
				show_pickup(tr("Encoche d'emblème obtenue !\nEncoches : %d") % GameState.prog["notches"], 3.5)
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

# Le point est-il dans l'arène du boss ? Entre les deux grilles ET à la hauteur de l'arène :
# sur les niveaux en strates, l'arène est en bas, sous des étages qui la dépassent en largeur.
func in_arena(p: Vector2) -> bool:
	if not entry_gate or not is_instance_valid(entry_gate):
		return false
	var r: Rect2 = entry_gate.rect
	if p.x <= r.end.x or p.y < r.position.y - TILE or p.y > r.end.y + TILE:
		return false
	if exit_gate and is_instance_valid(exit_gate) and p.x >= exit_gate.rect.position.x:
		return false
	return true

func is_solid_at(p: Vector2) -> bool:
	if solid.has(Vector2i(floori(p.x / TILE), floori(p.y / TILE))):
		return true
	# grille d'arène fermée : un mur pour les coups, les projectiles et les ennemis
	# (avant, seuls les blocs de roche comptaient : on touchait le boss à travers les barreaux)
	for g in [entry_gate, exit_gate]:
		if g and is_instance_valid(g) and g.closed and g.rect.grow(2.0).has_point(p):
			return true
	return false

# Les pics des fosses blessent aussi les ennemis qui y tombent (ou qu'on y pousse) :
# 2 dégâts, puis toutes les 0,5 s tant qu'ils restent dessus. Pas les boss.
var _spike_cd := {}
func _enemy_spikes(delta: float) -> void:
	if spikes.is_empty():
		return
	for e in _spike_cd.keys():
		if not is_instance_valid(e):
			_spike_cd.erase(e)
		else:
			_spike_cd[e] -= delta
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or e.is_boss or float(_spike_cd.get(e, 0.0)) > 0.0:
			continue
		var r: Rect2 = e.get_rect().grow(-3)
		for sp in spikes:
			if r.intersects(sp):
				if not e.trap_vulnerable():
					break
				_spike_cd[e] = 0.5
				e.hurt_by_trap(2, Vector2(0, -1))
				spawn_burst(Vector2(e.global_position.x, sp.position.y), Color(0.85, 0.85, 0.9), 6, 120.0)
				break

# ---------------------------------------------------------------- duel local (Arène des Ombres)
# Deux joueurs, chacun son arme (niveau 2, sans emblèmes), 9 masques ; le premier à 3 manches gagne.
const DUEL_HP := 9
var arena_spot := Vector2.INF
var arena_prop = null
# montre ou cache la bannière de l'arène selon l'option (sans recharger le Sanctuaire)
func refresh_arena() -> void:
	if arena_spot == Vector2.INF:
		return
	if Settings.arena_mode and arena_prop == null:
		arena_prop = _make_prop("arena", arena_spot, Color(1.0, 0.6, 0.45), 1.6)
		interactables.append([arena_prop, "arena"])
	elif not Settings.arena_mode and arena_prop != null:
		for it in interactables.duplicate():
			if it[0] == arena_prop:
				interactables.erase(it)
		arena_prop.queue_free()
		arena_prop = null
var duel_players: Array = []
var duel_spawns: Array = []
var duel_freeze := 0.0
var duel_hud = null
var _duel_over := false

func _duel_setup_player(p, n: int) -> void:
	p.duel_weapon = String(GameState.duel_w[n - 1])
	p.can_dash = true
	p.max_hp = DUEL_HP
	p.hp = DUEL_HP
	p.soul = 0
	p.ult = 0
	p.facing = 1 if n == 1 else -1
	p.add_to_group("enemies")
	if n == 2:
		p.modulate = Color(1.0, 0.72, 0.7)
	duel_players.append(p)
	duel_spawns.append(p.position)

func duel_other(p):
	for q in duel_players:
		if q != p:
			return q
	return null

func _duel_start_round() -> void:
	for i in duel_players.size():
		var p = duel_players[i]
		p.respawn(duel_spawns[i])
		p.max_hp = DUEL_HP
		p.hp = DUEL_HP
		p.facing = 1 if i == 0 else -1
		p.invuln_t = 0.0
	duel_freeze = 2.2
	if duel_hud:
		duel_hud.countdown(2.2)

func duel_ko(loser) -> void:
	if _duel_over:
		return
	_duel_over = true
	var w: int = 2 if loser == duel_players[0] else 1
	GameState.duel_score[w - 1] += 1
	spawn_burst(loser.global_position, Color(0.9, 0.85, 1.0), 30, 260.0)
	shake(8)
	hit_stop(0.25)
	if duel_hud:
		duel_hud.announce(tr("Manche pour le joueur %d !") % w)
	await get_tree().create_timer(2.0, false).timeout
	if int(GameState.duel_score[w - 1]) >= GameState.DUEL_TARGET:
		GameState.end_duel(w)
		return
	_duel_over = false
	_duel_start_round()

func _duel_tick(delta: float) -> void:
	if duel_players.size() < 2:
		return
	var a = duel_players[0]
	var b = duel_players[1]
	# compte à rebours : personne ne bouge
	if duel_freeze > 0.0:
		duel_freeze -= delta
		for p in duel_players:
			p.set_physics_process(duel_freeze <= 0.0)
	# caméra : cadre les deux joueurs
	var mid: Vector2 = (a.global_position + b.global_position) * 0.5 + Vector2(0, -40)
	var span := maxf(absf(a.global_position.x - b.global_position.x) + 360.0, (absf(a.global_position.y - b.global_position.y) + 260.0) * 16.0 / 9.0)
	var z := clampf(get_viewport_rect().size.x / span, 0.75, 1.4) * Settings.zoom
	camera.zoom = camera.zoom.lerp(Vector2(z, z), clampf(delta * 3.0, 0.0, 1.0))
	camera.global_position = mid

# ---------------------------------------------------------------- fantôme (jour, semaine)
# Le parcours du héros est noté 10 fois par seconde, niveau par niveau ; s'il existe un
# fantôme du premier du classement, une silhouette translucide rejoue son parcours en même temps.
const GhostScript = preload("res://scripts/ghost.gd")
var _ghost_t := 0.0
var _ghost_node = null
func _ghost_tick(delta: float) -> void:
	if not GameState.daily or GameState.mode != "descent" or player == null or get_tree().paused:
		return
	var key := str(GameState.step)
	_ghost_t += delta
	var rec: PackedStringArray = GameState.ghost_rec.get(key, PackedStringArray())
	var want := int(_ghost_t * 10.0) + 1
	while rec.size() < want and rec.size() < 12000:
		rec.append("%d,%d,%d" % [roundi(player.global_position.x), roundi(player.global_position.y), 1 if player.facing > 0 else 0])
	GameState.ghost_rec[key] = rec
	if _ghost_node == null and GameState.ghost_play.has(key):
		_ghost_node = GhostScript.new()
		_ghost_node.setup(String(GameState.ghost_play[key]), GameState.ghost_name)
		add_child(_ghost_node)
	if _ghost_node:
		_ghost_node.at(_ghost_t)

# Pluie de gravats (Mines de Cristal) : poussière qui tombe d'abord du plafond au-dessus de x,
# puis quelques pierres, décalées dans le temps.
func debris_rain(x: float, y: float) -> void:
	var cy := y
	for i in 14:
		if is_solid_at(Vector2(x, cy - TILE)):
			break
		cy -= TILE
	if cy >= y - TILE * 2:
		return
	for k in 4:
		var px := x + randf_range(-70.0, 70.0)
		spawn_burst(Vector2(px, cy + 4), Color(0.6, 0.62, 0.7), 5, 40.0, 300.0)
	await get_tree().create_timer(0.45, false).timeout
	for k in 5:
		if not is_inside_tree():
			return
		var px2 := x + randf_range(-80.0, 80.0)
		spawn_projectile(Vector2(px2, cy + 8), Vector2(randf_range(-20, 20), 60), {"kind": "rock", "radius": 7.0, "gravity": 900.0, "life": 3.0, "from_trap": true})
		await get_tree().create_timer(randf_range(0.12, 0.25), false).timeout

# Chemin pour les ennemis volants : parcours en largeur sur la grille des cases, limité à
# un rayon autour d'eux. Renvoie le point de passage le plus éloigné du chemin encore visible
# en ligne droite (pour contourner les murs sans zigzaguer), ou Vector2.INF si aucun chemin.
func fly_waypoint(from: Vector2, to: Vector2, radius: int = 16) -> Vector2:
	var s := Vector2i(floori(from.x / TILE), floori(from.y / TILE))
	var g := Vector2i(floori(to.x / TILE), floori(to.y / TILE))
	if s == g:
		return to
	var prev := {s: s}
	var queue: Array[Vector2i] = [s]
	var head := 0
	var found := false
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if c == g:
			found = true
			break
		for d in dirs:
			var n: Vector2i = c + d
			if prev.has(n) or absi(n.x - s.x) > radius or absi(n.y - s.y) > radius:
				continue
			if solid.has(n) and n != g:
				continue
			if is_solid_at((Vector2(n) + Vector2(0.5, 0.5)) * TILE) and n != g:
				continue          # grille d'arène fermée
			prev[n] = c
			queue.append(n)
	if not found:
		return Vector2.INF
	var path: Array[Vector2i] = []
	var c2 := g
	while c2 != s:
		path.push_front(c2)
		c2 = prev[c2]
	# le plus loin possible sur le chemin tant qu'on le voit sans obstacle
	var best := (Vector2(path[0]) + Vector2(0.5, 0.5)) * TILE
	for i in range(1, mini(path.size(), 10)):
		var q := (Vector2(path[i]) + Vector2(0.5, 0.5)) * TILE
		if path[i] == g:
			q = to
		if wall_between_wide(from, q, 10.0):
			break
		best = q
	return best

# comme wall_between, mais vérifie aussi deux lignes décalées (largeur du corps)
func wall_between_wide(a: Vector2, b: Vector2, half: float) -> bool:
	var n := (b - a).normalized().orthogonal() * half
	return wall_between(a, b) or wall_between(a + n, b + n) or wall_between(a - n, b - n)

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

func show_message(text: String, duration: float = 2.5, small := false) -> void:
	if hud:
		hud.message = tr(text)
		hud.message_t = duration
		hud.message_small = small

# objet ramassé : bandeau discret en haut de l'écran (le centre reste libre pour le combat)
func show_pickup(text: String, duration: float = 3.0) -> void:
	show_message(text, duration, true)

var _spark: Texture2D
func _spark_tex() -> Texture2D:
	if _spark == null:
		_spark = DU.radial_texture(32)
	return _spark

# Éclats propres au biome (feuilles, braises, neige, éclats de cristal, os, miel, sable, pages…),
# projetés aux impacts et aux morts : deux teintes, gravité et taille selon la matière.
func biome_debris(pos: Vector2, amount: int = 8, speed: float = 160.0) -> void:
	if amount <= 0:
		return
	var id := String(pal.get("id", ""))
	var moss: Color = pal.get("moss", Color(0.6, 0.8, 0.5))
	var rk: Color = pal.get("rock_hi", Color(0.5, 0.5, 0.5))
	var c1 := rk.lightened(0.2)
	var c2 := rk
	var grav := 420.0
	var sz := Vector2(0.06, 0.13)
	match id:
		"jungle", "jardins":
			c1 = moss; c2 = moss.darkened(0.35); grav = 160.0; sz = Vector2(0.08, 0.15)
		"profondeurs":
			c1 = Color(0.55, 0.85, 1.0); c2 = rk; grav = 200.0
		"glace":
			c1 = Color(0.95, 0.98, 1.0); c2 = Color(0.6, 0.8, 1.0); grav = 90.0
		"cristal":
			c1 = moss.lightened(0.3); c2 = moss; grav = 380.0; sz = Vector2(0.07, 0.16)
		"forge":
			c1 = Color(1.0, 0.75, 0.3); c2 = Color(1.0, 0.35, 0.1); grav = -60.0; sz = Vector2(0.05, 0.1)
		"ruche":
			c1 = Color(1.0, 0.8, 0.3); c2 = Color(0.8, 0.5, 0.15); grav = 520.0
		"ossuaire":
			c1 = Color(0.88, 0.84, 0.72); c2 = Color(0.6, 0.55, 0.45); grav = 520.0
		"desert":
			c1 = rk.lightened(0.3); c2 = rk; grav = 300.0; sz = Vector2(0.04, 0.09)
		"bibliotheque":
			c1 = Color(0.95, 0.9, 0.75); c2 = Color(0.75, 0.65, 0.5); grav = 70.0; sz = Vector2(0.09, 0.16)
		"citadelle":
			c1 = Color(0.6, 0.75, 1.0); c2 = rk; grav = 380.0
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = 0.9 if absf(grav) < 200.0 else 0.6
	p.direction = Vector2(0, -1)
	p.spread = 75.0
	p.gravity = Vector2(0, grav)
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.damping_min = 20.0 if absf(grav) < 200.0 else 0.0
	p.damping_max = 60.0 if absf(grav) < 200.0 else 0.0
	p.scale_amount_min = sz.x
	p.scale_amount_max = sz.y
	p.texture = _spark_tex()
	var tint := Gradient.new()
	tint.set_color(0, c1)
	tint.set_color(1, c2)
	p.color_initial_ramp = tint
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	p.z_index = 5
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)

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
	# l'ombre rend exactement les éclats perdus ; les autres ennemis suivent le barème
	var gained: int = geo if e.get_script() == ShadeScript else GameState.kill_geo(geo)
	# Bourse du Marchand : plus d'éclats sur les ennemis
	if e.get_script() != ShadeScript and player.eq(player.C.MERCHANT_PURSE):
		gained = roundi(gained * float(player.clv(player.C.MERCHANT_PURSE, [1.2, 1.3, 1.4], 1.0)))
	if e.get_script() != DummyScript and e.get_script() != ShadeScript and not e.is_boss:
		player.on_kill_charms()
	player.geo += gained
	if e.get_script() != DummyScript and e.get_script() != ShadeScript and not e.is_boss:
		GameState.j_add("geo_in", gained)
		GameState.j_add("kills")
		if e.elite:
			GameState.j_add("elites")
		GameState.j_mob_kill(String(e.get_script().resource_path.get_file()).get_basename(), e.elite, String(level.get("name", "")))
	# Faux niv. 2 : chaque ennemi fauché rend 6 d'âme
	if GameState.weapon() == "faux" and GameState.weapon_level() >= 2 and not e.is_boss:
		player.soul = mini(player.soul + 6, player.SOUL_MAX)
	# Récolte d'Âme : chaque ennemi vaincu rend 8 d'âme
	if player.eq(player.C.SOUL_HARVEST) and not e.is_boss:
		player.soul = mini(player.soul + int(player.clv(player.C.SOUL_HARVEST, [8, 12, 16])), player.SOUL_MAX)
	if e.champion != "":
		# champion vaincu : gros butin, ne revient plus dans ce niveau
		var bonus := roundi((60 + 25 * GameState.palier) * GameState.geo_mult())
		player.geo += bonus
		GameState.j_add("geo_in", bonus)
		GameState.j_add("champions")
		if GameState.mode == "descent" and e.has_meta("champ_key"):
			GameState.prog["collected"].append(String(e.get_meta("champ_key")))
		show_pickup(tr("Champion vaincu : %s\n+%d éclats") % [tr(e.champion), bonus], 3.5)
		spawn_burst(e.global_position, Color(1.0, 0.8, 0.4), 30, 260.0, 0.0)
		shake(10)
		hit_stop(0.12)
		Audio.sfx("achievement", 0.0, -4.0)
		champ = null
	Achievements.stat("kills")
	Achievements.on_kill(e.elite and not e.is_boss)
	if player.plunge_kill_t > 0.0:
		Achievements.unlock("plunge")
	Audio.sfx("kill")
	spawn_burst(e.global_position, Color(0.95, 0.9, 0.75), 18, 220.0)
	biome_debris(e.global_position, 14 if e.elite else 9, 230.0)
	if not e.is_boss and e.get_script() != DummyScript:
		hit_stop(0.1 if e.elite else 0.05)   # petit arrêt sur image à chaque ennemi vaincu
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
	GameState.j_add("deaths")
	if boss_started and not boss_dead and boss_id != "":
		GameState.j_boss_loss(boss_id)
	spawn_burst(player.global_position, Color(0.15, 0.1, 0.2), 40, 260.0)
	await get_tree().create_timer(1.6).timeout
	# En descente : retour au hub, le butin de la descente est perdu
	if not GameState.is_tutorial():
		Audio.stop_music()
		Audio.stop_ambience()
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
	player.geo += GameState.boss_geo()
	GameState.j_add("geo_in", GameState.boss_geo())
	GameState.j_add("bosses")
	GameState.j_boss_win(boss_id, clock - boss_t0, int(GameState.j_get("hurt")) == boss_hurt0)
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

# Petite onde de choc de l'estoc repoussant
func thrust_shock(pos: Vector2) -> void:
	var ring := Node2D.new()
	ring.set_script(RingScript)
	ring.radius = 46.0
	ring.position = pos
	ring.c1 = Color(0.9, 0.95, 1.0)
	ring.c2 = Color(0.6, 0.75, 1.0)
	add_child(ring)
	shake(7)
	Audio.sfx("hammer", 0.08, -6.0)

# Onde de choc de l'ultime : gros dégâts à tout ce qui est dans le rayon, détruit les spores.
func ultimate_blast(pos: Vector2, caster = null) -> void:
	GameState.j_add("ults")
	Audio.sfx("ult", 0.0)
	var ring := Node2D.new()
	ring.set_script(RingScript)
	var ul: Dictionary = GameState.cos.look("ult")
	# Onde Tonnerre : rayon plus grand (et +1 dégât au niv. 3)
	var urad := ULT_RADIUS
	var udmg := ULT_DAMAGE
	if caster and is_instance_valid(caster) and caster.has_method("clv"):
		urad *= float(caster.clv(caster.C.THUNDER_WAVE, [1.3, 1.45, 1.6], 1.0))
		udmg += 1 if caster.cl(caster.C.THUNDER_WAVE) >= 3 else 0
	ring.radius = urad
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
		if not is_instance_valid(e) or e == caster:
			continue
		var c: Vector2 = e.get_rect().get_center()
		var ex: float = e.size.x if "size" in e else 20.0
		if c.distance_to(pos) <= urad + ex / 2.0:
			e.take_hit(udmg, (c - pos).normalized())
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile and pr.global_position.distance_to(pos) <= urad:
			pr.pop()

# Journal des dégâts infligés (coin de l'écran)
const ENEMY_NAMES := {"crawler.gd": "Rampant", "flyer.gd": "Volant", "spitter.gd": "Cracheur", "hopper.gd": "Sauteur",
	"guard.gd": "Garde", "bomber.gd": "Bulbe", "weaver.gd": "Tisseuse", "monkey.gd": "Singe", "mimic.gd": "Mimique", "moth.gd": "Mite", "mole.gd": "Taupe", "slime.gd": "Slime", "scorpion.gd": "Scorpion", "goblin.gd": "Gobelin", "lancer.gd": "Lancier", "wraith.gd": "Spectre",
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
	if e.get_script() != DummyScript:
		GameState.j_add("damage", dmg)
		if kind == "crit":
			GameState.j_add("crits")
	hud.add_damage(dmg, n, kind, e.hp <= 0)

# Coquille Épineuse : riposte quand le joueur est touché
func thorns_burst(pos: Vector2, dmg: int = 3) -> void:
	spawn_burst(pos, Color(0.6, 0.85, 0.5), 24, 300.0, 0.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e in duel_players and e.get_rect().get_center().distance_to(pos) < 110.0:
			e.take_hit(dmg, (e.get_rect().get_center() - pos).normalized())

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
	if pr.kind != "goo":     # la glue des slimes reste mate (pas de halo lumineux au sol)
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
const MINION_CAP := 3          # au plus 3 sbires vivants à la fois, quelle que soit la difficulté

# Places libres pour des sbires (les morts et ceux qui disparaissent ne comptent pas)
func minion_room() -> int:
	minions = minions.filter(func(m): return is_instance_valid(m) and not m.dead)
	return MINION_CAP - minions.size()

func spawn_minion(script, pos: Vector2, props := {}) -> void:
	if minion_room() <= 0:
		return
	var e := CharacterBody2D.new()
	e.set_script(script)
	e.main = self
	e.position = pos
	for k in props:
		e.set(k, props[k])
	add_child(e)
	minions.append(e)
	spawn_burst(pos, Color(0.9, 0.8, 0.4), 12, 160.0, 0.0)

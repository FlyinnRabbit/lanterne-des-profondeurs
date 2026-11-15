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
#   *  emblème au hasard (niveaux générés)    h  sauteur    g  garde à bouclier
#   Y  grille d'entrée de l'arène        X  grille de sortie
# Les cartes sont dans scripts/levels.gd.

const TILE := 32
const DU = preload("res://scripts/draw_util.gd")
const PlayerScript = preload("res://scripts/player.gd")
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
const HopperScript = preload("res://scripts/hopper.gd")
const GuardScript = preload("res://scripts/guard.gd")
const Biomes = preload("res://scripts/biomes.gd")

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
var signs := []     # [prop, données du panneau, déjà déclenché]
var sign_text := ""
var benches := []   # positions des bancs
var pal: Dictionary = {}
var level: Dictionary = {}
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
	inventory = CanvasLayer.new()
	inventory.set_script(InventoryScript)
	inventory.main = self
	add_child(inventory)
	GameState.equipment_changed.connect(player.apply_equipment)
	if GameState.is_tutorial():
		player.can_dash = true
		show_message(level["name"], 3.0)
	else:
		show_message("Niveau %d / %d — %s\nDifficulté : %s" % [GameState.level_index, GameState.RUN_LENGTH, level["name"], GameState.diff_name()], 3.5)
	Audio.play_playlist(level.get("music", []))
	if GameState.show_title:
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

func _cell_feet(x: int, y: int, height: float) -> Vector2:
	return Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE - height / 2.0 - 1.0)

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
						pickups.append([cp, "charm", id])
				"*":
					var cid := _random_charm(x)
					if cid >= 0:
						var rp = _make_prop("charm", Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0), GameState.charm(cid)["color"], 1.6)
						rp.color = GameState.charm(cid)["color"]
						pickups.append([rp, "charm", cid])
				"N":
					var key := "%d:%d,%d" % [GameState.level_index, x, y]
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
				"O":
					exit_door = _make_prop("door", Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE), Color(0.6, 0.85, 1.0), 3.5)
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
				"K", "Q":
					boss = CharacterBody2D.new()
					boss.set_script(BossScript)
					boss.variant = 2 if row[x] == "Q" else 1
					boss.main = self
					boss.home = _cell_feet(x, y, 64)
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
	return r.randf() < float(GameState.d("elite")) * (0.6 + GameState.level_index * 0.15)

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
	add_child(mod)
	camera = Camera2D.new()
	camera.zoom = Vector2(Settings.zoom, Settings.zoom)
	Settings.changed.connect(func(): camera.zoom = Vector2(Settings.zoom, Settings.zoom))
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
	player.add_child(make_light(pal.get("light", Color(1.0, 0.85, 0.6)), 2.2, 0.85, Vector2(0, -10)))

# ---------------------------------------------------------------- boucle
func _process(delta: float) -> void:
	if player == null:
		return
	# Caméra : suit le joueur, regarde un peu devant lui
	camera.global_position = player.global_position + Vector2(player.facing * 50.0, -40.0)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt
	shake_amt = move_toward(shake_amt, 0.0, delta * 40.0)
	flash = move_toward(flash, 0.0, delta * 3.0)

	var pp: Vector2 = player.global_position
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
		show_message("Cape d'Ombre-Vive obtenue !\n%s pour faire une Ruée" % Controls.label("dash"), 4.0)
	# Déclenchement du boss
	if boss and not boss_started and not boss_dead and entry_gate and pp.x > entry_gate.rect.end.x + TILE * 3:
		boss_started = true
		entry_gate.set_closed(true)
		boss.wake()
		Audio.play_boss(level.get("boss_music", "res://music/boss_gardien_du_puits.ogg"))
		shake(10)
		show_message(boss.boss_name.to_upper(), 3.0)
	# Panneaux du tutoriel
	sign_text = ""
	for sg in signs:
		if pp.distance_to(sg[0].position + Vector2(0, -20)) < 70.0:
			sign_text = fmt(sg[1]["text"])
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
			if pk[1] == "charm":
				GameState.add_charm(pk[2])
				Audio.sfx("pickup", 0.0)
				show_message("Emblème obtenu : %s\nÉquipe-le depuis l'inventaire (%s) en te reposant sur un banc." % [GameState.charm(pk[2])["name"], Controls.label("inventory")], 4.5)
			else:
				GameState.add_notch(pk[2])
				Audio.sfx("pickup", 0.0)
				show_message("Encoche d'emblème obtenue !\nEncoches : %d" % GameState.prog["notches"], 3.5)
			spawn_burst(prop.position, Color(1.0, 0.92, 0.65), 30, 220.0, 0.0)
			shake(6)
			prop.queue_free()
			pickups.erase(pk)
	# Passage vers le niveau suivant
	if exit_door and not leaving and pp.distance_to(exit_door.position + Vector2(0, -20)) < 40:
		leaving = true
		show_message("…", 1.0)
		spawn_burst(exit_door.position + Vector2(0, -30), Color(0.6, 0.85, 1.0), 40, 200.0, -50.0)
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
		show_message("Vous avez rallumé la Lanterne des Profondeurs.\nPartie n° %d terminée — merci d'avoir joué !  (%s : nouvelle partie)" % [GameState.run_seed, Controls.pause_label()], 9999.0)

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

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount * Settings.shake)
	# Vibration de la manette (XInput) proportionnelle à la secousse
	Controls.rumble(amount / 20.0, amount / 16.0 if amount >= 8.0 else 0.0, 0.08 + amount / 80.0)

func hit_stop(duration: float) -> void:
	if not Settings.hitstop:
		return
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func show_message(text: String, duration: float = 2.5) -> void:
	if hud:
		hud.message = text
		hud.message_t = duration

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
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)

# ---------------------------------------------------------------- événements
func on_enemy_killed(e, geo: int) -> void:
	player.geo += geo
	Audio.sfx("kill")
	spawn_burst(e.global_position, Color(0.95, 0.9, 0.75), 18, 220.0)
	shake(4)

func on_player_hurt() -> void:
	Audio.sfx("hurt")
	shake(12)
	hit_stop(0.12)
	spawn_burst(player.global_position, Color(0.1, 0.08, 0.15), 16, 200.0)

func on_player_died() -> void:
	show_message("Vous avez sombré...", 2.0)
	spawn_burst(player.global_position, Color(0.15, 0.1, 0.2), 40, 260.0)
	await get_tree().create_timer(1.6).timeout
	# Mort définitive (sauf dans le tutoriel) : la partie est terminée
	if not GameState.is_tutorial():
		Audio.stop_music()
		var summary := "Vous avez sombré dans %s (niveau %d / %d, %s).\nÉclats : %d — Emblèmes : %d — Partie n° %d" % [
			level["name"], GameState.level_index, GameState.RUN_LENGTH, GameState.diff_name(),
			player.geo, GameState.prog["owned"].size(), GameState.run_seed]
		menu.open_game_over(summary)
		return
	if boss_started and not boss_dead:
		boss_started = false
		boss.reset()
		entry_gate.set_closed(false)
		Audio.resume_level()
	player.geo = player.geo / 2
	player.respawn(respawn_pos)
	respawn_enemies()

func on_boss_killed() -> void:
	boss_dead = true
	player.geo += 50
	spawn_burst(boss.global_position, Color(1.0, 0.7, 0.4), 70, 380.0)
	shake(18)
	hit_stop(0.25)
	if entry_gate:
		entry_gate.set_closed(false)
	if exit_gate:
		exit_gate.set_closed(false)
	Audio.resume_level()
	show_message("%s est vaincu%s.\nLa voie est ouverte." % [boss.boss_name, "e" if boss.variant == 2 else ""], 4.0)

func on_parry(pos: Vector2) -> void:
	Audio.sfx("parry")
	spawn_burst(pos, Color(1, 1, 1), 14, 260.0, 0.0)
	shake(7)
	hit_stop(0.09)
	Controls.rumble(0.8, 0.3, 0.12)

func on_ultimate_charge(p) -> void:
	spawn_burst(p.global_position, Color(1.0, 0.85, 0.5), 20, 140.0, -200.0)
	Controls.rumble(0.3, 0.0, ULT_RUMBLE)

const ULT_RADIUS := 260.0
const ULT_DAMAGE := 8
const ULT_RUMBLE := 0.5

# Onde de choc de l'ultime : gros dégâts à tout ce qui est dans le rayon, détruit les spores.
func ultimate_blast(pos: Vector2) -> void:
	Audio.sfx("ult", 0.0)
	var ring := Node2D.new()
	ring.set_script(RingScript)
	ring.radius = ULT_RADIUS
	ring.position = pos
	add_child(ring)
	flash = 1.0
	shake(18)
	hit_stop(0.12)
	spawn_burst(pos, Color(1.0, 0.9, 0.6), 60, 420.0, 0.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var c: Vector2 = e.get_rect().get_center()
		if c.distance_to(pos) <= ULT_RADIUS + e.size.x / 2.0:
			e.take_hit(ULT_DAMAGE, (c - pos).normalized())
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if is_instance_valid(pr) and pr.hostile and pr.global_position.distance_to(pos) <= ULT_RADIUS:
			pr.pop()

# Coquille Épineuse : riposte quand le joueur est touché
func thorns_burst(pos: Vector2) -> void:
	spawn_burst(pos, Color(0.6, 0.85, 0.5), 24, 300.0, 0.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e.get_rect().get_center().distance_to(pos) < 110.0:
			e.take_hit(3, (e.get_rect().get_center() - pos).normalized())

func spawn_projectile(pos: Vector2, vel: Vector2) -> void:
	var pr := Node2D.new()
	pr.set_script(ProjectileScript)
	pr.main = self
	pr.vel = vel
	pr.position = pos
	add_child(pr)
	pr.add_child(make_light(Color(0.85, 0.5, 1.0), 0.6, 0.8))

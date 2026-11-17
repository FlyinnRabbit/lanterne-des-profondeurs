extends SceneTree
# Bande-annonce v2 : captures (Movie Maker) avec un pilote qui JOUE vraiment —
# arrêts, combos, pogo, parades, ruées, esquives, sauts de plateforme en plateforme.
#   godot --path . --write-movie x.avi --fixed-fps 30 -s tests/trailer_capture2.gd -- <scène> <langue>
# Scènes : title, hub, explore:<biome>, grotte, combat, boss:<id>, ending
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
const TILE := 32.0

var scene := ""
var lang := "fr"
var main
var pl
var gs
var t := 0
var rng := RandomNumberGenerator.new()
var held := {}           # action -> image où la relâcher (-1 : tenue)
var combo := 0
var rest := 0
var evade_cd := 0
var parry_cd := 0
var dash_cd := 0
var stuck_x := 0.0
var stuck_t := 0
var pause_t := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	scene = a[0] if a.size() > 0 else "title"
	lang = a[1] if a.size() > 1 else "fr"
	rng.seed = 1234 + scene.hash() % 1000
	_run()

# ---------------------------------------------------------------- entrées
func _f(n: int) -> void:
	for i in n:
		_tick_inputs()
		_immortal()
		await process_frame

func _tap(act: String, n := 3) -> void:
	Input.action_press(act)
	held[act] = t + n

func _hold(act: String) -> void:
	Input.action_press(act)
	held[act] = -1

func _rel(act: String) -> void:
	Input.action_release(act)
	held.erase(act)

func _rel_all() -> void:
	for a in held.keys():
		Input.action_release(a)
	held.clear()

func _tick_inputs() -> void:
	t += 1
	for a in held.keys():
		if held[a] >= 0 and t >= held[a]:
			Input.action_release(a)
			held.erase(a)

func _immortal() -> void:
	if main and is_instance_valid(main) and main.hud:
		main.hud.message_t = 0.0
	if is_instance_valid(pl):
		pl.hp = pl.max_hp
		pl.soul = maxi(pl.soul, 50)

func _move(dir: float) -> void:
	if dir > 0:
		_rel("move_left"); _hold("move_right")
	elif dir < 0:
		_rel("move_right"); _hold("move_left")
	else:
		_rel("move_left"); _rel("move_right")

# ---------------------------------------------------------------- pilote
func _target(max_dx := 380.0):
	var best = null
	var bd := 1e9
	var p: Vector2 = pl.global_position
	for e in get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or not e.visible:
			continue
		if "state" in e and str(e.state) == "sleep":
			continue
		var d: Vector2 = e.global_position - p
		if absf(d.x) > max_dx or absf(d.y) > 170:
			continue
		if main.wall_between(p + Vector2(0, -10), e.global_position):
			continue
		if d.length() < bd:
			bd = d.length()
			best = e
	return best

func _threat() -> bool:
	var p: Vector2 = pl.global_position
	for pr in get_nodes_in_group("projectiles"):
		if not is_instance_valid(pr) or not pr.hostile:
			continue
		var d: Vector2 = p - pr.global_position
		if d.length() < 75 and pr.vel.dot(d) > 0:
			return true
	return false

# Un pas de jeu : se bat s'il y a quelqu'un, sinon avance (dir) en franchissant les obstacles.
func _step(dir: float) -> void:
	if not is_instance_valid(pl):
		return
	var p: Vector2 = pl.global_position
	var floor_ok: bool = pl.is_on_floor()
	evade_cd = maxi(evade_cd - 1, 0)
	parry_cd = maxi(parry_cd - 1, 0)
	dash_cd = maxi(dash_cd - 1, 0)
	if parry_cd == 0 and _threat():
		_tap("parry", 3)
		parry_cd = 40
		return
	var e = _target()
	if e:
		var d: Vector2 = e.global_position - p
		var s := signf(d.x) if absf(d.x) > 3 else float(pl.facing)
		var tele: bool = e.telegraph() > 0 if e.has_method("telegraph") else false
		if e.is_boss and e.has_method("telegraphing"):
			tele = e.telegraphing()
		# esquive : l'ennemi prépare un coup et on est à portée
		if tele and absf(d.x) < (170.0 if e.is_boss else 95.0) and evade_cd == 0:
			evade_cd = 50
			if rng.randf() < 0.55 and pl.can_dash:
				_move(-s)
				_tap("dash", 3)
			else:
				_move(s)
				_tap("jump", 16)
			rest = 8
			return
		# en l'air au-dessus de lui : pogo
		if not floor_ok and d.y > 14 and absf(d.x) < 46:
			_hold("down")
			if t % 6 == 0:
				_tap("attack", 3)
			return
		_rel("down")
		# au-dessus de nous (volant) : saut + coup vers le haut
		if d.y < -60 and absf(d.x) < 90:
			_move(s * 0.0 if absf(d.x) < 30 else s)
			if floor_ok:
				_tap("jump", 14)
			elif pl.velocity.y > -250 and t % 7 == 0:
				_hold("up")
				_tap("attack", 3)
			return
		_rel("up")
		if rest > 0:
			rest -= 1
			_move(0)
			return
		var reach := (110.0 if e.is_boss else 58.0)
		if absf(d.x) > reach:
			_move(s)
			# ruée + estoc pour fondre sur la cible de temps en temps
			if dash_cd == 0 and pl.can_dash and absf(d.x) > 150 and absf(d.x) < 260 and floor_ok and rng.randf() < 0.04:
				_tap("dash", 3)
				dash_cd = 70
				held["__estoc"] = t + 4
			if held.has("__estoc") and t >= held["__estoc"]:
				held.erase("__estoc")
				_tap("attack", 3)
			# saute vers une cible au sol de temps en temps pour un pogo
			if floor_ok and absf(d.x) < 150 and d.y > -20 and rng.randf() < 0.025:
				_tap("jump", 15)
			combo = 0
		else:
			_move(0)
			pl.facing = int(s)
			if t % 8 == 0:
				_tap("attack", 3)
				combo += 1
				if combo >= 3:
					combo = 0
					rest = 12 + rng.randi_range(0, 10)
					if rng.randf() < 0.35 and pl.can_dash:   # recul après la série
						_move(-s)
						_tap("dash", 3)
		return
	_rel("down"); _rel("up")
	# --------------- exploration
	if pause_t > 0:
		pause_t -= 1
		_move(0)
		return
	_move(dir)
	var ahead := p + Vector2(dir * 30.0, 0)
	var wall: bool = main.is_solid_at(ahead) or main.is_solid_at(ahead + Vector2(0, -24))
	var hole: bool = not main.is_solid_at(p + Vector2(dir * 44.0, 40)) and not main.is_solid_at(p + Vector2(dir * 44.0, 90)) and not main.is_solid_at(p + Vector2(dir * 44.0, 150))
	if floor_ok and (wall or hole):
		_tap("jump", 18)
		if hole and pl.can_dash:
			held["__airdash"] = t + 9
	elif floor_ok and rng.randf() < 0.012:
		_tap("jump", rng.randi_range(6, 16))     # petit saut, comme un joueur
	elif floor_ok and dash_cd == 0 and pl.can_dash and rng.randf() < 0.01:
		_tap("dash", 3)
		dash_cd = 80
	if held.has("__airdash") and t >= held["__airdash"]:
		held.erase("__airdash")
		if not pl.is_on_floor():
			_tap("dash", 3)
	if floor_ok and rng.randf() < 0.004:
		pause_t = rng.randi_range(8, 18)            # un temps d'arrêt pour regarder
	# coincé : saut + ruée, puis demi-tour
	if absf(p.x - stuck_x) > 6:
		stuck_x = p.x
		stuck_t = 0
	else:
		stuck_t += 1
		if stuck_t == 25:
			_tap("jump", 18)
		if stuck_t == 34 and pl.can_dash:
			_tap("dash", 3)

func _play(frames: int, dir := 1.0) -> void:
	for i in frames:
		_tick_inputs()
		_immortal()
		_step(dir)
		await process_frame
	_rel_all()

# Va jusqu'à x (au sol), en jouant ; s'arrête dessus.
func _goto(x: float, max_frames := 300) -> void:
	for i in max_frames:
		_tick_inputs()
		_immortal()
		var dx: float = x - pl.global_position.x
		if absf(dx) < 10:
			break
		_step(signf(dx))
		await process_frame
	_rel_all()

func _jump_up(dir: float, hold := 18, move_frames := 22) -> void:
	_move(dir)
	_tap("jump", hold)
	await _f(move_frames)
	_move(0)
	await _f(6)

# ---------------------------------------------------------------- niveaux
func _level(bid: String, sd: int, pal := 3, boss_ch := "") -> void:
	var b: Dictionary
	for bb in Biomes.all():
		if bb["id"] == bid:
			b = bb
	gs.run_seed = sd
	gs._cache.clear()
	var gen := LevelGen.new()
	gs._cache["%d-%d-1" % [sd, pal]] = {"name": b["name"], "map": gen.generate(b, sd, pal + 1, boss_ch, false, gs.DIFFS[1]),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": sd}
	gs.mode = "descent"
	gs.palier = pal
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await _attach()

func _attach() -> void:
	await process_frame
	await process_frame
	paused = false
	main = current_scene
	pl = main.player

func _run() -> void:
	await process_frame
	gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	st.set_value("music_volume", 0.0)
	st.show_fps = false
	st.show_hints = false
	st.gfx_quality = 0
	st.set_value("language", ["", "fr", "en", "es", "de"].find(lang))
	gs.difficulty = 1
	gs.curse = ""
	gs.prog["can_dash"] = true
	gs.prog["geo"] = 640
	match scene:
		"title":
			gs.show_title = true
			change_scene_to_file("res://main.tscn")
			await _f(30 * 7)
		"hub":
			await _hub()
		"grotte":
			await _grotte()
		"combat":
			gs.show_title = false
			await _level("forge", 777, 4)
			await _f(12)
			await _play(30 * 5)
			pl.ult = pl.ULT_MAX
			await _play(30 * 1)
			_tap("ultimate", 3)
			await _f(28)
			await _play(30 * 3)
		"ending":
			gs.show_title = false
			await _level("ossuaire", 31, 7)
			await _f(5)
			main.play_ending("ombre")
			await _f(30 * 50)
		_:
			if scene.begins_with("explore:"):
				gs.show_title = false
				var bid := scene.substr(8)
				await _level(bid, 5100 + bid.length() * 7, 3)
				await _f(8)
				await _play(30 * 7)
			elif scene.begins_with("boss:"):
				await _boss(scene.substr(5))
	quit()

func _hub() -> void:
	gs.show_title = false
	gs.mode = "hub"
	gs.unlocked = 6
	gs.record = 5
	change_scene_to_file("res://main.tscn")
	await _attach()
	# assis au banc (colonne 26, sol rangée 17)
	var bench := Vector2(26 * TILE + 16, 17 * TILE)
	pl.global_position = bench + Vector2(0, -20)
	await _f(4)
	pl.sit(pl.global_position, false)
	await _f(40)
	# se lève, va voir la tailleuse puis le marchand
	await _goto(22 * TILE)
	await _f(10)
	await _goto(12.5 * TILE)
	pl.facing = -1
	await _f(26)
	# demi-tour : plateformes vers le haut du Sanctuaire
	await _goto(20.6 * TILE)
	await _jump_up(1.0, 18, 20)                 # plateforme rangée 13 (colonnes 22-26)
	await _goto(25.6 * TILE, 60)
	await _jump_up(1.0, 20, 24)                 # grande plateforme rangée 9 (colonnes 28-38)
	await _goto(37 * TILE, 120)
	_move(1); await _f(26); _move(0)            # redescend vers la forgeronne
	await _f(14)
	await _goto(35 * TILE, 60)
	pl.facing = 1
	await _f(16)
	# mannequin : série de coups puis tourbillon
	await _goto(46.3 * TILE, 120)
	pl.facing = 1
	for i in 3:
		_tap("attack", 3)
		await _f(8)
	await _f(10)
	_hold("attack"); await _f(24); _rel("attack")
	await _f(22)
	# l'ascenseur
	await _goto(52 * TILE, 120)
	await _f(8)
	main.hub_ui.open_elevator()
	await _f(40)
	main.hub_ui._choose_curse(4)
	await _f(30)
	main.hub_ui._descend(4, "")
	await _f(30 * 6)

func _grotte() -> void:
	gs.show_title = false
	await _level("jardins", 9100)
	var w = null
	for it in main.interactables:
		if it[1] == "winch":
			w = it[0]
			break
	pl.global_position = w.arrive + Vector2(-260, 0)
	await _f(15)
	await _goto(w.arrive.x + 20, 120)            # descend dans le puits
	_move(0)
	await _f(25)
	await _play(30 * 3, 1.0 if w.position.x > pl.global_position.x else -1.0)
	pl.global_position = w.position + Vector2(90, -18)
	await _f(10)
	await _goto(w.position.x, 60)
	_tap("up", 3)                               # le treuil
	await _f(30 * 3)

func _boss(id: String) -> void:
	gs.show_title = false
	var pal := 1
	for p in range(1, 8):
		if gs.boss_for(p) == id:
			pal = p
			break
	if id in gs.FINALS:
		pal = 7
		for sd in range(1, 400):
			gs.run_seed = sd
			gs._cache.clear()
			if gs.boss_for(7) == id:
				break
	gs.mode = "descent"
	gs.palier = pal
	gs.step = 2
	change_scene_to_file("res://main.tscn")
	await _attach()
	var boss = main.boss
	pl.global_position = Vector2(boss.home.x - 300.0, boss.home.y - 20.0)
	await _f(20)
	for i in 30 * 8:
		_tick_inputs()
		_immortal()
		_step(1.0)
		if i == 30 * 4 and is_instance_valid(boss) and boss.hp > boss.max_hp / 2:
			boss.take_hit(boss.hp - boss.max_hp / 2 + 1, Vector2.RIGHT)     # phase 2 pour le spectacle
		if is_instance_valid(boss) and boss.hp < 6:
			boss.hp = 6
		await process_frame
	_rel_all()

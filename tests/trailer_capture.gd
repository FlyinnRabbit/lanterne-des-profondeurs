extends SceneTree
# Capture d'une scène de bande-annonce (Movie Maker de Godot) :
#   godot --path . --write-movie /tmp/t/x.avi --fixed-fps 30 -s tests/trailer_capture.gd -- <scène>
# Scènes : title, biome:<id>, grotte, strate, combat, boss:<id>, hub
# Le héros est piloté (marche, saute, frappe) et ne peut pas mourir ; la musique est coupée
# (une seule piste est posée au montage), les bruitages restent.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")

var scene := ""
var lang := "fr"
var main
var pl
var t := 0

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	scene = a[0] if a.size() > 0 else "title"
	lang = a[1] if a.size() > 1 else "fr"
	_run()

func _f(n: int) -> void:
	for i in n:
		await process_frame

func _press(act: String, frames := 2) -> void:
	Input.action_press(act)
	await _f(frames)
	Input.action_release(act)

func _level(bid: String, sd: int, pal := 3, boss_ch := "") -> void:
	var gs = root.get_node("GameState")
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
	await process_frame
	await process_frame
	paused = false
	main = current_scene
	pl = main.player

func _immortal() -> void:
	if main and is_instance_valid(main) and main.hud:
		main.hud.message_t = 0.0      # pas de bandeau de texte pendant les plans de jeu
	if is_instance_valid(pl):
		pl.hp = pl.max_hp
		pl.soul = maxi(pl.soul, 66)

# pilote simple : avance, saute devant un mur ou un trou, frappe ce qui est devant
func _drive(frames: int, dir := 1.0) -> void:
	var act := "move_right" if dir > 0 else "move_left"
	Input.action_press(act)
	for i in frames:
		_immortal()
		t += 1
		if is_instance_valid(pl):
			var p: Vector2 = pl.global_position
			var ahead := p + Vector2(dir * 30.0, 0)
			var wall: bool = main.is_solid_at(ahead) or main.is_solid_at(ahead + Vector2(0, -24))
			var hole: bool = not main.is_solid_at(p + Vector2(dir * 40.0, 40)) and not main.is_solid_at(p + Vector2(dir * 40.0, 72))
			if pl.is_on_floor() and (wall or hole or t % 70 == 0):
				Input.action_press("jump")
			elif t % 70 == 18:
				Input.action_release("jump")
			var near := false
			for e in get_nodes_in_group("enemies"):
				if is_instance_valid(e) and not e.dead and absf(e.global_position.y - p.y) < 70 and (e.global_position.x - p.x) * dir > -10 and (e.global_position.x - p.x) * dir < 110:
					near = true
			if near and t % 9 == 0:
				Input.action_press("attack")
			elif t % 9 == 3:
				Input.action_release("attack")
		await process_frame
	for a2 in [act, "jump", "attack"]:
		Input.action_release(a2)

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	st.set_value("music_volume", 0.0)
	st.show_fps = false
	st.show_hints = false
	st.gfx_quality = 0
	st.set_value("language", ["", "fr", "en", "es", "de"].find(lang))
	gs.difficulty = 1
	gs.curse = ""
	match scene:
		"title":
			gs.show_title = true
			change_scene_to_file("res://main.tscn")
			await _f(30 * 7)
		"hub":
			gs.show_title = false
			gs.mode = "hub"
			gs.prog["unlocked"] = 6
			change_scene_to_file("res://main.tscn")
			await process_frame
			await process_frame
			paused = false
			main = current_scene
			pl = main.player
			pl.global_position = Vector2(14 * 32, 16 * 32)
			await _f(20)
			await _drive(30 * 6)
		"grotte":
			gs.show_title = false
			await _level("jardins", 9100)
			var w = null
			for it in main.interactables:
				if it[1] == "winch":
					w = it[0]
					break
			for e in get_nodes_in_group("enemies"):
				e.queue_free()
			pl.global_position = w.arrive + Vector2(-140, 0)
			await _f(20)
			await _drive(48)                       # tombe dans le puits
			await _f(30)
			pl.global_position = w.position + Vector2(90, -18)
			await _f(15)
			Input.action_press("move_left")
			await _f(26)
			Input.action_release("move_left")
			await _press("up", 3)                   # treuil
			await _f(30 * 3)
		"strate":
			gs.show_title = false
			await _level("cristal", 9100)
			var w2 = null
			for it in main.interactables:
				if it[1] == "winch" and it[0].top.y < it[0].position.y - 600:
					w2 = it[0]
					break
			pl.global_position = w2.arrive + Vector2(-60, 0)
			await _f(10)
			await _drive(30 * 4, 1.0 if w2.arrive.x < w2.position.x else -1.0)
			await _f(30)
		"combat":
			gs.show_title = false
			await _level("forge", 777)
			await _f(15)
			pl.ult = pl.ULT_MAX
			await _drive(30 * 2)
			await _press("ultimate", 3)
			await _f(30)
			await _drive(30 * 3)
		_:
			if scene.begins_with("biome:"):
				gs.show_title = false
				await _level(scene.substr(6), 4242 + scene.length())
				await _f(10)
				pl.global_position.x += 32 * 8
				await _drive(30 * 5)
			elif scene.begins_with("boss:"):
				var id := scene.substr(5)
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
				await process_frame
				await process_frame
				paused = false
				main = current_scene
				pl = main.player
				var boss = main.boss
				pl.global_position = Vector2(boss.home.x - 280.0, boss.home.y - 20.0)
				await _f(30)
				for i in 30 * 6:
					_immortal()
					t += 1
					if is_instance_valid(boss):
						var dx: float = boss.global_position.x - pl.global_position.x
						pl.facing = signf(dx) if absf(dx) > 4 else pl.facing
						if absf(dx) > 120:
							Input.action_press("move_right" if dx > 0 else "move_left")
						else:
							Input.action_release("move_right")
							Input.action_release("move_left")
						if absf(dx) < 140 and t % 10 == 0:
							Input.action_press("attack")
						elif t % 10 == 4:
							Input.action_release("attack")
						if t % 55 == 0 and pl.is_on_floor():
							Input.action_press("jump")
						elif t % 55 == 14:
							Input.action_release("jump")
						if i == 30 * 3 and is_instance_valid(boss):
							boss.take_hit(boss.hp - boss.max_hp / 2 + 1, Vector2.RIGHT)   # phase 2
					await process_frame
	quit()

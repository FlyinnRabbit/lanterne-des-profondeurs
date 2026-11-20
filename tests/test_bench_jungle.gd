extends SceneTree
# Jungle Noyée : chaque banc doit soigner (graines et profondeurs variées, toutes difficultés).
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.record = 15
	gs.unlocked = 15
	var b: Dictionary = {}
	for x in Biomes.all():
		if x["id"] == (OS.get_environment("BIOME") if OS.get_environment("BIOME") != "" else "jungle"):
			b = x
	var bad := 0
	var total := 0
	for sd in 8:
		var diff_i := sd % 4
		gs.difficulty = diff_i
		var depth := 1 + sd * 2
		gs.run_seed = 300 + sd
		var gen := LevelGen.new()
		var diff: Dictionary = gs.DIFFS[diff_i].duplicate()
		var seed := 900 + sd * 37
		gs._cache["%d-%d-%d" % [gs.run_seed, depth, 1]] = {"name": b["name"], "map": gen.generate(b, seed, depth, "", false, diff),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": seed}
		gs.mode = "descent"
		gs.palier = depth
		gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		var main = current_scene
		await _frames(20)
		for bp in main.benches:
			total += 1
			var pl = main.player
			# on retire les ennemis : on vérifie le banc, pas la tranquillité du coin
			for e in get_nodes_in_group("enemies"):
				e.queue_free()
			for pr in get_nodes_in_group("projectiles"):
				pr.queue_free()
			await _frames(200)
			pl.hp = 1
			pl.global_position = bp + Vector2(-10, 0)
			pl.velocity = Vector2.ZERO
			await _frames(40)
			var lock: float = pl.bench_lock_t
			var onf: bool = pl.is_on_floor()
			var d: float = pl.global_position.distance_to(bp)
			Input.action_press("up")
			await _frames(3)
			Input.action_release("up")
			await _frames(5)
			var ok: bool = pl.sitting and pl.hp == pl.max_hp
			if not ok:
				bad += 1
				print("PROBLÈME graine %d palier %d banc %s : assis %s, vie %d/%d, au sol %s, distance %.0f, verrou %.2f, message « %s »" % [sd, depth, bp, pl.sitting, pl.hp, pl.max_hp, onf, d, lock, main.hud.msg_label.text if "msg_label" in main.hud else "?"])
			Input.action_press("move_right")
			await _frames(30)
			Input.action_release("move_right")
			await _frames(10)
	print("bancs testés : %d, problèmes : %d" % [total, bad])
	print("RÉSULTAT : ", "OK" if bad == 0 else "ÉCHEC")
	quit()

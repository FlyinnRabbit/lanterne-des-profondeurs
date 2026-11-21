extends SceneTree
# Vérifie qu'on peut toujours s'asseoir sur un banc puis en repartir (tous les biomes, plusieurs graines).
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	RenderingServer.render_loop_enabled = false   # aucun dessin nécessaire : test plus rapide
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	var all: Array = Biomes.all()
	var bad := 0
	var total := 0
	for sd in 3:
		for i in all.size():
			var b: Dictionary = all[i]
			gs.run_seed = 100 + sd
			var gen := LevelGen.new()
			var diff: Dictionary = gs.DIFFS[2].duplicate()
			gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, 500 + sd * 91 + i * 17, 3, "", false, diff),
				"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 500 + sd * 91 + i * 17}
			gs.mode = "descent"
			gs.palier = 2
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
				pl.global_position = bp + Vector2(-10, 0)
				pl.velocity = Vector2.ZERO
				pl.bench_lock_t = 0.0   # délai banc remis à zéro (on vient d'être téléporté)
				await _frames(30)
				var onf: bool = pl.is_on_floor()
				Input.action_press("up")
				await _frames(4)
				await process_frame
				Input.action_release("up")
				await _frames(10)
				var sat: bool = pl.sitting
				var x0: float = pl.global_position.x
				Input.action_press("move_right")
				await _frames(40)
				Input.action_release("move_right")
				var moved: float = pl.global_position.x - x0
				if not sat or pl.sitting or absf(moved) < 20.0:
					bad += 1
					print("PROBLÈME %s graine %d banc %s : au sol %s, assis %s, encore assis %s, déplacement %.0f, pos %s" % [b["id"], sd, bp, onf, sat, pl.sitting, moved, pl.global_position])
				await _frames(5)
	print("bancs testés : %d, problèmes : %d" % [total, bad])
	quit()

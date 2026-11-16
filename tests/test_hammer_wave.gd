extends SceneTree
# Marteau niv.2 : l'onde de choc du coup final survit-elle sur un vrai sol de niveau (relief, bords) ?
# Fouet niv.2 : attire-t-il les petits ennemis ?
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
	gs.unlocked = 5
	var b: Dictionary = Biomes.all()[0]
	var gen := LevelGen.new()
	var d: Dictionary = gs.DIFFS[1].duplicate()
	d["count"] = 0
	gs.run_seed = 91
	gs._cache["91-1-1"] = {"name": b["name"], "map": gen.generate(b, 3333, 1, "", false, d), "music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 3333}
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(60)
	var pl = main.player
	gs.prog["weapon"] = "marteau"
	gs.prog["weapon_lv"] = {"marteau": 2}
	var spots := 0
	var ok := 0
	var x0: float = pl.global_position.x
	for s in 12:
		pl.global_position = Vector2(x0 + s * 160.0, pl.global_position.y - 40.0)
		pl.velocity = Vector2.ZERO
		await _frames(90)
		if not pl.is_on_floor():
			continue
		spots += 1
		for pr in get_nodes_in_group("projectiles"):
			pr.queue_free()
		pl.combo_i = 1
		pl.combo_t = 1.0
		pl.attack_cd = 0.0
		Input.action_press("attack")
		await _frames(2)
		Input.action_release("attack")
		await _frames(12)
		if pl.attack_t <= 0.0 and pl.attack_cd <= 0.0:
			continue          # le coup n'est pas parti (recul, etc.) : position ignorée
		var waves := 0
		for pr in get_nodes_in_group("projectiles"):
			if is_instance_valid(pr) and pr.kind == "wave" and not pr.hostile:
				waves += 1
		if waves > 0:
			ok += 1
		else:
			print("  pas d'onde à x=%d y=%d, kind=%s" % [pl.global_position.x, pl.global_position.y, pl.attack_kind])
			var cx := int(pl.global_position.x / 32)
			var cy := int(pl.global_position.y / 32)
			for yy in range(cy - 2, cy + 3):
				var row := ""
				for xx in range(cx - 4, cx + 5):
					row += "P" if (xx == cx and yy == cy) else ("#" if main.solid.has(Vector2i(xx, yy)) else ".")
				print("    ", row)
	print("marteau niv.2 : onde encore présente 0,1 s après le coup final sur %d / %d positions" % [ok, spots])
	quit()

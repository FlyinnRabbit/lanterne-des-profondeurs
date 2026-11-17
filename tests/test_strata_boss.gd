extends SceneTree
# Niveau en strates avec boss : être au-dessus de l'arène (même abscisse) ne lance pas le combat.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	for bid in ["glace", "cristal", "forge", "profondeurs"]:
		var b: Dictionary
		for bb in Biomes.all():
			if bb["id"] == bid:
				b = bb
		gs.run_seed = 4321
		gs._cache.clear()
		var gen := LevelGen.new()
		gs._cache["4321-2-2"] = {"name": b["name"], "map": gen.generate(b, 4321, 3, "Q", false, gs.DIFFS[1]), "music": b["music"],
			"boss_id": "queen", "boss_music": "", "palette": b["pal"], "seed": 4321}
		gs.mode = "descent"
		gs.palier = 2
		gs.step = 2
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(10)
		var main = current_scene
		var g = main.entry_gate
		var pl = main.player
		# étage du haut, bien à droite de la grille
		pl.global_position = Vector2(g.rect.end.x + 200, 6 * 32)
		var x_top: float = pl.global_position.x
		await _f(40)
		var early: bool = main.boss_started
		# dans l'arène
		pl.global_position = Vector2(g.rect.end.x + 160, g.rect.end.y - 20)
		await _f(40)
		var started: bool = main.boss_started
		print("%-12s grille y=%d..%d ; au-dessus : combat=%s ; dans l'arène : combat=%s" % [bid, g.rect.position.y, g.rect.end.y, early, started])
		if early or not started:
			ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

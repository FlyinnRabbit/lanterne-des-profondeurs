extends SceneTree
# Treuils : chaque grotte et chaque passage entre strates a un treuil qui remonte le héros en haut.
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
	var total := 0
	for bid in ["jardins", "cristal", "ruche", "glace"]:
		gs.difficulty = 1
		gs.mode = "descent"
		gs.palier = 2
		gs.step = 1
		gs.curse = ""
		gs.run_seed = 777
		gs._cache.clear()
		var LevelGen = load("res://scripts/levelgen.gd")
		var Biomes = load("res://scripts/biomes.gd")
		var b: Dictionary
		for bb in Biomes.all():
			if bb["id"] == bid:
				b = bb
		var gen = LevelGen.new()
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, 9100, 3, "", false, {"count": 1.0}),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 9100}
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(10)
		var main = current_scene
		for e in get_nodes_in_group("enemies"):
			e.queue_free()
		var winches := []
		for it in main.interactables:
			if it[1] == "winch":
				winches.append(it[0])
		var res := []
		for w in winches:
			total += 1
			var pl = main.player
			pl.global_position = w.position + Vector2(10, -18)
			pl.velocity = Vector2.ZERO
			await _f(30)
			Input.action_press("up")
			await _f(2)
			Input.action_release("up")
			await create_timer(2.2, true, true).timeout
			var d: float = pl.global_position.distance_to(w.arrive)
			var good: bool = d < 24.0 and pl.is_on_floor()
			res.append("%s(%.0f)" % ["✔" if good else "✗", d])
			if not good:
				ok = false
		print("%-12s : %d treuils  %s  taille %dx%d" % [bid, winches.size(), " ".join(res), main.map_size.x, main.map_size.y])
		if winches.size() < 2:
			ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC", " (", total, " treuils)")
	quit()

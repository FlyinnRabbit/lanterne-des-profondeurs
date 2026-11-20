extends SceneTree
# Niveau en strates (Mines) : la carte garde les 3 strates parcourues.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var b: Dictionary = {}
	for x in Biomes.all():
		if x["id"] == "cristal":
			b = x
	gs.run_seed = 77
	var gen := LevelGen.new()
	gs._cache["%d-%d-%d" % [gs.run_seed, 3, 1]] = {"name": b["name"], "map": gen.generate(b, 321, 5, "", false, gs.DIFFS[1]),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 321}
	gs.mode = "descent"; gs.palier = 3; gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	print("taille de la carte : ", main.map_size)
	# parcours : chaque case d'air au-dessus d'un sol, de gauche à droite, strate par strate
	var T: int = main.TILE
	var visited := 0
	for y in range(0, main.map_size.y, 6):
		for x in range(0, main.map_size.x, 10):
			if not main.solid.has(Vector2i(x, y)):
				main.player.global_position = Vector2(x * T + 16, y * T + 16)
				main._reveal()
				visited += 1
	var bands := [0, 0, 0]
	var h3: int = main.map_size.y / 3
	for y in main.map_size.y:
		for x in main.map_size.x:
			if main.is_explored(x, y):
				bands[mini(y / h3, 2)] += 1
	print("cases explorées par tiers de hauteur : ", bands)
	var ok: bool = bands[0] > 0 and bands[1] > 0 and bands[2] > 0
	main.player.global_position = Vector2(main.map_size.x * T * 0.5, main.map_size.y * T * 0.8)
	for i in 10: await physics_frame
	main.map_view.toggle()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	if "--shots" in OS.get_cmdline_user_args():
		root.get_viewport().get_texture().get_image().save_png("/tmp/shots/map_mines.png")
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

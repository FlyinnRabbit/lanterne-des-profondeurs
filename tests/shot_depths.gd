extends SceneTree
# Captures : grotte (jardins), puits entre strates (cristal), et carte d'un niveau en strates.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _load(gs, bid: String, sd: int):
	var LevelGen = load("res://scripts/levelgen.gd")
	var Biomes = load("res://scripts/biomes.gd")
	var b: Dictionary
	for bb in Biomes.all():
		if bb["id"] == bid:
			b = bb
	gs.mode = "descent"
	gs.palier = 2
	gs.step = 1
	gs.run_seed = sd
	gs._cache.clear()
	var gen = LevelGen.new()
	gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, sd, 3, "", false, {"count": 1.0}),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": sd}
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
func _snap(name: String) -> void:
	current_scene.hud.message_t = 0.0   # pas de message par-dessus la capture
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/depth_%s.png" % name)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.prog["map_full"] = true
	for bid in ["jardins", "bibliotheque", "ruche", "citadelle", "ossuaire", "forge"]:
		await _load(gs, bid, 9100)
		var main = current_scene
		var w = null
		for it in main.interactables:
			if it[1] == "winch":
				w = it[0]
				break
		if w:
			main.player.global_position = w.position + Vector2(110, -18)
			await _f(420)
			await _snap("grotte_" + bid)
	await _load(gs, "cristal", 9100)
	var m2 = current_scene
	var low = null
	for it in m2.interactables:
		if it[1] == "winch" and it[0].top.y < it[0].position.y - 600:
			low = it[0]
	m2.player.global_position = low.position + Vector2(40, -18)
	await _f(420)
	await _snap("strate_bas")
	m2.player.global_position = low.arrive + Vector2(-60, 0)
	await _f(90)
	await _snap("strate_haut")
	m2.explored.fill(1)
	m2.map_view.toggle()
	await _f(10)
	await _snap("carte")
	quit()

extends SceneTree
# Banc d'essai : coût par image sur plusieurs niveaux (chemin, grotte, strates) et au Sanctuaire.
# Lancer avec un écran (Xvfb) : les appels de dessin et le temps de rendu comptent.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
var results := []
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await process_frame
func _measure(label: String) -> void:
	await _f(30)
	var tp := 0.0
	var tph := 0.0
	var dc := 0.0
	var prim := 0.0
	var frames := 120
	var t0 := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		tp += Performance.get_monitor(Performance.TIME_PROCESS)
		tph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var dt := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	var line := "%-34s image %6.2f ms | process %5.2f | physique %5.2f | dessins %5d | primitives %7d | nœuds %d" % [label, dt, tp / frames * 1000.0, tph / frames * 1000.0, int(dc / frames), int(prim / frames), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]
	print(line)
	results.append(line)
func _level(bid: String, sd: int) -> void:
	var gs = root.get_node("GameState")
	var b: Dictionary
	for bb in Biomes.all():
		if bb["id"] == bid:
			b = bb
	gs.run_seed = sd
	gs._cache.clear()
	var gen := LevelGen.new()
	gs._cache["%d-3-1" % sd] = {"name": b["name"], "map": gen.generate(b, sd, 4, "", false, gs.DIFFS[2]),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": sd}
	gs.difficulty = 2
	gs.mode = "descent"
	gs.palier = 3
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _measure("Sanctuaire")
	for bid in ["jardins", "forge", "cristal"]:
		await _level(bid, 5151)
		var main = current_scene
		await _measure("%s : départ" % bid)
		for q in [1, 2]:
			root.get_node("Settings").set_value("gfx_quality", q)
			await _measure("%s : départ (qualité %s)" % [bid, ["haute", "équilibrée", "basse"][q]])
		root.get_node("Settings").set_value("gfx_quality", 0)
		var w = null
		for it in main.interactables:
			if it[1] == "winch":
				w = it[0]
		if w:
			main.player.global_position = w.position + Vector2(40, -18)
			await _measure("%s : grotte / puits" % bid)
		main.player.global_position = Vector2(main.map_size.x * 32 * 0.5, main.player.global_position.y)
	print("FIN")
	quit()

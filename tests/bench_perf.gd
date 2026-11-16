extends SceneTree
# Mesure le coût par image d'un niveau (ennemis éveillés / endormis).
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	var b: Dictionary = Biomes.all()[0]
	gs.run_seed = 4242
	var gen := LevelGen.new()
	var diff: Dictionary = gs.DIFFS[2].duplicate()
	gs._cache["4242-3-1"] = {"name": b["name"], "map": gen.generate(b, 1000, 3, "", false, diff),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 1000}
	gs.mode = "descent"
	gs.palier = 3
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	for i in 120:
		await physics_frame
	var n := 0
	var awake := 0
	for e in get_nodes_in_group("enemies"):
		n += 1
		if e.can_process():
			awake += 1
	var tp := 0.0
	var tph := 0.0
	var frames := 240
	var t0 := Time.get_ticks_usec()
	for i in frames:
		await process_frame
		tp += Performance.get_monitor(Performance.TIME_PROCESS)
		tph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var dt := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	print("ennemis %d, éveillés %d | process %.2f ms, physique %.2f ms, image %.2f ms | objets dessinés %d" % [n, awake, tp / frames * 1000.0, tph / frames * 1000.0, dt, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
	await _measure("jeu normal")
	main.set_process(false)
	for e in get_nodes_in_group("sleepy"):
		e.process_mode = Node.PROCESS_MODE_INHERIT
	await _measure("tout réveillé (ancien comportement)")
	for e in get_nodes_in_group("enemies"):
		e.process_mode = Node.PROCESS_MODE_DISABLED
	await _measure("ennemis endormis")
	for e in get_nodes_in_group("enemies"):
		e.visible = false
	await _measure("ennemis cachés")
	for k in ["prop.gd", "trap.gd", "platform.gd"]:
		for ch in main.get_children():
			var sc = ch.get_script()
			if sc and sc.resource_path.get_file() == k:
				ch.process_mode = Node.PROCESS_MODE_DISABLED
	await _measure("+ props/pièges endormis")
	for ch in main.get_children():
		var sc = ch.get_script()
		if sc and sc.resource_path.get_file() in ["ambience.gd", "background.gd"]:
			ch.visible = false
			ch.process_mode = Node.PROCESS_MODE_DISABLED
			await _measure("+ sans " + sc.resource_path.get_file())
	for ch in main.get_children():
		var sc = ch.get_script()
		if sc and sc.resource_path.get_file() == "level_art.gd":
			ch.visible = false
			await _measure("+ sans level_art")
	for ch in main.get_children():
		if ch is CanvasLayer:
			ch.visible = false
	await _measure("+ sans CanvasLayers (HUD, vignette)")
	quit()

func _measure(label: String) -> void:
	for i in 10:
		await process_frame
	var t0 := Time.get_ticks_usec()
	for i in 60:
		await process_frame
	print("  %-38s image %.1f ms, appels de dessin %d" % [label, (Time.get_ticks_usec() - t0) / 60000.0, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])

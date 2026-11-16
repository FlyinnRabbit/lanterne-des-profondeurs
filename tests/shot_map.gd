extends SceneTree
# Captures de la carte et de la mini-carte avec leurs repères. Usage : -- <prefixe>
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _snap(name: String) -> void:
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s.png" % name)
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "map"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	gs.record = 5
	# Sanctuaire
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(40)
	for i in main.explored.size():
		main.explored[i] = 1
	await _snap(pre + "_hub_mini")
	main.map_view.toggle()
	await _snap(pre + "_hub")
	main.map_view.toggle()
	# niveau de descente avec salles spéciales
	var b: Dictionary = Biomes.all()[2]
	for sd in 30:
		var gen := LevelGen.new()
		var map: Array = gen.generate(b, 9100 + sd, 3, "", false, gs.DIFFS[1].duplicate())
		var txt := "".join(map)
		if txt.contains("R") and txt.contains("T") and txt.contains("M"):
			gs.run_seed = 55
			gs._cache["55-2-1"] = {"name": b["name"], "map": map, "music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 9100 + sd}
			break
	gs.mode = "descent"
	gs.palier = 2
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	main = current_scene
	await _frames(40)
	for i in main.explored.size():
		main.explored[i] = 1
	main.map_view.toggle()
	await _snap(pre + "_niveau")
	print("ok carte")
	quit()

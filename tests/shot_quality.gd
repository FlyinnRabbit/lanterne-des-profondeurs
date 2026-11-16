extends SceneTree
# Captures des trois niveaux de qualité graphique sur le même endroit.
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	gs.show_title = false
	var b: Dictionary
	for bb in Biomes.all():
		if bb["id"] == "jardins":
			b = bb
	gs.run_seed = 5151
	var gen := LevelGen.new()
	gs._cache["5151-3-1"] = {"name": b["name"], "map": gen.generate(b, 5151, 4, "", false, gs.DIFFS[1]), "music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 5151}
	gs.mode = "descent"
	gs.palier = 3
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	main.player.global_position.x += 420
	for i in 200:
		await process_frame
	for q in 3:
		st.set_value("gfx_quality", q)
		main.hud.message_t = 0.0
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/quality_%d.png" % q)
	st.set_value("gfx_quality", 0)
	quit()

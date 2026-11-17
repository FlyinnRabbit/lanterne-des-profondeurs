extends SceneTree
# Aperçu des nouveaux biomes (jungle, désert, antique) avec un nouveau mob chacun
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
	var mobs := {"jungle": "res://scripts/slime.gd", "desert": "res://scripts/scorpion.gd", "antique": "res://scripts/goblin.gd"}
	var k := 0
	for b in Biomes.all():
		if not mobs.has(b["id"]):
			continue
		gs.run_seed = 500 + k
		var gen := LevelGen.new()
		var diff: Dictionary = gs.DIFFS[1].duplicate()
		gs._cache["%d-%d-%d" % [gs.run_seed, 2, 1]] = {"name": b["name"], "map": gen.generate(b, 700 + k * 13, 3, "", false, diff),
			"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 700 + k * 13}
		gs.mode = "descent"
		gs.palier = 2
		gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(10)
		var main = current_scene
		var pl = main.player
		for e in get_nodes_in_group("enemies"):
			if e.global_position.distance_to(pl.global_position) < 900:
				e.queue_free()
		pl.global_position.x += 260
		await _f(40)
		var feet: float = pl.get_rect().end.y
		for i in 2:
			var e := CharacterBody2D.new()
			e.set_script(load(mobs[b["id"]]))
			e.main = main
			e.position = pl.global_position + Vector2(90 + i * 70, -10)
			main.add_child(e)
		await _f(30)
		main.hud.visible = false
		await _f(3)
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("/tmp/biome_%s.png" % b["id"])
		k += 1
	quit()

extends SceneTree
# Gros plans du portail de fin dans chaque biome. Usage : -s tests/shot_doors.gd -- <prefixe> <index biome>
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	await process_frame
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var pre: String = args[0]
	var i := int(args[1])
	var gs = root.get_node("GameState")
	gs.show_title = false
	var b: Dictionary = Biomes.all()[i]
	gs.run_seed = 4242
	var key := "%d-%d-%d" % [gs.run_seed, 1, 1]
	var diff: Dictionary = gs.DIFFS[1].duplicate()
	diff["count"] = 0
	gs._cache[key] = {"name": b["name"], "map": LevelGen.new().generate(b, 1000 + i * 17, 1, "", false, diff),
		"music": b["music"], "boss_id": "", "boss_music": "", "palette": b["pal"], "seed": 1000 + i * 17}
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _frames(4)
	var main = current_scene
	main.hud.visible = false
	var d = main.exit_door
	main.player.global_position = d.global_position + Vector2(-120, -20)
	await _frames(30)
	paused = true
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2(3.0, 3.0)
	main.camera.limit_left = -100000
	main.camera.limit_right = 100000
	main.camera.limit_top = -100000
	main.camera.limit_bottom = 100000
	main.camera.global_position = d.global_position + Vector2(0, -60)
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_door_%s.png" % [pre, b["id"]])
	print("ok ", b["id"])
	quit()

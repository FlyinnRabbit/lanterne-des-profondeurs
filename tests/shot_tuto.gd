extends SceneTree
# Captures du tutoriel, de gauche à droite. Usage : -s tests/shot_tuto.gd -- <prefixe>
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	await process_frame
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "tutorial"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _frames(5)
	var main = current_scene
	var w: int = main.map_size.x
	var i := 0
	for x in range(12, w, 22):
		var fy := 1
		for y in range(main.map_size.y - 1, 0, -1):
			if not main.solid.has(Vector2i(x, y)) and main.solid.has(Vector2i(x, y + 1)):
				fy = y
				break
		main.player.global_position = Vector2(x * 32 + 16, fy * 32)
		main.player.velocity = Vector2.ZERO
		await _frames(40)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_tuto_%d.png" % [pre, i])
		i += 1
	print("ok tuto ", i)
	quit()

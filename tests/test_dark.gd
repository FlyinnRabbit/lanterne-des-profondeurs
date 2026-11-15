extends SceneTree
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
	for d in [2, 3]:
		gs.difficulty = d
		gs.mode = "hub"
		change_scene_to_file("res://main.tscn")
		paused = false
		await _frames(5)
		gs.start_descent(2, current_scene.player, "dark")
		await _frames(8)
		paused = false
		Engine.time_scale = 1.0
		var main = current_scene
		main.player.global_position.x += 300
		await _frames(90)
		print("difficulté %d : malédiction %s, voile %s" % [d, gs.curse, main.dark_rect != null])
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/dark_%d.png" % d)
		gs.step = 2
		gs.go_next_level(main.player) if false else null
	quit()

extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 5
	gs.unlocked = 6
	gs.difficulty = 2
	gs.prog["weapon"] = "fouet"
	change_scene_to_file("res://main.tscn")
	paused = false
	for i in 30:
		await physics_frame
	var main = current_scene
	main.player.global_position = Vector2(52 * 32, 16 * 32)
	for i in 30:
		await physics_frame
	Input.action_press("attack")
	await physics_frame
	await physics_frame
	Input.action_release("attack")
	main.hub_ui.open_elevator()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/lift_small.png")
	print("panneau : ", main.hub_ui.lift_panel.get_global_rect(), " écran ", root.get_viewport().get_visible_rect().size)
	quit()

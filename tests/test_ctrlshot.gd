extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	root.get_node("Settings").language = 1
	root.get_node("Lang").apply()
	root.get_node("Settings").kb_layout = 1
	change_scene_to_file("res://main.tscn")
	for i in 6:
		await process_frame
	current_scene.menu.open()
	current_scene.menu._open_controls()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/ctrl.png")
	root.get_node("Settings").kb_layout = 0
	root.get_node("Settings").language = 0
	quit()

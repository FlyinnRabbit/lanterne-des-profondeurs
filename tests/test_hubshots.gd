extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 7
	root.get_node("Settings").zoom = 1.0
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	for i in 5:
		await physics_frame
	var main = current_scene
	for x in [10, 30, 50]:
		main.player.global_position = Vector2(x * 32, 16 * 32)
		for i in 90:
			await physics_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/hub_%d.png" % x)
	quit()

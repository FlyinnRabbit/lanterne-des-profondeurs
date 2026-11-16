extends SceneTree
# Captures de l'animation de fin. Usage : -s tests/shot_ending.gd -- <prefixe>
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	for i in 8:
		await process_frame
	var main = current_scene
	main.play_ending("oeil")
	await process_frame
	var e = main.get_children()[-1]
	for tt in [4.0, 11.0, 22.0, 35.0, 45.0, 56.0]:
		e.t = tt
		e.view.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_ending_%d.png" % [pre, int(tt)])
	print("ok ending")
	quit()

extends SceneTree
# Gros plan de l'arsenal du Sanctuaire. Usage : -- <prefixe>
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 8:
		await physics_frame
	var main = current_scene
	main.hud.visible = false
	for n in main.get_children():
		if n.get("kind") == "arsenal":
			main.player.global_position = n.global_position + Vector2(-90, -30)
			for i in 40:
				await physics_frame
			paused = true
			main.camera.position_smoothing_enabled = false
			main.camera.zoom = Vector2(3.5, 3.5)
			main.camera.global_position = n.global_position + Vector2(-30, -55)
			for i in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_arsenal.png" % pre)
	paused = false
	main.hud.visible = true
	main.player.geo = 400
	main.hub_ui.open_arsenal()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_arsenal_menu.png" % pre)
	print("ok arsenal")
	quit()

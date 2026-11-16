extends SceneTree
# Gros plans des habitants du Sanctuaire. Usage : -s tests/shot_npc.gd -- <prefixe>
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var pre := "now"
	if OS.get_cmdline_user_args().size() > 0:
		pre = OS.get_cmdline_user_args()[0]
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 7
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	await _frames(5)
	var main = current_scene
	main.hud.visible = false
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2(2.4, 2.4)
	main.camera.limit_right = 100000
	main.camera.limit_left = -100000
	main.player.set_physics_process(false)
	main.player.visible = false
	for k in ["merchant", "smith", "cartographer", "elder"]:
		for n in main.get_children():
			if n.get("kind") == k:
				main.player.global_position = n.global_position + Vector2(-10, -40)
				main.camera.global_position = n.global_position + Vector2(-10, -50)
				await _frames(4)
				await RenderingServer.frame_post_draw
				root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_npc_%s.png" % [pre, k])
				print("ok ", k)
	quit()

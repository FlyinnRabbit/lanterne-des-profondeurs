extends SceneTree
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % n)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	for id in ["cerbere", "centaure", "oeil"]:
		for sd in range(1, 400):
			gs.run_seed = sd
			if gs.boss_for(7) == id:
				break
		gs._cache.clear()
		gs.mode = "descent"; gs.palier = 7; gs.step = 2
		change_scene_to_file("res://main.tscn")
		paused = false
		Engine.time_scale = 1.0
		await _frames(5)
		var main = current_scene
		var b = main.boss
		main.boss_started = true
		b.wake()
		main.player.global_position = b.home + Vector2(-260, -10)
		var want: String = {"cerbere": "windup_breath", "centaure": "windup_rain", "oeil": "windup_beam"}[id]
		var shot := false
		for f in 900:
			main.player.hp = main.player.max_hp
			main.player.invuln_t = 0.5
			if not shot and b.state == ("beam" if id == "oeil" else want):
				await _frames(10 if id != "oeil" else 4)
				for cam in current_scene.find_children("*", "Camera2D", true, false):
					cam.reset_smoothing()
				await _snap("final_" + id)
				shot = true
				break
			await physics_frame
		print(id, " capture : ", shot)
	# animation de fin
	var main2 = current_scene
	main2.play_ending("oeil")
	await process_frame
	var e = main2.get_children()[-1]
	for tt in [4.0, 11.0, 22.0, 35.0, 45.0, 56.0]:
		e.t = tt
		e.view.queue_redraw()
		await process_frame
		await _snap("ending_%d" % int(tt))
	quit()

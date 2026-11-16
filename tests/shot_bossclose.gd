extends SceneTree
# Gros plans des boss (réveillés, figés). Usage : -s tests/shot_bossclose.gd -- <prefixe> [id]
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var pre: String = args[0] if args.size() > 0 else "now"
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	var ids := ["gardien", "abbesse", "reine", "colosse", "ver", "chevalier", "ombre", "cerbere", "centaure", "oeil"]
	if args.size() > 1:
		ids = [args[1]]
	for id in ids:
		var pal := 1
		for p in range(1, 8):
			if gs.boss_for(p) == id:
				pal = p
				break
		if id in gs.FINALS:
			pal = 7
			for sd in range(1, 400):
				gs.run_seed = sd
				gs._cache.clear()
				if gs.boss_for(7) == id:
					break
		gs.mode = "descent"
		gs.palier = pal
		gs.step = 2
		change_scene_to_file("res://main.tscn")
		await process_frame   # le changement de scène est différé
		await process_frame
		paused = false
		await _frames(4)
		var main = current_scene
		var boss = main.boss
		var pl = main.player
		main.hud.visible = false
		pl.global_position = boss.global_position + Vector2(-260, -20)
		for f in 140:
			pl.hp = pl.max_hp
			pl.invuln_t = 1.0
			await physics_frame
		paused = true
		main.camera.position_smoothing_enabled = false
		main.camera.limit_left = -100000
		main.camera.limit_right = 100000
		main.camera.limit_top = -100000
		main.camera.limit_bottom = 100000
		main.camera.zoom = Vector2(2.2, 2.2)
		main.camera.global_position = boss.global_position + Vector2(0, -10)
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s_boss_%s.png" % [pre, id])
		print("ok ", id)
		paused = false
	quit()

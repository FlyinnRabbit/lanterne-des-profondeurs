extends SceneTree
# Captures : écran titre, carte, effets de combat, projectiles. Usage : -- <prefixe>
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	await process_frame
	for i in n:
		await physics_frame
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/%s.png" % n)
func _run() -> void:
	await process_frame
	var pre: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "now"
	var gs = root.get_node("GameState")
	# écran titre
	gs.show_title = true
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	for i in 20:
		await process_frame
	await _snap(pre + "_titre")
	print("titre ok")
	# options (thème des panneaux)
	current_scene.menu._open_options()
	for i in 4:
		await process_frame
	await _snap(pre + "_options")
	print("options ok")
	paused = false
	# descente : carte
	gs.show_title = false
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _frames(10)
	var main = current_scene
	main.player.global_position.x += 600
	await _frames(40)
	for x in range(int(main.map_size.x * 0.6)):
		for y in range(main.map_size.y):
			main.explored[y * main.map_size.x + x] = 1
	main.map_view.toggle()
	for i in 4:
		await process_frame
	await _snap(pre + "_carte")
	main.map_view.toggle()
	paused = false
	await _frames(4)
	# effets et projectiles, figés
	var p = main.player
	var base: Vector2 = p.global_position
	main.hud.visible = true
	var kinds := ["spore", "acid", "rock", "dart", "ember", "shuriken", "soulblade", "slashwave"]
	var i := 0
	for k in kinds:
		main.spawn_projectile(base + Vector2(-260 + i * 70, -60), Vector2(160, 0), {"kind": k, "hostile": k in ["spore", "acid", "rock", "dart", "ember"], "life": 30.0, "radius": 7.0 if k != "shuriken" else 10.0})
		i += 1
	main.spawn_fx("hit", base + Vector2(-200, 10), Color(1.0, 0.85, 0.6), Vector2.RIGHT)
	main.spawn_fx("death", base + Vector2(-60, 0), Color(0.7, 0.6, 0.8))
	main.spawn_fx("shards", base + Vector2(80, 0), Color(0.75, 0.85, 1.0), Vector2(6, 0))
	main.spawn_fx("dust", base + Vector2(200, 24), Color(0.75, 0.72, 0.68))
	for j in 4:
		main.spawn_fx("after", base + Vector2(260 + j * 14, 24), Color(1, 1, 1), Vector2.RIGHT, 1)
	await _frames(4)
	paused = true
	main.camera.position_smoothing_enabled = false
	main.camera.zoom = Vector2(2.0, 2.0)
	for kk in 3:
		await process_frame
	await _snap(pre + "_effets")
	print("ok ui")
	quit()

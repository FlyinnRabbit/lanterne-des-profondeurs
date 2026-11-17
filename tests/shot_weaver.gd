extends SceneTree
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	var pl = main.player
	pl.sitting = false
	var e := CharacterBody2D.new()
	e.set_script(main.WeaverScript)
	e.main = main
	e.position = pl.global_position + Vector2(170, -40)
	main.add_child(e)
	main.spawn_projectile(pl.global_position + Vector2(-90, 16), Vector2.ZERO, {"kind": "webpatch", "life": 5.0, "radius": 22.0})
	for i in 200:
		await physics_frame
		if e.state == "windup_web": break
	await _f(12)
	get_root().get_texture().get_image().save_png("/tmp/weaver1.png")
	for i in 120:
		await physics_frame
		if pl.web_t > 0.0: break
	await _f(4)
	get_root().get_texture().get_image().save_png("/tmp/weaver2.png")
	quit()

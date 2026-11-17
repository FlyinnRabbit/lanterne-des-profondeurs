extends SceneTree
# Aperçu des nouveaux mobs dans leurs différents états (figés)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _mk(main, path: String, pos: Vector2, props := {}):
	var e := CharacterBody2D.new()
	e.set_script(load(path))
	e.main = main
	e.display = true
	e.position = pos
	main.add_child(e)
	e.set_physics_process(false)
	for k in props:
		e.set(k, props[k])
	e.queue_redraw()
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	main.hud.visible = false
	var pl = main.player
	pl.sitting = false
	var feet: float = pl.get_rect().end.y
	var base := Vector2(pl.global_position.x - 230, feet)
	pl.visible = false
	var x := base.x
	_mk(main, "res://scripts/monkey.gd", Vector2(x, feet - 12), {"dir": 1.0}); x += 60
	_mk(main, "res://scripts/monkey.gd", Vector2(x, feet - 12), {"dir": 1.0, "windup_t": 0.3}); x += 60
	_mk(main, "res://scripts/monkey.gd", Vector2(x, feet - 12), {"dir": -1.0, "loot": 20, "elite": true}); x += 70
	_mk(main, "res://scripts/mimic.gd", Vector2(x, feet - 11), {"state": "sleep"}); x += 60
	_mk(main, "res://scripts/mimic.gd", Vector2(x, feet - 11), {"state": "hop", "dir": -1.0}); x += 60
	_mk(main, "res://scripts/moth.gd", Vector2(x, feet - 60), {}); 
	_mk(main, "res://scripts/moth.gd", Vector2(x + 26, feet - 40), {"anim_t": 1.3, "elite": true}); x += 80
	_mk(main, "res://scripts/mole.gd", Vector2(x, feet - 12), {"state": "windup", "state_t": 0.2}); x += 60
	_mk(main, "res://scripts/mole.gd", Vector2(x, feet - 12), {"state": "exposed"}); x += 60
	main.camera.zoom = Vector2(2.4, 2.4)
	main.camera.position_smoothing_enabled = false
	await _f(6)
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("/tmp/newmobs.png")
	quit()

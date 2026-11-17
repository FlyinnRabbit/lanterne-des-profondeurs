extends SceneTree
# Aperçu des nouvelles armes : tenue au repos et coups (figés à mi-course)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _snap(main, pl, wid: String, lv: int, kind: String, adir: Vector2, frac: float, path: String) -> void:
	var gs = root.get_node("GameState")
	gs.prog["weapon"] = wid
	gs.prog["weapon_lv"] = {wid: lv}
	pl.attack_kind = kind
	pl.attack_dir = adir
	var tot: float = pl.ATTACK_TIME * (1.4 if kind == "finisher" else 1.0)
	pl.attack_t = tot * frac if kind != "" else 0.0
	pl.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
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
	pl.set_physics_process(false)
	pl.facing = 1
	main.camera.zoom = Vector2(3.0, 3.0)
	main.camera.position_smoothing_enabled = false
	await _f(3)
	var shots := [["faux", 1, "", Vector2.RIGHT, 0.0], ["faux", 1, "slash", Vector2.RIGHT, 0.45], ["faux", 1, "finisher", Vector2.RIGHT, 0.45],
		["baton", 1, "", Vector2.RIGHT, 0.0], ["baton", 1, "slash", Vector2.RIGHT, 0.5], ["baton", 2, "finisher", Vector2.RIGHT, 0.25]]
	for i in shots.size():
		var s: Array = shots[i]
		await _snap(main, pl, s[0], s[1], s[2], s[3], s[4], "/tmp/wp%d.png" % i)
	quit()

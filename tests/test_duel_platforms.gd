extends SceneTree
# Arène du duel : les plateformes latérales sont accessibles depuis le sol, la centrale depuis une latérale
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _jump_to(pl, start: Vector2, dir: int, hold: int) -> float:
	pl.global_position = start
	pl.velocity = Vector2.ZERO
	await _f(20)
	var a := "move_right" if dir > 0 else "move_left"
	Input.action_press(a)
	Input.action_press("jump")
	var miny := 99999.0
	for i in 160:
		await _f(1)
		miny = minf(miny, pl.global_position.y)
		if i == hold:
			Input.action_release(a)
	print("  x ", pl.global_position.x, " y min ", miny)
	Input.action_release("jump")
	await _f(10)
	return pl.global_position.y
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(5)
	gs.duel_w = ["aiguille", "aiguille"]
	gs.duel_score = [0, 0]
	gs.snapshot = gs.prog.duplicate(true)
	gs.mode = "duel"
	gs._reload(true)
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	for i in 600:
		await physics_frame
		if main.duel_freeze <= 0.0 and main.duel_players[0].is_physics_processing():
			break
	var pl = main.duel_players[0]
	main.duel_players[1].global_position = Vector2(36 * 32, 14 * 32)
	var T := 32.0
	var fails := []
	# sol -> plateforme latérale gauche (colonnes 4-10, rangée 11)
	var y1: float = await _jump_to(pl, Vector2(13 * T, 14 * T + 15), -1, 80)
	print("latérale : y ", y1, " sol ", pl.is_on_floor())
	if y1 > 11 * T: fails.append("latérale")
	# plateforme latérale -> plateforme centrale (colonnes 14-25, rangée 8)
	var y2: float = await _jump_to(pl, Vector2(9 * T, 11 * T - 17), 1, 110)
	print("centrale : y ", y2, " x ", pl.global_position.x, " sol ", pl.is_on_floor())
	if y2 > 8 * T or not pl.is_on_floor(): fails.append("centrale")
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/duel_arena.png")
	print("échecs : ", fails)
	print("RESULT ", "OK" if fails.is_empty() else "FAIL")
	quit()

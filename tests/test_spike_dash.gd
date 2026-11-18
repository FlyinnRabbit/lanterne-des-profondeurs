extends SceneTree
# Ruée dans des pics : un seul masque perdu, la ruée ne ramène pas dans les pics après la réapparition
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
	await _f(10)
	var main = current_scene
	var pl = main.player
	pl.can_dash = true
	pl.max_hp = 9
	pl.hp = 9
	pl.global_position = Vector2(28 * 32, 16 * 32)
	await _f(40)
	pl.facing = 1
	pl.last_safe = pl.global_position
	# des pics juste devant, sur toute la course de la Ruée
	main.spikes.append(Rect2(pl.global_position.x + 16, pl.global_position.y - 40, 300, 80))
	pl.invuln_t = 0.0
	Input.action_press("dash"); await _f(2); Input.action_release("dash")
	await _f(90)
	print("PV après la ruée dans les pics : ", pl.hp, " / 9, mort : ", pl.dead)
	print("RESULT ", "OK" if pl.hp == 8 and not pl.dead else "FAIL")
	quit()

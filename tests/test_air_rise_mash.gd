extends SceneTree
# Combo aérien joué « vite » : deux appuis rapprochés (le 2e pendant la recharge) en pleine
# montée. Le 2e coup doit partir (appui gardé) et relancer le héros nettement plus haut qu'un
# saut seul.
func _initialize() -> void:
	RenderingServer.render_loop_enabled = false
	_run()
func _f(n: int) -> void:
	for i in n:
		await physics_frame
func _tap(a: String) -> void:
	Input.action_press(a)
	await _f(2)
	Input.action_release(a)
func _jump_peak(pl, mash: bool, gap: int) -> Array:
	pl.global_position = Vector2(40 * 32, 10 * 32)
	pl.velocity = Vector2.ZERO
	await _f(90)
	var y0: float = pl.global_position.y
	var peak := y0
	var kinds := []
	Input.action_press("jump")
	for f in 160:
		if mash and f == 8:
			_tap("attack")
		if mash and f == 8 + gap:
			_tap("attack")
		if pl.attack_kind != "" and (kinds.is_empty() or kinds[-1] != pl.attack_kind) and pl.attack_t > 0.0:
			kinds.append(pl.attack_kind)
		await physics_frame
		peak = minf(peak, pl.global_position.y)
	Input.action_release("jump")
	await _f(60)
	return [y0 - peak, kinds]
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(30)
	var pl = current_scene.player
	var ok := true
	var plain: Array = await _jump_peak(pl, false, 0)
	print("saut seul : %d px" % int(plain[0]))
	for gap in [20, 34, 48]:
		var r: Array = await _jump_peak(pl, true, gap)
		var good: bool = r[1].has("air_rise") and r[0] > plain[0] + 40.0
		print("2 coups à %d images d'écart : %d px  %s  %s" % [gap, int(r[0]), r[1], "ok" if good else "PROBLÈME"])
		ok = ok and good
	# stick poussé en avant et un peu vers le bas : combo aérien, pas coup plongeant
	pl.global_position = Vector2(40 * 32, 10 * 32)
	pl.velocity = Vector2.ZERO
	await _f(90)
	Input.action_press("jump")
	await _f(10)
	Input.action_press("move_right", 0.8)
	Input.action_press("down", 0.6)
	await _f(2)
	await _tap("attack")
	await _f(3)
	var k1: String = pl.attack_kind
	Input.action_release("down")
	Input.action_press("down", 0.95)
	Input.action_press("move_right", 0.2)
	await _f(60)
	await _tap("attack")
	await _f(3)
	var k2: String = pl.attack_kind
	Input.action_release("down")
	Input.action_release("move_right")
	Input.action_release("jump")
	await _f(90)
	print("stick en diagonale avant-bas : %s (attendu air) ; stick franchement bas : %s (attendu slash vers le bas)" % [k1, k2])
	ok = ok and k1 == "air" and k2 != "air"
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

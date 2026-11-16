extends SceneTree
# Pas de coup à travers la roche : le mannequin juste sous la plateforme fine du Sanctuaire
# ne doit pas être touché par un coup vers le bas donné depuis la plateforme, ni de côté à travers un mur.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _hit(pl, dummy, ppos: Vector2, dpos: Vector2, dir: String, air: bool) -> bool:
	dummy.global_position = dpos
	pl.global_position = ppos
	pl.velocity = Vector2.ZERO
	pl.facing = signf(dpos.x - ppos.x) if absf(dpos.x - ppos.x) > 2.0 else 1.0
	await _f(30)
	if air:
		pl.global_position = ppos
		pl.velocity = Vector2.ZERO
	var n0: int = dummy.hits.size()
	var t0: float = float(dummy.hits.back()[0]) if n0 > 0 else -1.0
	if dir != "":
		Input.action_press(dir)
	Input.action_press("attack")
	await _f(2)
	Input.action_release("attack")
	await _f(30)
	if dir != "":
		Input.action_release(dir)
	return dummy.hits.size() > n0
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _f(60)
	var pl = main.player
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == main.DummyScript:
			dummy = e
	dummy.set_physics_process(false)
	# plateforme haute : rangée 9, colonnes 28-38 (dessus à y = 288, dessous à y = 320)
	var on_plat := Vector2(33 * 32, 9 * 32 - 17 - 24)
	var under := Vector2(33 * 32, 10 * 32 + 22)
	var a: bool = await _hit(pl, dummy, on_plat, under, "down", true)
	# même chose sans plateforme entre les deux (à l'air libre, au-dessus du sol)
	var b: bool = await _hit(pl, dummy, Vector2(10 * 32, 16 * 32 - 60), Vector2(10 * 32, 16 * 32 + 6), "down", true)
	# de côté, à l'air libre
	var c: bool = await _hit(pl, dummy, Vector2(10 * 32, 16 * 32), Vector2(10 * 32 + 50, 16 * 32 - 6), "", false)
	print("à travers la plateforme : %s (attendu false) ; air libre vers le bas : %s (attendu true) ; de côté : %s (attendu true)" % [a, b, c])
	print("RÉSULTAT : ", "OK" if (not a and b and c) else "ÉCHEC")
	quit()

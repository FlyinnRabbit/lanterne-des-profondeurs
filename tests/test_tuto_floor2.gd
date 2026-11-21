extends SceneTree
# Tutoriel, étage du bas, joué au clavier : descendre par le treuil, traverser le pont qui
# s'effondre, briser la roche, ramasser l'emblème et les éclats, sortir → Sanctuaire avec le but.
func _initialize() -> void:
	RenderingServer.render_loop_enabled = false
	_run()
func _f(n: int) -> void:
	for i in n:
		await physics_frame
func _hold(act: String, n: int) -> void:
	Input.action_press(act)
	await _f(n)
	Input.action_release(act)
func _tap(act: String) -> void:
	Input.action_press(act)
	await _f(2)
	Input.action_release(act)
	await _f(2)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	gs.mode = "tutorial"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(5)
	var main = current_scene
	var ok := true
	var pl = main.player
	var T: int = main.TILE
	var winches: Array = main.interactables.filter(func(it): return it[1] == "winch")
	print("treuils : ", winches.size(), "  panneaux : ", main.signs.size(), " / ", gs.current_level()["signs"].size())
	ok = ok and winches.size() == 1 and main.signs.size() == gs.current_level()["signs"].size()
	# 1) au bord du puits, {bas} : on prend la corde et on descend
	var wn = winches[0][0]
	pl.global_position = wn.arrive
	await _f(20)
	await _tap("down")
	print("accroché : ", pl.rope != null)
	ok = ok and pl.rope != null
	await _hold("down", 200)
	await _f(30)
	var low: bool = pl.global_position.y > 30 * T
	print("en bas : ", low, "  y=", int(pl.global_position.y / T))
	ok = ok and low
	if pl.rope != null:
		await _tap("jump")
		await _f(30)
	# 2) vers la droite : pont qui s'effondre (on doit le traverser sans tomber)
	var hp0: int = pl.hp
	Input.action_press("move_right")
	var t := 0
	while pl.global_position.x < 134 * T and t < 600:
		await _f(1)
		t += 1
	Input.action_release("move_right")
	await _f(60)
	var crumbles := 0
	for c in main.get_children():
		if c.get("kind") == "crumble":
			crumbles += 1
	print("après le pont : x=", int(pl.global_position.x / T), " pv ", pl.hp, "/", hp0, "  blocs de pont ", crumbles)
	ok = ok and pl.global_position.x >= 133 * T and pl.hp == hp0
	# 3) la roche fissurée : on frappe jusqu'au passage
	Input.action_press("move_right")
	await _f(90)
	Input.action_release("move_right")
	var blocked_x: float = pl.global_position.x
	for k in 30:
		Input.action_press("move_right")
		await _tap("attack")
		Input.action_release("move_right")
		await _f(10)
	Input.action_press("move_right")
	t = 0
	while pl.global_position.x < 158 * T and t < 600:
		await _f(1)
		t += 1
	Input.action_release("move_right")
	print("roche : bloqué à x=", int(blocked_x / T), " puis x=", int(pl.global_position.x / T), "  emblèmes : ", gs.prog["owned"].size(), "  éclats : ", pl.geo)
	ok = ok and blocked_x < 140 * T and pl.global_position.x > 150 * T and gs.prog["owned"].size() >= 1 and pl.geo > 0
	# 4) la porte → Sanctuaire, éclats gardés, but annoncé
	var geo: int = pl.geo
	Input.action_press("move_right")
	t = 0
	while gs.mode == "tutorial" and t < 400:
		await _f(1)
		t += 1
	Input.action_release("move_right")
	await _f(60)
	print("mode : ", gs.mode, "  éclats gardés : ", gs.prog["geo"], " / ", geo, "  but : ", gs.goal_text())
	ok = ok and gs.mode == "hub" and int(gs.prog["geo"]) == geo
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

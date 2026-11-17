extends SceneTree
# Estoc repoussant : la ruée + attaque projette un petit ennemi au loin (toutes armes sauf shuriken),
# puis 2 s de recharge pendant lesquelles l'estoc ne repousse plus.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _thrust(pl) -> void:
	Input.action_press("dash")
	await _f(2)
	Input.action_release("dash")
	Input.action_press("attack")
	await _f(2)
	Input.action_release("attack")
func _setup(gs, w: String):
	gs.prog["weapon"] = w
	gs.prog["can_dash"] = true
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	gs.difficulty = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	# un ennemi au sol, rendu très résistant pour qu'il survive aux coups
	var e = null
	for c in get_nodes_in_group("enemies"):
		if c.get_script().resource_path.get_file() in ["crawler.gd", "hopper.gd", "guard.gd", "lancer.gd"]:
			e = c
			break
	return [main, pl, e]
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	for w in ["aiguille", "griffes", "marteau", "fouet", "shuriken"]:
		var r = await _setup(gs, w)
		var main = r[0]
		var pl = r[1]
		var e = r[2]
		if e == null:
			print(w, " : pas d'ennemi au sol trouvé")
			ok = false
			continue
		e.hp = 999
		var pushes := []
		for k in 2:
			e.global_position = pl.global_position + Vector2(90, -4)
			e.knock = Vector2.ZERO
			e.stun_t = 0.0
			pl.facing = 1
			pl.invuln_t = 5.0
			var x0: float = e.global_position.x
			await _thrust(pl)
			await _f(40)
			pushes.append(e.global_position.x - x0)
			pl.dash_cd = 0.0
		var want_push: bool = w != "shuriken"
		var good: bool = (pushes[0] > 120.0 and pushes[0] > pushes[1] + 40.0) == want_push and pushes[1] < 100.0
		print("%-9s : recul 1er estoc %.0f px, 2e estoc (recharge) %.0f px -> %s" % [w, pushes[0], pushes[1], "ok" if good else "PROBLÈME"])
		ok = ok and good
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

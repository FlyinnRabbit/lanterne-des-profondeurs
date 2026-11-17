extends SceneTree
# Registres du Scriptorium : les compteurs avancent en jouant, survivent à la mort (contrairement
# au butin) et à la sauvegarde ; le livre s'ouvre au Sanctuaire et se referme.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.new_game(true, 1, 3, false)
	await process_frame
	await process_frame
	gs.prog["can_dash"] = true
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	gs.snapshot = gs.prog.duplicate(true)
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	var pl = main.player
	# un saut, une ruée
	Input.action_press("jump"); await _f(3); Input.action_release("jump"); await _f(40)
	Input.action_press("dash"); await _f(3); Input.action_release("dash"); await _f(30)
	# un ennemi vaincu
	var e = null
	for c in get_nodes_in_group("enemies"):
		if not c.is_boss and c.get_script() != main.DummyScript:
			e = c
			break
	var kind: String = String(e.get_script().resource_path.get_file()).get_basename()
	e.take_hit(999, Vector2.RIGHT)
	await _f(5)
	var c1: Dictionary = gs.journal.get("c", {}).duplicate()
	print("après jeu : ", c1, " | ", kind, " : ", gs.journal.get("mobs", {}).get(kind, {}))
	var ok: bool = int(c1.get("jumps", 0)) >= 1 and int(c1.get("dashes", 0)) >= 1 and int(c1.get("kills", 0)) == 1 \
		and int(gs.journal["mobs"][kind]["k"]) == 1 and int(c1.get("damage", 0)) > 0 and float(c1.get("time", 0.0)) > 0.0
	# la mort : le butin est perdu, pas les registres
	pl.take_damage(99, pl.global_position.x - 10)
	for i in 600:
		await process_frame
		if gs.mode == "hub" and current_scene and current_scene.get("scriptorium") != null and current_scene.player:
			break
	await process_frame
	var c2: Dictionary = gs.journal.get("c", {})
	print("après la chute : kills ", c2.get("kills"), " chutes ", c2.get("deaths"), " mode ", gs.mode)
	ok = ok and int(c2.get("kills", 0)) == 1 and int(c2.get("deaths", 0)) == 1
	# sauvegarde puis rechargement
	gs.save_game()
	gs.journal = {}
	gs.load_game()
	print("rechargé : kills ", gs.journal.get("c", {}).get("kills"))
	ok = ok and int(gs.journal.get("c", {}).get("kills", 0)) == 1
	# le Scriptorium au Sanctuaire
	await process_frame
	var m2 = current_scene
	var sc = m2.scriptorium
	sc.open()
	await process_frame
	var opened: bool = sc.visible and paused
	for p in 5:
		sc._set_page(p)
		await process_frame
	sc.close()
	await process_frame
	print("livre ouvert : ", opened, " refermé : ", not sc.visible and not paused)
	ok = ok and opened and not sc.visible and not paused
	gs.delete_slot(3)
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

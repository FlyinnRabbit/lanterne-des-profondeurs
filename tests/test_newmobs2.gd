extends SceneTree
# Slime (division), scorpion (piqûre + venin, pinces qui parent les coups bas), gobelin (dagues, fuite)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _mk(main, path: String, pos: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(load(path))
	e.main = main
	e.position = pos
	main.add_child(e)
	return e
func _count_script(path: String) -> int:
	var n := 0
	for e in get_nodes_in_group("enemies"):
		if e.get_script().resource_path == path and not e.dead: n += 1
	return n
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
	pl.sitting = false
	var ok := true
	# slime : se divise en deux
	var sl = _mk(main, "res://scripts/slime.gd", pl.global_position + Vector2(160, -10))
	await _f(10)
	sl.take_hit(99, Vector2.RIGHT)
	await _f(5)
	var n: int = _count_script("res://scripts/slime.gd")
	print("slimes after kill: ", n)
	if n != 2: ok = false
	for e in get_nodes_in_group("enemies"):
		e.take_hit(99, Vector2.RIGHT)
	await _f(5)
	print("small slimes don't split: ", _count_script("res://scripts/slime.gd"))
	if _count_script("res://scripts/slime.gd") != 0: ok = false
	# scorpion : piqûre puis venin
	pl.hp = 5
	pl.invuln_t = 0.0
	var sc = _mk(main, "res://scripts/scorpion.gd", pl.global_position + Vector2(55, 0))
	var stung := false
	for i in 200:
		await physics_frame
		pl.velocity.x = 0.0
		if pl.hp < 5:
			stung = true
			break
	sc.queue_free()
	var sc2 = _mk(main, "res://scripts/scorpion.gd", pl.global_position + Vector2(400, 0))
	sc2._poison(pl)    # piqûre : venin appliqué
	print("poisoned meta=", pl.has_meta("poisoned"), " hp=", pl.hp, " sitting=", pl.sitting)
	var hp_after: int = pl.hp
	for i in 30:
		await _f(10)
		if pl.hp != hp_after or not pl.has_meta("poisoned"):
			print("  changed at ", i * 10, " frames, hp=", pl.hp, " meta=", pl.has_meta("poisoned"))
			break
	print("scorpion stung=", stung, " hp ", hp_after, " -> after venom ", pl.hp)
	if not stung or pl.hp != hp_after - 1: ok = false
	sc2.queue_free()
	await _f(5)
	# gobelin : lance une dague de loin
	pl.hp = 5
	pl.invuln_t = 2.0
	var gb = _mk(main, "res://scripts/goblin.gd", pl.global_position + Vector2(300, 0))
	var dart := false
	for i in 180:
		await physics_frame
		for pr in get_nodes_in_group("projectiles"):
			if pr.kind == "dart" and pr.hostile: dart = true
		if dart: break
	print("goblin threw dagger=", dart)
	if not dart: ok = false
	gb.take_hit(gb.hp - 1, Vector2.RIGHT)
	await _f(3)
	print("goblin flees at low hp: ", gb.state)
	if gb.state != "flee": ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

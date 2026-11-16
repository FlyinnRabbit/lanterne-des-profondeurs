extends SceneTree
# Après une attaque (ou en se relevant), il faut attendre avant de se rasseoir sur le banc.
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _try_sit(pl) -> bool:
	Input.action_press("up")
	await _frames(3)
	Input.action_release("up")
	await _frames(3)
	return pl.sitting
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(20)
	for e in get_nodes_in_group("enemies"):
		e.queue_free()   # pas d'ennemi qui frappe pendant le test
	var pl = main.player
	var bp: Vector2 = main.benches[0]
	pl.global_position = bp + Vector2(-10, 0)
	pl.velocity = Vector2.ZERO
	pl.bench_lock_t = 0.0
	await _frames(30)
	# 1) attaque puis banc tout de suite : refusé
	Input.action_press("attack")
	await _frames(2)
	Input.action_release("attack")
	await _frames(10)
	var a: bool = await _try_sit(pl)
	# 2) 1,7 s plus tard : accepté
	await create_timer(1.7, true, true).timeout
	var b: bool = await _try_sit(pl)
	# 3) se relever puis se rasseoir aussitôt : refusé
	await create_timer(0.5, true, true).timeout
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	await _frames(40)
	pl.global_position = bp + Vector2(-10, 0)
	pl.velocity = Vector2.ZERO
	await _frames(5)
	var c: bool = await _try_sit(pl)
	# 4) même banc, plus tard : on s'assoit mais il ne soigne plus
	await create_timer(1.7, true, true).timeout
	pl.hp = 1
	var d: bool = await _try_sit(pl)
	var hp_after: int = pl.hp
	print("4e essai : assis %s, vie %d (attendu assis, vie 1)" % [d, hp_after])
	print("assis juste après attaque : %s (attendu false) ; après 1,7 s : %s (attendu true) ; juste après s'être relevé : %s (attendu false)" % [a, b, c])
	print("RÉSULTAT : ", "OK" if (not a and b and not c and d and hp_after == 1) else "ÉCHEC")
	quit()

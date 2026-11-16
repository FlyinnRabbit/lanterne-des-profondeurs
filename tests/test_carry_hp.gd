extends SceneTree
# Vie conservée au portail entre les zones d'un palier : +1 masque en Facile/Normal, rien en Difficile/Cauchemar.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	for diff in 4:
		gs.difficulty = diff
		gs.mode = "descent"
		gs.palier = 1
		gs.step = 1
		change_scene_to_file("res://main.tscn")
		await process_frame
		await process_frame
		paused = false
		await _f(10)
		var pl = current_scene.player
		pl.hp = 2
		gs.go_next_level(pl)
		await process_frame
		await process_frame
		await process_frame
		await _f(10)
		var pl2 = current_scene.player
		var want := 3 if diff <= 1 else 2
		print("difficulté %d : zone %d, vie %d/%d (attendu %d)" % [diff, gs.step, pl2.hp, pl2.max_hp, want])
		if pl2.hp != want or gs.step != 2:
			ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

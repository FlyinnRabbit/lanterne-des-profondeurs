extends SceneTree
# Ambiance du biome lancée à l'arrivée dans un niveau, pas qui sonnent en courant, retour des coups.
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 20: await physics_frame
	var A = root.get_node("Audio")
	var ok := true
	print("Sanctuaire : ambiance ", A.amb_id, " ; joue ", A.amb.playing, " ; boucle ", A.amb.stream.loop if A.amb.stream else null)
	ok = ok and A.amb_id == "hub" and A.amb.playing
	var steps := 0
	var count := func(): pass
	var main = current_scene
	Input.action_press("move_right")
	var played := 0
	for i in 120:
		await physics_frame
		for s in A.sfx_pool:
			if s.playing and s.stream and String(s.stream.resource_path).contains("step_"):
				played += 1
				break
	Input.action_release("move_right")
	print("pas entendus en courant : ", played > 0)
	ok = ok and played > 0
	main.biome_debris(main.player.global_position, 8, 150.0)
	print("éclats du biome : ok")
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "descent"
	gs.one_life = true      # l'écran de fin de partie ne sert plus qu'au mode « une seule vie »
	gs.palier = 1
	gs.step = 2
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.player.take_damage(99, main.player.global_position.x - 10)
	for i in 600:
		await process_frame
		if main.menu.game_over:
			break
	print("game over: ", main.menu.game_over, " panneau difficulté visible: ", main.menu.diff_panel.get_parent().visible, " pause: ", paused)
	print("résumé: ", main.menu.diff_header.text)
	main.menu._start_game(2)
	await process_frame
	await process_frame
	await process_frame
	print("nouvelle partie -> mode ", gs.mode, " difficulté ", gs.diff_name(), " pause: ", paused, " scène: ", current_scene.level["name"])
	print("RÉSULTAT : ", "OK" if gs.mode != "descent" else "ÉCHEC")
	quit()

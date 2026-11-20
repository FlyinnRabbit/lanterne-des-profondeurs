extends SceneTree
# Classement du jour : fin d'une Descente du jour → temps envoyé, rang affiché ; puis écran du classement.
# Nécessite le serveur local : node server/dev_server.mjs, et LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var settings = root.get_node("Settings")
	settings.player_name = "Thomas"
	settings.board_online = true
	gs.show_title = false
	gs.difficulty = 1
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	# classement du jour peuplé d'avance (serveur vierge) : 2 temps meilleurs que 240 s, 9 moins bons
	var url := OS.get_environment("LANTERNE_LEADERBOARD_URL")
	for i in 11:
		var hr := HTTPRequest.new()
		root.add_child(hr)
		var body := JSON.stringify({"seed": gs.today_seed(), "diff": 1, "player_id": "%016x" % (0xb07000 + i),
			"name": "Veilleur %d" % (i + 1), "time": 100.0 + i * 100.0 + (0.0 if i < 2 else 100.0), "version": "test"})
		hr.request(url + "/score", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
		await hr.request_completed
		hr.queue_free()
	# fin de Descente du jour simulée
	gs.saved_seed = gs.run_seed
	gs.run_seed = gs.today_seed()
	gs.daily = true
	gs.mode = "descent"
	gs.palier = 3
	gs.step = gs.STEPS_PER_PALIER
	var ach = root.get_node("Achievements")
	ach.run["time"] = 240.0
	gs.go_next_level(main.player)
	await create_timer(2.5, true, false, true).timeout
	var msg: String = current_scene.hud.message
	print("message : ", msg.replace("\n", " | "))
	print("dernière réponse : rang ", gs.board.last.get("me", {}).get("rank", -1), " sur ", gs.board.last.get("total", -1))
	# écran du classement
	current_scene.hub_ui.open_elevator()
	current_scene.hub_ui._show_board()
	await create_timer(1.5, true, false, true).timeout
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/board.png")
	var lines: int = current_scene.hub_ui._board_rows.get_child_count()
	print("lignes affichées : ", lines)
	var ok: bool = int(gs.board.last.get("me", {}).get("rank", -1)) == 3 and lines >= 10 and msg.find("3") >= 0
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

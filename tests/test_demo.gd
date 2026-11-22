extends SceneTree
# Édition démo (forcée par LANTERNE_EDITION=demo) : l'ascenseur s'arrête au palier 2 avec un
# accès « version complète », sans modes spéciaux ; terminer le palier 2 ouvre l'écran de fin de
# démo au Sanctuaire. Le jeu complet (sans la variable) garde tout.
func _initialize() -> void:
	RenderingServer.render_loop_enabled = OS.get_cmdline_user_args().has("--shots")
	_run()
func _f(n: int) -> void:
	for i in n:
		await process_frame
func _labels(hub) -> Array:
	var out := []
	for b in hub.lift_list.get_children():
		if b is Button:
			out.append(b.text)
	return out
func _hub(gs) -> Node:
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	return current_scene
func _run() -> void:
	await process_frame
	TranslationServer.set_locale("fr")
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	# --- jeu complet
	gs.record = 4; gs.unlocked = 5
	var main = await _hub(gs)
	main.hub_ui.open_elevator()
	var full: Array = _labels(main.hub_ui)
	var full_ok: bool = full.any(func(t): return t.begins_with("Palier 5")) and full.any(func(t): return t.begins_with("Descente du jour"))
	print("complet : %d boutons, palier 5 et modes spéciaux : %s" % [full.size(), full_ok])
	ok = ok and full_ok
	main.hub_ui.close_all()
	# --- démo
	OS.set_environment("LANTERNE_EDITION", "demo")
	main = await _hub(gs)
	main.hub_ui.open_elevator()
	var demo: Array = _labels(main.hub_ui)
	print("démo : ", demo)
	var demo_ok: bool = demo.size() == 3 and demo[0].begins_with("Palier 3 et au-delà") and demo[1].begins_with("Palier 2") \
		and demo[2].begins_with("Palier 1")
	ok = ok and demo_ok
	main.hub_ui.close_all()
	# --- terminer le palier 2 en démo
	gs.record = 1; gs.unlocked = 2
	gs.mode = "descent"; gs.palier = 2; gs.step = gs.STEPS_PER_PALIER
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	main = current_scene
	gs.go_next_level(main.player)
	for i in 600:
		await process_frame
		if current_scene != main and current_scene != null and current_scene.get("hub_ui") != null and gs.mode == "hub":
			break
	paused = false
	await _f(10)
	main = current_scene
	paused = false
	for i in 3000:
		await process_frame
		if main.hub_ui.visible:
			break
	var end_ok: bool = main.hub_ui.visible and main.hub_ui.npc_panel.get_parent().visible and String(main.hub_ui.npc_name.text) == "Fin de la démo"
	print("fin de démo affichée : ", end_ok, "  record ", gs.record)
	ok = ok and end_ok and gs.record == 2
	if OS.get_cmdline_user_args().has("--shots"):
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/demo_end.png")
		main.hub_ui.close_all()
		main.hub_ui.open_elevator()
		await _f(10)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/demo_lift.png")
		main.hub_ui.close_all()
		main.menu.open_title()
		await _f(30)
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/demo_title.png")
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

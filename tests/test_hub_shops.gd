extends SceneTree
# Chaque habitant du Sanctuaire propose bien ses boutons (forgeronne, joaillier, arène)
func _initialize() -> void:
	_run()
func _btns(main) -> Array:
	var out := []
	for b in main.hub_ui.npc_buttons.get_children():
		if b is Button: out.append(b.text)
	return out
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 3
	gs.prog["owned"] = [1, 4, 2, 6]
	gs.prog["equipped"] = [4]
	gs.prog["weapons_owned"] = ["griffes"]
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10: await physics_frame
	var main = current_scene
	var ok := true
	main.hub_ui.open_npc("smith")
	var sm := _btns(main)
	main.hub_ui.open_npc("jeweler")
	var jw := _btns(main)
	main.hub_ui.open_npc("arena")
	var ar := _btns(main)
	print("smith ", sm.size(), " ", sm)
	print("jeweler ", jw.size(), " arena ", ar.size(), " ", ar)
	if sm.size() != 3 or jw.size() != 5 or not str(jw[0]).contains("(") or ar.size() != 4: ok = false
	# beaucoup d'emblèmes : la liste défile, la fenêtre reste dans l'écran
	gs.prog["owned"] = range(gs.charm_count())
	main.hub_ui.open_npc("jeweler")
	await process_frame
	await process_frame
	var pr: Rect2 = main.hub_ui.npc_panel.get_global_rect()
	print("jeweler all ", _btns(main).size(), " panel ", pr)
	if _btns(main).size() != gs.charm_count() + 1 or pr.end.y > 720.0 or pr.position.y < 0.0: ok = false
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/jeweler_all.png")
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

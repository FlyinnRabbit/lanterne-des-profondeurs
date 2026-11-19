extends SceneTree
# Captures : onglets LB / RB (tailleuse, inventaire) et page « Équipement » de l'inventaire.
func _initialize() -> void:
	_run()
func _snap(n: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/gfx/tabs_%s.png" % n)
func _press(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/gfx")
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	var owned := []
	for i in 30:
		owned.append(i)
	gs.prog["owned"] = owned
	gs.prog["notches"] = 11
	gs.prog["equipped"] = [0, 7, 24, 34, 5]
	gs.prog["charm_lv"] = {"0": 2, "7": 1, "24": 2, "34": 1, "5": 1}
	gs.prog["weapons_owned"] = ["aiguille", "baton"]
	gs.prog["weapon"] = "baton"
	gs.prog["weapon_lv"] = {"baton": 4}
	gs.prog["bonus_hp"] = 3
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 30:
		await physics_frame
	var main = current_scene
	main.player.can_dash = true
	main.player.apply_equipment()
	main.player.hp = main.player.max_hp
	root.get_node("Controls").using_pad = true
	var ok := true
	# tailleuse : RB passe de « Cape » à « Écharpe »
	main.hub_ui.open_wardrobe()
	await _snap("garde_robe")
	var c0: String = main.hub_ui.ward_cat
	await _press(JOY_BUTTON_RIGHT_SHOULDER)
	var c1: String = main.hub_ui.ward_cat
	await _press(JOY_BUTTON_LEFT_SHOULDER)
	await _press(JOY_BUTTON_LEFT_SHOULDER)
	var c2: String = main.hub_ui.ward_cat
	print("tailleuse : ", c0, " -> RB ", c1, " -> LB LB ", c2)
	if c1 == c0 or c2 == c0: ok = false
	await _snap("garde_robe_lb")
	main.hub_ui.close_all()
	await process_frame
	# inventaire : page emblèmes puis RB -> équipement
	main.inventory.open()
	await _snap("inv_emblemes")
	await _press(JOY_BUTTON_RIGHT_SHOULDER)
	print("inventaire page : ", main.inventory.page)
	if main.inventory.page != 1: ok = false
	await _snap("inv_equipement")
	await _press(JOY_BUTTON_RIGHT_SHOULDER)
	if main.inventory.page != 0: ok = false
	main.inventory.close()
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

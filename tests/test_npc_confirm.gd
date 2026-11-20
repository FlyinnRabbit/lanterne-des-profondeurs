extends SceneTree
# Forgeronne, joaillier, cartographe et arsenal : un achat demande confirmation (rien n'est dépensé
# avant « Valider » / « Acheter »), « Annuler » ne dépense rien.
func _initialize() -> void:
	_run()
func _btn(box: Node, has: String) -> Button:
	for c in box.get_children():
		if c is Button and has in c.text and not c.disabled:
			return c
		if c is HBoxContainer:
			for d in c.get_children():
				if d is Button and has in d.text and not d.disabled:
					return d
	return null
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.record = 6
	gs.prog["map_full"] = false
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10:
		await physics_frame
	var main = current_scene
	var hub = main.hub_ui
	var ok := true
	main.player.geo = 9000
	# cartographe
	hub.open_npc("cartographer")
	_btn(hub.npc_buttons, "Plume").pressed.emit()
	print("cartographe : ", hub.npc_text.text, " ; confirmation : ", hub.npc_confirm.visible, " ; éclats ", main.player.geo)
	ok = ok and hub.npc_confirm.visible and main.player.geo == 9000
	hub._npc_cancel()
	ok = ok and main.player.geo == 9000 and not gs.prog.get("map_full", false)
	_btn(hub.npc_buttons, "Plume").pressed.emit()
	hub._npc_ok()
	print("  validé : plume ", gs.prog.get("map_full", false), " ; éclats ", main.player.geo)
	ok = ok and gs.prog.get("map_full", false) and main.player.geo == 9000 - hub.CARTO_PRICE
	# forgeronne
	var g0: int = main.player.geo
	hub.open_npc("smith")
	var sb := _btn(hub.npc_buttons, "éclats")
	if sb:
		sb.pressed.emit()
		print("forgeronne : ", hub.npc_text.text, " ; éclats ", main.player.geo)
		ok = ok and hub.npc_confirm.visible and main.player.geo == g0
		hub._npc_ok()
		print("  validé : éclats ", main.player.geo)
		ok = ok and main.player.geo < g0
	# joaillier
	g0 = main.player.geo
	hub.open_npc("jeweler")
	var jb := _btn(hub.npc_buttons, "éclats")
	if jb:
		jb.pressed.emit()
		print("joaillier : ", hub.npc_text.text)
		ok = ok and hub.npc_confirm.visible and main.player.geo == g0
		hub._npc_cancel()
		ok = ok and main.player.geo == g0
	hub.close_all()
	# arsenal
	hub.open_arsenal()
	await process_frame
	var ab := _btn(hub.ars_list, "éclats")
	if ab:
		g0 = main.player.geo
		ab.pressed.emit()
		print("arsenal : ", hub.ars_status.text, " ; éclats ", main.player.geo)
		ok = ok and hub.ars_confirm.visible and main.player.geo == g0
		hub._ars_ok()
		print("  acheté : ", hub.ars_status.text, " ; éclats ", main.player.geo)
		ok = ok and main.player.geo < g0 and not hub.ars_confirm.visible
	else:
		print("arsenal : toutes les armes déjà achetées")
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

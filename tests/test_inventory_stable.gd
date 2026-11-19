extends SceneTree
# Inventaire : le panneau garde la même taille quel que soit l'emblème décrit (sinon, souris
# immobile + panneau qui se redimensionne = la description clignote entre deux emblèmes),
# et un survol sans mouvement de souris ne change pas l'emblème décrit.
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	for id in gs.charm_count():
		if not gs.prog["owned"].has(id):
			gs.prog["owned"].append(id)
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	for i in 30:
		await physics_frame
	var inv = main.inventory
	inv.open()
	await process_frame
	await process_frame
	var ok := true
	var sizes := {}
	for lang in ["fr", "en", "de"]:
		TranslationServer.set_locale(lang)
		inv.close()
		inv.open()
		await process_frame
		for id in gs.charm_count():
			inv._show_desc(id)
			await process_frame
			await process_frame
			sizes[str(inv.panel.size)] = true
		print(lang, " : tailles du panneau ", sizes.keys())
		if sizes.size() != 1:
			ok = false
		sizes.clear()
	TranslationServer.set_locale("fr")
	inv._show_desc(3)
	inv.mouse_moved_t = -100
	inv._on_slot_hover(5)
	print("survol sans mouvement : décrit ", inv.focused_id, " (attendu 3)")
	if inv.focused_id != 3: ok = false
	inv.mouse_moved_t = Engine.get_process_frames()
	inv._on_slot_hover(5)
	print("survol avec mouvement : décrit ", inv.focused_id, " (attendu 5)")
	if inv.focused_id != 5: ok = false
	# le panneau tient dans la fenêtre (mise à l'échelle revérifiée chaque image)
	await process_frame
	await process_frame
	var vr: Vector2 = inv.get_viewport().get_visible_rect().size
	var bot: float = inv.panel.global_position.y + inv.panel.size.y * inv.panel.scale.y
	print("bas du panneau %.0f / hauteur %.0f" % [bot, vr.y])
	if bot > vr.y + 1.0: ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

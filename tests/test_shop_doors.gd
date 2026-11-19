extends SceneTree
# Écran d'entrée des boutiques : la boutique ne s'ouvre qu'une fois les battants fermés
# (avant, elle transparaissait sous les battants pendant leur fondu). À lancer avec un affichage
# (xvfb-run) : l'écran d'entrée est coupé en mode headless.
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
	var main = current_scene
	for i in 30:
		await physics_frame
	var ok := true
	var merchant = null
	for it in main.interactables:
		if it[1] == "merchant":
			merchant = it
	var opened_at := [-1.0]
	var hub = main.hub_ui
	var shop_vis_before := false
	var frames := 0
	main.LoadingScript.shop(self, "shop", "Marchand", func():
		var l = null
		for c in root.get_children():
			if c.get("kind") == "shop":
				l = c
		opened_at[0] = l.t if l else -2.0
		main._do_interact(merchant))
	print("figé pendant les battants : ", paused)
	if not paused: ok = false
	while opened_at[0] < 0.0 and frames < 120:
		if hub.visible and hub.shop_panel.get_parent().visible:
			shop_vis_before = true
		await process_frame
		frames += 1
	print("boutique ouverte à t = %.2f s (battants fermés à 0,12 s), visible avant : %s" % [opened_at[0], shop_vis_before])
	if opened_at[0] < 0.12 or shop_vis_before: ok = false
	print("boutique visible après : ", hub.visible and hub.shop_panel.get_parent().visible)
	if not (hub.visible and hub.shop_panel.get_parent().visible): ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

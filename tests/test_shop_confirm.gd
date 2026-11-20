extends SceneTree
# Marchand : un premier appui demande confirmation (rien n'est dépensé) ; « Acheter » achète,
# « Annuler » revient à la liste sans rien dépenser.
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
	for i in 10:
		await physics_frame
	var main = current_scene
	var hub = main.hub_ui
	main.player.geo = 5000
	hub.open_shop()
	await process_frame
	var ok := true
	var notches0 := int(gs.prog["notches"])
	var b: Button = null
	for c in hub.shop_list.get_children():
		if c is Button and "Encoche" in c.text:
			b = c
	b.pressed.emit()
	print("demande : ", hub.shop_status.text, " ; confirmation visible : ", hub.shop_confirm.visible, " ; éclats : ", main.player.geo)
	ok = ok and hub.shop_confirm.visible and main.player.geo == 5000 and int(gs.prog["notches"]) == notches0
	hub._shop_cancel()
	print("annulé : éclats ", main.player.geo, " ; confirmation visible : ", hub.shop_confirm.visible)
	ok = ok and not hub.shop_confirm.visible and main.player.geo == 5000
	for c in hub.shop_list.get_children():
		if c is Button and "Encoche" in c.text:
			b = c
	b.pressed.emit()
	hub._shop_ok()
	await process_frame
	print("acheté : encoches ", notches0, " → ", gs.prog["notches"], " ; éclats ", main.player.geo, " ; ", hub.shop_status.text)
	ok = ok and int(gs.prog["notches"]) == notches0 + 1 and main.player.geo < 5000 and not hub.shop_confirm.visible
	main.player.geo = 0
	for c in hub.shop_list.get_children():
		if c is Button and "Encoche" in c.text:
			b = c
	b.pressed.emit()
	print("sans éclats : ", hub.shop_status.text, " ; confirmation : ", hub.shop_confirm.visible)
	ok = ok and not hub.shop_confirm.visible
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
# Tailleuse : acheter un cosmétique demande une confirmation (« Acheter » / « Annuler »).
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
	for i in 20:
		await physics_frame
	var main = current_scene
	var hub = main.hub_ui
	var cos = gs.cos
	main.player.geo = 5000
	hub.open_wardrobe()
	await process_frame
	var target := ""
	for cat in cos.CATS:
		for id in cos.items_of(cat):
			var it: Dictionary = cos.item(id)
			if not cos.has(id) and it.has("price") and not it.has("season") and not it.get("gift", false):
				target = id
				break
		if target != "":
			break
	var ok := target != ""
	print("cosmétique à vendre : ", target)
	var g0: int = main.player.geo
	hub._ward_pick(target)
	print("1er appui : éclats %d -> %d, possédé %s, confirmation %s" % [g0, main.player.geo, cos.has(target), hub.ward_confirm.visible])
	if main.player.geo != g0 or cos.has(target) or not hub.ward_confirm.visible: ok = false
	hub._ward_cancel()
	print("annulé : éclats %d, possédé %s, confirmation %s" % [main.player.geo, cos.has(target), hub.ward_confirm.visible])
	if main.player.geo != g0 or cos.has(target) or hub.ward_confirm.visible: ok = false
	hub._ward_pick(target)
	hub._ward_buy()
	print("confirmé : éclats %d, possédé %s, confirmation %s" % [main.player.geo, cos.has(target), hub.ward_confirm.visible])
	if main.player.geo >= g0 or not cos.has(target) or hub.ward_confirm.visible: ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

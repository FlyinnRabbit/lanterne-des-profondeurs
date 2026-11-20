extends SceneTree
# Inventaire à la manette : la grille d'emblèmes défile par rangées entières (aucune case coupée).
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
	main.player.sitting = true
	main.inventory.open()
	for i in 5:
		await process_frame
	var inv = main.inventory
	var ok := true
	var seen := []
	for id in [0, 7, 14, 21, 28, 35, 41, 30, 20, 10, 3]:
		inv.slots[id].grab_focus()
		for i in 3:
			await process_frame
		var v: int = inv.grid_scroll.scroll_vertical
		seen.append([id, v])
		var row: int = id / 7
		var top: int = v / inv.ROW_PITCH
		if v % inv.ROW_PITCH != 0 or row < top or row >= top + inv.ROWS_SHOWN:
			ok = false
	print("focus → défilement : ", seen)
	# molette / barre : position arbitraire ramenée à une rangée
	inv.grid_scroll.scroll_vertical = 130
	for i in 4:
		await process_frame
	print("défilement libre 130 → ", inv.grid_scroll.scroll_vertical)
	ok = ok and inv.grid_scroll.scroll_vertical % inv.ROW_PITCH == 0
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

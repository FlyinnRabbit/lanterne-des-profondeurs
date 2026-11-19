extends SceneTree
# Pause au Sanctuaire : un bouton « Écran-titre » ramène à l'écran-titre (absent en descente).
func _initialize() -> void:
	_run()
func _btns(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_btns(c, out)
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
	var all := []
	_btns(main.menu, all)
	var target = null
	for b in all:
		if b.text == "Écran-titre":
			target = b      # le dernier ajouté est celui de la pause (le premier est celui de la mort)
	var ok := target != null
	print("bouton trouvé : ", ok, " (", all.filter(func(b): return b.text == "Écran-titre").size(), " boutons Écran-titre)")
	if ok:
		target.pressed.emit()
		for i in 6:
			await process_frame
		var m2 = current_scene.menu
		print("écran-titre ouvert : ", m2.title_mode, " ; mode : ", gs.mode)
		ok = m2.title_mode
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

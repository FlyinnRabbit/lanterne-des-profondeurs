extends SceneTree
# Défi des boss : +600 éclats à chaque victoire, +200 si record battu, +1 encoche à la première seulement.
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
	var res := []
	var ach = root.get_node("Achievements")
	ach.counters["rush_best"] = 0.0
	for k in 3:
		var n0: int = int(gs.prog["notches"])
		var g0: int = int(gs.prog["geo"])
		gs.start_rush(null)
		gs.rush_i = gs.RUSH_ORDER.size() - 1
		ach.run["time"] = [300.0, 400.0, 250.0][k]     # 1er temps, plus lent, puis record
		gs.go_next_level(null)
		res.append([int(gs.prog["notches"]) - n0, int(gs.prog["geo"]) - g0, gs.mode])
		await process_frame
		await process_frame
	print(res)
	var ok: bool = res[0][0] == 1 and res[1][0] == 0 and res[2][0] == 0 and res[0][1] == 600 and res[1][1] == 600 and res[2][1] == 800 and res[2][2] == "hub"
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

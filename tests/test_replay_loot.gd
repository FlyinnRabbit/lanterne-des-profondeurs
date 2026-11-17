extends SceneTree
# Refaire un palier : les emblèmes au hasard (« * »), l'autel d'élites et le défi chronométré
# déjà obtenus ne se rejouent pas ; les cachettes et encoches restent prises.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _load(gs):
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(5)
	return current_scene
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	var found := false
	for sd in 80:
		gs.run_seed = 3000 + sd
		gs._cache.clear()
		gs.mode = "descent"
		gs.palier = 1
		gs.step = 1
		var m: String = str(gs.current_level()["map"])
		var cs := {}
		for ch in m: cs[ch] = true
		if sd == 0: print("chars ", "".join(cs.keys()))
		if sd == 0: print("map type ", typeof(gs.current_level()["map"]), " len ", m.length(), " has* ", m.contains("*"))
		if not (m.contains("*") or m.contains("R") or m.contains("S")):
			continue
		var main = await _load(gs)
		var keyed := []
		for pk in main.pickups:
			if pk[1] == "charm" and pk.size() > 3:
				keyed.append(pk[3])
		print("seed ", gs.run_seed, " random charms=", keyed.size(), " altar=", main.altar_key != "", " challenge=", main.challenge_key != "")
		if keyed.is_empty() or (main.altar_key == "" and main.challenge_key == ""):
			continue
		found = true
		# on simule : tout obtenu lors d'un premier passage
		for k in keyed: gs.prog["collected"].append(k)
		if main.altar_key != "": gs.prog["collected"].append(main.altar_key)
		if main.challenge_key != "": gs.prog["collected"].append(main.challenge_key)
		var had_altar: bool = main.altar_key != ""
		var had_ch: bool = main.challenge_key != ""
		main = await _load(gs)
		var again := 0
		for pk in main.pickups:
			if pk[1] == "charm" and pk.size() > 3: again += 1
		var altar_on := false
		for it in main.interactables:
			if it[1] == "altar": altar_on = true
		print("replay: random charms=", again, " altar usable=", altar_on, " challenge done=", main.challenge_done)
		if again > 0 or altar_on or (had_ch and not main.challenge_done): ok = false
		if had_altar and main.altar_state != "done": ok = false
		break
	if not found:
		print("no level with special loot found"); ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

extends SceneTree
# Tirage du boss final : priorité aux boss jamais vaincus, stable une fois tiré ; vie plafonnée
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var ach = root.get_node("Achievements")
	var fails := []
	gs.mode = "descent"
	gs.daily = false
	var keep := {}
	for f in gs.FINALS:
		keep[f] = ach.counters.get("final_" + f, false)
	for trial in 30:
		gs.prog = gs._fresh()
		gs.run_seed = 1000 + trial
		for f in gs.FINALS:
			ach.counters["final_" + f] = false
		var seen := {}
		for k in 4:
			var p := (k + 1) * 7
			var b: String = gs.final_boss_for(p)
			if seen.has(b):
				fails.append("trial %d : %s revu au palier %d" % [trial, b, p])
			seen[b] = true
			var drawn: Dictionary = gs.prog.get("finals_drawn", {})
			drawn[str(p)] = b
			gs.prog["finals_drawn"] = drawn
			ach.counters["final_" + b] = true
			if gs.final_boss_for(p) != b:
				fails.append("instable")
	for f in keep:
		ach.counters["final_" + f] = keep[f]
	gs.palier = 84
	var hp: float = gs.scaled("hp") / float(gs.d("hp"))
	print("vie au palier 84 : x", hp)
	if absf(hp - 4.6) > 0.01: fails.append("cap")
	gs.palier = 10
	if absf(gs.scaled("hp") / float(gs.d("hp")) - 2.62) > 0.01: fails.append("p10")
	print("échecs : ", fails)
	print("RESULT ", "OK" if fails.is_empty() else "FAIL")
	quit()

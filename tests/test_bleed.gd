extends SceneTree
# Saignée en pourcentage : 20 % par coup avec les Griffes niv. 2, +30 % avec le Croc Sanglant (toutes armes).
# Coup puissant des griffes : 0,875 par griffe (1,75 au total).
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
	var pl = current_scene.player
	var C = pl.C
	var res := {}
	for case in [["aiguille", 1, false], ["aiguille", 1, true], ["griffes", 1, false], ["griffes", 2, false], ["griffes", 2, true]]:
		gs.prog["weapon"] = case[0]
		gs.prog["weapon_lv"] = {case[0]: case[1]}
		gs.prog["equipped"] = [C.BLOOD_FANG] if case[2] else []
		res["%s niv.%d%s" % [case[0], case[1], " + croc" if case[2] else ""]] = pl.bleed_chance()
	print(res)
	var ok: bool = is_equal_approx(res["aiguille niv.1"], 0.0) and is_equal_approx(res["aiguille niv.1 + croc"], 0.3) \
		and is_equal_approx(res["griffes niv.1"], 0.0) and is_equal_approx(res["griffes niv.2"], 0.2) and is_equal_approx(res["griffes niv.2 + croc"], 0.5)
	# coup puissant des griffes : deux griffes à 0,875 -> 1,75 ; un coup normal : 0,5 + 0,5 -> 1
	gs.prog["weapon"] = "griffes"
	gs.prog["equipped"] = []
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == current_scene.DummyScript:
			dummy = e
	pl.attack_kind = "finisher"
	pl.attack_crit = false
	pl.claw_split = true
	pl.claw_kind = "finisher"
	dummy.set_meta("claw_frac", 0.0)
	dummy.hits.clear()
	var per: float = 0.4375 * pl.hit_damage()
	pl._claw_hit(dummy, per, Vector2.ZERO)
	pl._claw_hit(dummy, per, Vector2.ZERO)
	var got := 0
	for h in dummy.hits:
		got += int(h[1])
	print("coup puissant : %.2f par griffe, %d dégât(s) entier(s) + reste %.2f" % [per, got, float(dummy.get_meta("claw_frac"))])
	ok = ok and is_equal_approx(per, 0.875) and got == 1 and is_equal_approx(float(dummy.get_meta("claw_frac")), 0.75)
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

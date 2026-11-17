extends SceneTree
# Combo aérien : entaille → entaille montante → vrille, sur le mannequin du Sanctuaire, pour chaque arme.
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
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
	await _frames(60)
	var pl = main.player
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == main.DummyScript:
			dummy = e
	dummy.global_position = Vector2(21 * 32, 16 * 32)   # à l'air libre (pas de plateforme au-dessus)
	await _frames(30)
	var all_ok := true
	for w in ["aiguille", "fouet", "marteau", "shuriken"]:
		gs.prog["weapon"] = w
		gs.trial_weapon = w
		pl.apply_equipment()
		pl.global_position = Vector2(dummy.global_position.x - 60.0, dummy.global_position.y - 6)
		pl.velocity = Vector2.ZERO
		pl.facing = 1.0
		await _frames(60)
		var t0 := Engine.get_physics_frames()
		Input.action_press("jump")
		await _frames(14)
		var res := []
		var hits := 0
		var y_peak: float = pl.global_position.y
		for k in 3:
			print("   coup %d : t=%.2f s, au sol=%s, vy=%.0f" % [k, float(Engine.get_physics_frames() - t0) / 120.0, pl.is_on_floor(), pl.velocity.y])
			var n0: int = dummy.hits.size()
			Input.action_press("attack")
			await _frames(2)
			Input.action_release("attack")
			var kind: String = pl.attack_kind
			var in_air: bool = not pl.is_on_floor()
			var hit := false
			for f in 140:
				await physics_frame
				y_peak = minf(y_peak, pl.global_position.y)
				if dummy.hits.size() > n0:
					hit = true
				if pl.attack_cd <= 0.0 and f > 6:
					break
			res.append("%s%s" % [kind, "✔" if hit else "✗"])
			if hit:
				hits += 1
		Input.action_release("jump")
		await _frames(120)
		# le marteau (lent) n'a le temps que de deux coups aériens par saut
		var seq_ok: bool = String(res[0]).begins_with("air") and String(res[1]).begins_with("air_rise") and (w == "marteau" or String(res[2]).begins_with("air_spin"))
		print("%-9s : %s" % [w, "  ".join(res)])
		if not seq_ok:
			all_ok = false
	gs.trial_weapon = ""
	print("RÉSULTAT : ", "OK" if all_ok else "ÉCHEC")
	quit()

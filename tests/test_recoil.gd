extends SceneTree
# Recul du héros quand il frappe le mannequin du Sanctuaire (cible fixe) : distance par coup,
# et le combo de 3 coups touche-t-il ? Debout ou accroupi, sans toucher aux flèches ou en avançant.
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.unlocked = 5
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
	for w in ["aiguille", "fouet", "marteau"]:
		for mode in ["debout", "avance", "accroupi"]:
			gs.prog["weapon"] = w
			gs.prog["weapon_lv"] = {}
			pl.global_position = Vector2(dummy.global_position.x - 50.0, dummy.global_position.y - 6)
			pl.velocity = Vector2.ZERO
			pl.facing = 1
			await _frames(60)
			if mode == "accroupi":
				Input.action_press("down")
				await _frames(6)
			var x0: float = pl.global_position.x
			var res := []
			var gaps := []
			for i in 3:
				var guard := 0
				while pl.attack_cd > 0.0 and guard < 600:
					if mode == "avance":
						Input.action_press("move_right")
					await physics_frame
					guard += 1
				await _frames(6)
				var n0: float = float(dummy.hits.back()[0]) if dummy.hits.size() > 0 else -1.0
				Input.action_press("attack")
				await _frames(2)
				Input.action_release("attack")
				for k in 40:
					await physics_frame
					if w == "marteau" and i == 2 and mode == "debout" and k % 3 == 0:
						var r: Rect2 = pl.attack_rect()
						print("   f%d kind=%s t=%.2f cd=%.2f x=%d rect=[%d..%d] mannequin=%s hits=%d" % [k, pl.attack_kind, pl.attack_t, pl.attack_cd, pl.global_position.x, r.position.x, r.end.x, dummy.get_rect(), 0])
					if (dummy.hits.size() > 0 and float(dummy.hits.back()[0]) > n0):
						break
				res.append("%s%s" % [pl.attack_kind, "✔" if (dummy.hits.size() > 0 and float(dummy.hits.back()[0]) > n0) else "✗"])
				gaps.append(int(dummy.global_position.x - pl.global_position.x))
			Input.action_release("move_right")
			Input.action_release("down")
			print("%-8s %-9s : %-34s recul total %3d px, écart au mannequin après chaque coup %s" % [w, mode, " ".join(res), int(x0 - pl.global_position.x), gaps])
	quit()

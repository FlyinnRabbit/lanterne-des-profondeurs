extends SceneTree
# Bancs en descente : ils soignent dans toutes les difficultés, quel que soit le record de la
# sauvegarde (ex. record palier 15, nouvelle descente au palier 7), à chaque niveau ; un banc
# déjà utilisé dans le même niveau ne soigne plus (anti-boucle en combat).
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _sit(main) -> void:
	var pl = main.player
	pl.global_position = main.bench_pos + Vector2(-10, 0)
	pl.velocity = Vector2.ZERO
	pl.bench_lock_t = 0.0
	await _frames(30)
	pl.bench_lock_t = 0.0
	Input.action_press("up")
	await _frames(3)
	Input.action_release("up")
	await _frames(5)
func _stand(main) -> void:
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	await _frames(10)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var ok := true
	for diff in 4:
		for pal in [1, 7, 15]:
			# un niveau avec un banc
			var found := false
			for st in range(1, gs.STEPS_PER_PALIER + 1):
				gs.record = 15
				gs.unlocked = 15
				gs.difficulty = diff
				gs.mode = "descent"
				gs.daily = false
				gs.palier = pal
				gs.step = st
				change_scene_to_file("res://main.tscn")
				await process_frame
				await process_frame
				paused = false
				await _frames(15)
				var main = current_scene
				if main.benches.is_empty():
					continue
				found = true
				main.bench_pos = main.benches[0]
				var pl = main.player
				pl.hp = 1
				await _sit(main)
				var healed: bool = pl.hp == pl.max_hp
				await _stand(main)
				pl.hp = 1
				main.bench_pos = main.benches[0]
				await _sit(main)
				var again: bool = pl.hp == pl.max_hp
				print("%s · palier %d niveau %d : soigné %s (%d/%d) ; 2e fois même banc : %s" % [gs.DIFFS[diff]["name"], pal, st, healed, pl.hp if again else 1, pl.max_hp, again])
				ok = ok and healed and not again
				await _stand(main)
				break
			if not found:
				print("%s · palier %d : aucun banc trouvé" % [gs.DIFFS[diff]["name"], pal])
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

extends SceneTree
# Coup final de chaque arme, niveau 1 et niveau 2 : le combo aboutit-il, et l'effet de niveau 2 apparaît-il ?
const Biomes = preload("res://scripts/biomes.gd")
const LevelGen = preload("res://scripts/levelgen.gd")
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
	pl.global_position.x = 30 * 32
	await _frames(30)
	for lv in [1, 2]:
		for w in ["aiguille", "fouet", "marteau", "shuriken"]:
			gs.prog["weapon"] = w
			gs.prog["weapon_lv"] = {w: lv}
			await _frames(150)
			for pr in get_nodes_in_group("projectiles"):
				pr.queue_free()
			await _frames(4)
			var kinds := []
			var seen := {}
			for i in 3:
				var guard := 0
				while pl.attack_cd > 0.0 and guard < 600:
					await physics_frame
					guard += 1
				await _frames(12)      # 100 ms de réaction
				Input.action_press("attack")
				await _frames(2)
				Input.action_release("attack")
				kinds.append(pl.attack_kind)
				for k in 10:
					await physics_frame
					for pr in get_nodes_in_group("projectiles"):
						if is_instance_valid(pr) and not pr.hostile:
							seen[pr.kind + (" (boomerang)" if pr.boomerang else "")] = int(seen.get(pr.kind + (" (boomerang)" if pr.boomerang else ""), 0)) + 1
			var pj := []
			for k in seen:
				pj.append(k)
			print("niv.%d %-9s : %s | projectiles vus : %s" % [lv, w, " > ".join(kinds), ", ".join(pj) if pj.size() > 0 else "aucun"])
	quit()

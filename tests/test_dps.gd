extends SceneTree
# Dégâts par seconde de chaque arme contre le mannequin (frappe en continu, 10 s), au contact et à distance.
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
	gs.prog["equipped"] = []
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	Engine.time_scale = 1.0
	await _frames(5)
	var main = current_scene
	var pl = main.player
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == main.DummyScript:
			dummy = e
	for w in ["aiguille", "fouet", "marteau", "shuriken"]:
		for dist in [40.0, 110.0]:
			gs.prog["weapon"] = w
			pl.facing = 1
			pl.global_position = Vector2(dummy.global_position.x - dist, dummy.global_position.y - 5)
			await _frames(20)
			var log := []
			main.hud.damage_log.clear()
			var total := 0
			var fn := func(e, d): total += 0
			dummy.hits.clear()
			var t0: float = dummy.anim_t
			for i in 600:
				if i % 2 == 0:
					Input.action_press("attack")
				else:
					Input.action_release("attack")
				pl.global_position.x = dummy.global_position.x - dist
				pl.facing = 1
				await physics_frame
			Input.action_release("attack")
			await _frames(2)
			var s := 0
			for h in dummy.hits:
				if float(h[0]) >= t0:
					s += int(h[1])
			print("%-9s à %3d px : %.2f dégâts/s" % [w, int(dist), s / 5.0])
	quit()

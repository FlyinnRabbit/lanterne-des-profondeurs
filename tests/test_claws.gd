extends SceneTree
# Griffes Jumelles : plus de coups par seconde que l'aiguille, moins d'âme par coup, saignée au niveau 2.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _hits(pl, dummy, w: String, secs: float) -> Array:
	var gs = root.get_node("GameState")
	gs.trial_weapon = w
	pl.apply_equipment()
	pl.global_position = Vector2(dummy.global_position.x - 30.0, dummy.global_position.y - 6)
	pl.facing = 1.0
	pl.velocity = Vector2.ZERO
	await _f(30)
	var t_start: float = dummy.anim_t
	var frames := int(secs * 120)
	for i in frames:
		if i % 30 == 15:
			pl.global_position.x = dummy.global_position.x - 30.0   # on reste au contact malgré le recul
		if i % 6 == 0:
			Input.action_press("attack")
		elif i % 6 == 2:
			Input.action_release("attack")
		await physics_frame
	Input.action_release("attack")
	await _f(150)
	var n := 0
	var dmg := 0
	for h in dummy.hits:
		if float(h[0]) >= t_start:
			n += 1
			dmg += int(h[1])
	return [n, dmg]
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
	await _f(60)
	var pl = main.player
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == main.DummyScript:
			dummy = e
	gs.prog["weapon_lv"] = {}
	var a: Array = await _hits(pl, dummy, "aiguille", 3.0)
	var c: Array = await _hits(pl, dummy, "griffes", 3.0)
	gs.prog["weapon_lv"] = {"griffes": 2}
	var c2: Array = await _hits(pl, dummy, "griffes", 3.0)
	gs.trial_weapon = "griffes"
	var sg: int = pl.soul_per_hit()
	gs.trial_weapon = "aiguille"
	var sa: int = pl.soul_per_hit()
	gs.trial_weapon = ""
	print("aiguille : %d coups, %d dégâts en 3 s" % a)
	print("griffes  : %d coups, %d dégâts en 3 s" % c)
	print("griffes niv. 2 (saignée) : %d coups, %d dégâts en 3 s" % c2)
	print("âme par coup : aiguille %d, griffes %d" % [sa, sg])
	var ok: bool = c[0] > a[0] * 1.15 and c2[1] > c[1] and sg < sa
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

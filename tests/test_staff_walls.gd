extends SceneTree
# Bâton : la zone de coup (et donc le bâton dessiné) s'arrête à la roche, dans les 4 directions,
# et le mannequin sous la plateforme fine du Sanctuaire n'est pas touché à travers elle.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _rock_in(main, r: Rect2) -> bool:
	# un point de la zone de coup est-il dans la roche ? (marge de 2 px sur les bords)
	var x := r.position.x + 2.0
	while x < r.end.x - 2.0:
		var y := r.position.y + 2.0
		while y < r.end.y - 2.0:
			if main.solid.has(Vector2i(floori(x / 32.0), floori(y / 32.0))):
				return true
			y += 4.0
		x += 4.0
	return false
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["weapons_owned"] = ["baton"]
	gs.prog["weapon"] = "baton"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _f(60)
	var pl = main.player
	pl.sitting = false
	var ok := true
	print("weapon=", pl.wid())
	# debout sur la plateforme haute (rangée 9), coup vers le bas : le bâton ne s'enfonce pas
	pl.global_position = Vector2(33 * 32, 9 * 32 - 17)
	pl.attack_kind = "slash"
	pl.attack_dir = Vector2.DOWN
	var rd: Rect2 = pl.attack_rect()
	print("bas sur plateforme : ", rd, " roche=", _rock_in(main, rd))
	if _rock_in(main, rd): ok = false
	# sous la plateforme, coup vers le haut
	pl.global_position = Vector2(33 * 32, 10 * 32 + 20)
	pl.attack_dir = Vector2.UP
	var ru: Rect2 = pl.attack_rect()
	print("haut sous plateforme : ", ru, " roche=", _rock_in(main, ru))
	if _rock_in(main, ru): ok = false
	# de côté vers la plateforme (le héros juste sous son bord, au niveau de la roche)
	pl.global_position = Vector2(27 * 32 - 30, 9 * 32 + 16)
	pl.facing = 1
	pl.attack_dir = Vector2.RIGHT
	for k in ["slash", "finisher", "low"]:
		pl.attack_kind = k
		var rs: Rect2 = pl.attack_rect()
		print(k, " de côté : ", rs, " roche=", _rock_in(main, rs))
		if _rock_in(main, rs): ok = false
	# à l'air libre, la portée reste entière
	pl.global_position = Vector2(10 * 32, 16 * 32 - 120)
	pl.attack_kind = "slash"
	pl.attack_dir = Vector2.RIGHT
	var rf: Rect2 = pl.attack_rect()
	print("air libre : largeur ", rf.size.x)
	if rf.size.x < 110.0: ok = false
	# et le mannequin sous la plateforme n'est pas touché par un coup vers le bas
	var dummy = null
	for e in get_nodes_in_group("enemies"):
		if e.get_script() == main.DummyScript:
			dummy = e
	dummy.set_physics_process(false)
	dummy.global_position = Vector2(33 * 32, 10 * 32 + 22)
	pl.global_position = Vector2(33 * 32, 9 * 32 - 17 - 24)
	pl.velocity = Vector2.ZERO
	await _f(30)
	pl.global_position = Vector2(33 * 32, 9 * 32 - 17 - 24)
	pl.velocity = Vector2.ZERO
	var n0: int = dummy.hits.size()
	Input.action_press("down")
	Input.action_press("attack")
	await _f(2)
	Input.action_release("attack")
	await _f(30)
	Input.action_release("down")
	print("mannequin touché à travers : ", dummy.hits.size() > n0)
	if dummy.hits.size() > n0: ok = false
	# 3e coup niv. 2 contre un mur fin : l'onde ne naît pas de l'autre côté
	gs.prog["weapon_lv"] = {"baton": 2}
	print("niveau bâton = ", pl.wlv())
	# mur fin d'une case posé sur le sol de la grande salle (le sol est en rangée 17)
	var wall_x := 11
	main.solid[Vector2i(wall_x, 16)] = true
	pl.global_position = Vector2(wall_x * 32 - 12, 17 * 32 - 17)
	if wall_x >= 0 and pl.wlv() >= 2:
		pl.facing = 1
		pl.velocity = Vector2.ZERO
		pl.attack_t = 0.0
		for i in 60:
			await physics_frame
			if pl.is_on_floor():
				break
		pl.attack_cd = 0.0
		print("au sol : ", pl.is_on_floor(), " pos ", pl.global_position)
		pl._start_attack("finisher", Vector2.RIGHT)
		var beyond := false
		for pr in get_nodes_in_group("projectiles"):
			if is_instance_valid(pr) and pr.kind == "wave" and not pr.hostile and pr.global_position.x > (wall_x + 1) * 32:
				beyond = true
		var n := 0
		for pr in get_nodes_in_group("projectiles"):
			if is_instance_valid(pr) and pr.kind == "wave" and not pr.hostile:
				n += 1
		print("ondes : ", n, " ; derrière le mur fin : ", beyond)
		if beyond: ok = false
	else:
		print("(pas de mur fin ou bâton niv. 2 indisponible : test de l'onde sauté)")
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

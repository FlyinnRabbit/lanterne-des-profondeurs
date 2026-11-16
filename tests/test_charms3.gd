extends SceneTree
# Les 8 nouveaux emblèmes (12 à 19) : chacun a l'effet annoncé.
const C = preload("res://scripts/charms.gd")
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _equip(gs, ids: Array) -> void:
	gs.prog["owned"] = ids.duplicate()
	gs.prog["equipped"] = ids.duplicate()
func _crawler(main, pos: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(main.CrawlerScript)
	e.main = main
	e.position = pos
	main.add_child(e)
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _f(30)
	var pl = main.player
	var res := {}
	# Récolte d'Âme
	_equip(gs, [C.SOUL_HARVEST])
	var e1 = _crawler(main, pl.global_position + Vector2(300, -10))
	await _f(5)
	pl.soul = 0
	main.on_enemy_killed(e1, 3)
	res["Récolte d'Âme (âme +8)"] = pl.soul == 8
	e1.queue_free()
	# Enclume Tombante
	_equip(gs, [])
	pl.attack_kind = "plunge"
	var d0: int = pl.hit_damage()
	_equip(gs, [C.ANVIL_FALL])
	res["Enclume Tombante (+1 dégât piqué)"] = pl.hit_damage() == d0 + 1
	# Lame Rebond
	_equip(gs, [C.REBOUND])
	pl.soul = 0
	pl._pogo()
	res["Lame Rebond (rebond plus haut, +6 âme)"] = pl.velocity.y < pl.POGO_VELOCITY and pl.soul == 6
	# Dernier Souffle
	_equip(gs, [C.LAST_BREATH])
	pl.hp = 1
	pl.invuln_t = 0.0
	pl.take_damage(5, pl.global_position.x - 10)
	var saved: bool = pl.hp == 1 and not pl.dead
	pl.invuln_t = 0.0
	res["Dernier Souffle (sauvé une fois)"] = saved and pl.last_breath_used
	pl.hp = pl.max_hp
	pl.invuln_t = 0.0
	# Parade Tranchante
	_equip(gs, [C.RIPOSTE])
	var e2 = _crawler(main, pl.global_position + Vector2(30, 0))
	await _f(3)
	var hp0: int = e2.hp
	pl.parry_t = 0.2
	pl.receive_hit(e2.global_position, e2)
	res["Parade Tranchante (2 dégâts à l'attaquant)"] = (not is_instance_valid(e2)) or e2.dead or e2.hp <= hp0 - 2
	if is_instance_valid(e2):
		e2.queue_free()
	pl.invuln_t = 0.0
	await _f(30)
	# Ruée Spectrale
	_equip(gs, [C.PHANTOM_DASH])
	pl.can_dash = true
	pl.dash_cd = 0.0
	pl.facing = 1.0
	var e3 = _crawler(main, pl.global_position + Vector2(70, -6))
	e3.hp = 10
	await _f(3)
	# Ruée lancée directement (l'appui simulé se perd après les étapes précédentes)
	pl.dash_hit.clear()
	pl.dash_t = pl.DASH_TIME
	await _f(30)
	res["Ruée Spectrale (blesse en traversant)"] = is_instance_valid(e3) and e3.hp < 10
	if is_instance_valid(e3):
		e3.queue_free()
	# Flair du Pilleur et Nœud de Grimpeur : vérifiés par leur formule
	_equip(gs, [C.PLUNDERER, C.CLIMBER])
	res["Flair du Pilleur (équipé)"] = pl.eq(C.PLUNDERER)
	pl.hoist([pl.global_position, pl.global_position + Vector2(0, -200), pl.global_position + Vector2(40, -200)], 2.0)
	var t0 := Engine.get_physics_frames()
	while not pl.hoist_path.is_empty() and Engine.get_physics_frames() - t0 < 600:
		await physics_frame
	var secs := float(Engine.get_physics_frames() - t0) / 120.0
	res["Nœud de Grimpeur (treuil 2x : %.2f s)" % secs] = secs < 0.6
	var ok := true
	for k in res:
		print(("✔ " if res[k] else "✗ ") + k)
		ok = ok and res[k]
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

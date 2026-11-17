extends SceneTree
# Nouvelles armes (faux, bâton) et nouveaux mobs (singe, mimique, mite, taupe)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _mk(main, path: String, pos: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(load(path))
	e.main = main
	e.position = pos
	main.add_child(e)
	return e
func _count(kind: String) -> int:
	var n := 0
	for p in get_nodes_in_group("projectiles"):
		if p.kind == kind: n += 1
	return n
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	pl.sitting = false
	var ok := true
	var feet: float = pl.get_rect().end.y
	# --- faux : finisher autour du héros, niv. 2 lame fantôme
	gs.prog["weapon"] = "faux"
	gs.prog["weapon_lv"] = {"faux": 2, "baton": 2}
	pl.attack_kind = "finisher"
	var fr: Rect2 = pl.attack_rect()
	print("faux finisher rect ", fr.size, " covers behind: ", fr.position.x < pl.global_position.x - 40)
	if not fr.position.x < pl.global_position.x - 40: ok = false
	pl._start_attack("finisher", Vector2(pl.facing, 0))
	await _f(2)
	print("ghost scythe: ", _count("ghostscythe"))
	if _count("ghostscythe") < 1: ok = false
	pl.attack_t = 0.0
	await _f(30)
	# --- bâton : saut à la perche accroupi, niv. 2 onde
	gs.prog["weapon"] = "baton"
	pl.velocity = Vector2.ZERO
	await _f(10)
	pl._start_attack("low", Vector2(pl.facing, 0))
	print("baton vault vy=", pl.velocity.y)
	if pl.velocity.y > -400.0: ok = false
	for i in 120:
		await physics_frame
		if pl.is_on_floor() and i > 20: break
	pl._start_attack("finisher", Vector2(pl.facing, 0))
	await _f(2)
	print("baton wave: ", _count("wave"))
	await _f(40)
	gs.prog["weapon"] = "aiguille"
	# --- singe : vole puis rend en mourant
	pl.geo = 100
	pl.invuln_t = 0.0
	var m = _mk(main, "res://scripts/monkey.gd", pl.global_position + Vector2(30, 0))
	for i in 240:
		await physics_frame
		pl.invuln_t = 0.0
		if m.loot > 0: break
	print("monkey loot=", m.loot, " geo=", pl.geo)
	if m.loot <= 0: ok = false
	var before: int = pl.geo
	m.hp = 1
	m.take_hit(5, Vector2.RIGHT)
	await _f(2)
	print("after kill geo ", before, " -> ", pl.geo)
	if pl.geo <= before: ok = false
	# --- mimique : dort, se réveille quand on approche
	var mi = _mk(main, "res://scripts/mimic.gd", pl.global_position + Vector2(200, 0))
	await _f(10)
	print("mimic asleep harmful=", mi.is_harmful(), " state=", mi.state)
	if mi.is_harmful(): ok = false
	pl.global_position.x = mi.global_position.x - 40
	await _f(100)
	print("mimic state=", mi.state, " st=", mi.state_t, " ts=", Engine.time_scale, " proc=", mi.is_physics_processing(), " anim=", mi.anim_t)
	if mi.state != "hop": ok = false
	mi.queue_free()
	await _f(5)
	# --- mites : assombrissent
	var mo = _mk(main, "res://scripts/moth.gd", pl.global_position + Vector2(40, -30))
	var mo2 = _mk(main, "res://scripts/moth.gd", pl.global_position + Vector2(-40, -30))
	await _f(90)
	print("moth dim=", main.moth_dim)
	if main.moth_dim < 0.2: ok = false
	mo.queue_free(); mo2.queue_free()
	await _f(5)
	# --- taupe : intouchable sous terre, jaillit sous le héros
	var ml = _mk(main, "res://scripts/mole.gd", pl.global_position + Vector2(150, 0))
	await _f(5)
	var hp0: int = ml.hp
	ml.take_hit(2, Vector2.RIGHT)
	print("mole under hit hp ", hp0, " -> ", ml.hp)
	if ml.hp != hp0: ok = false
	pl.invuln_t = 0.0
	var php: int = pl.hp
	var states := {}
	for i in 500:
		await physics_frame
		pl.velocity.x = 0.0
		states[ml.state] = true
		if ml.state == "exposed": break
	print("mole states=", states.keys(), " player hp ", php, " -> ", pl.hp)
	if not states.has("windup") or not states.has("exposed"): ok = false
	ml.take_hit(1, Vector2.RIGHT)
	print("mole exposed hit hp=", ml.hp)
	if ml.hp >= hp0: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

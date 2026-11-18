extends SceneTree
# Duel local : deux joueurs, coups entre eux, parade, manches, fin du duel
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _unfreeze(main):
	for i in 600:
		await physics_frame
		if main.duel_freeze <= 0.0 and main.duel_players[0].is_physics_processing():
			break
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(5)
	# pas de manette dans le test : on lance le duel sans passer par la répartition des manettes
	gs.duel_w = ["aiguille", "marteau"]
	gs.duel_score = [0, 0]
	gs.snapshot = gs.prog.duplicate(true)
	gs.mode = "duel"
	gs._reload(true)
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var ok := true
	print("players=", main.duel_players.size(), " hp=", main.duel_players[0].hp, "/", main.duel_players[1].hp, " weapons=", main.duel_players[0].wid(), ",", main.duel_players[1].wid())
	if main.duel_players.size() != 2: ok = false
	await _unfreeze(main)    # compte à rebours
	var a = main.duel_players[0]
	var b = main.duel_players[1]
	b.global_position = a.global_position + Vector2(40, 0)
	a.facing = 1
	await _f(5)
	var hp0: int = b.hp
	a._start_attack("slash", Vector2.RIGHT)
	print("freeze=", main.duel_freeze, " procA=", a.is_physics_processing(), " attack_t=", a.attack_t, " rect ", a.attack_rect(), " b ", b.get_rect(), " inter=", a.attack_rect().intersects(b.get_rect()), " grp=", b.is_in_group("enemies"))
	await _f(12)
	print("P2 hit: hp ", hp0, " -> ", b.hp, " ; P1 hp ", a.hp)
	if b.hp >= hp0 or a.hp != 9: ok = false
	# parade de J2
	await _f(60)
	b.invuln_t = 0.0
	a.attack_cd = 0.0
	b.global_position = a.global_position + Vector2(40, 0)
	a.facing = 1
	await _f(2)
	b.parry_t = b.parry_window()
	var hpb: int = b.hp
	a._start_attack("slash", Vector2.RIGHT)
	await _f(6)
	print("parry: P2 hp ", hpb, " -> ", b.hp, " P1 knock_t=", a.knock_t)
	if b.hp != hpb or a.knock_t <= 0.0: ok = false
	# K.-O. : manche pour J1
	await _f(40)
	b.invuln_t = 0.0
	b.take_damage(99, a.global_position.x)
	for i in 600:
		await physics_frame
		if not b.dead: break
	await _unfreeze(main)
	print("score=", gs.duel_score, " P2 hp after new round=", b.hp, " dead=", b.dead)
	if gs.duel_score != [1, 0] or b.hp != 9 or b.dead: ok = false
	# deux manches de plus : fin du duel
	for r in 2:
		b.invuln_t = 0.0
		b.take_damage(99, a.global_position.x)
		for i in 600:
			await process_frame
			if gs.mode != "duel" or not b.dead: break
		if gs.mode == "duel":
			await _unfreeze(main)
	await process_frame
	await process_frame
	print("mode after duel=", gs.mode, " message=", gs.pending_message)
	if gs.mode != "hub": ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

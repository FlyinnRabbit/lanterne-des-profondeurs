extends SceneTree
# Nouveaux pièges : main (agrippe), vapeur (blesse debout, pas accroupi), livre (pages), goutte (acide),
# cristal (onde au sol), pièges qui blessent les ennemis, gravats des Mines.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
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
	var px: float = pl.global_position.x
	# main squelettique
	var h = main._make_trap("hand", Vector2(px, feet), {})
	for i in 60:
		await physics_frame
		if pl.grab_t > 0.0: break
	print("hand: dx=", pl.global_position.x - h.global_position.x, " feet-dy=", pl.get_rect().end.y - h.global_position.y, " state=", h.hand_state, " grab_t=", pl.grab_t, " speed=", pl.run_speed())
	if pl.grab_t <= 0.0 or pl.run_speed() > 0.0: ok = false
	h.queue_free()
	pl.grab_t = 0.0
	await _f(5)
	# vapeur : debout = touché, accroupi = esquive
	var st = main._make_trap("steam", Vector2(px - 60, feet), {"dir": 1.0})
	st.t = st.CYCLE["steam"][0] + st.CYCLE["steam"][1] + 0.3
	await _f(1)
	var stand_hit: bool = st._hits(pl.get_rect(), pl.global_position)
	pl.crouching = true
	var crouch_hit: bool = st._hits(pl.get_rect(), pl.global_position)
	pl.crouching = false
	print("steam: standing hit=", stand_hit, " crouched hit=", crouch_hit)
	if not stand_hit or crouch_hit: ok = false
	st.queue_free()
	# livre maudit
	var bk = main._make_trap("book", Vector2(px + 150, feet), {})
	bk.t = bk.CYCLE["book"][0] + bk.CYCLE["book"][1] - 0.05
	await _f(10)
	print("book pages=", _count("page"))
	if _count("page") < 3: ok = false
	bk.queue_free()
	# goutte acide
	var dr = main._make_trap("drip", Vector2(px + 300, feet - 200), {})
	dr.t = dr.CYCLE["drip"][0] + dr.CYCLE["drip"][1] - 0.05
	await _f(10)
	print("drip acid=", _count("acid"))
	if _count("acid") < 1: ok = false
	dr.queue_free()
	# cristal : onde au sol, sautée = pas touché
	var cr = main._make_trap("crystal", Vector2(pl.global_position.x - 80, pl.get_rect().end.y), {})
	cr.t = cr.CYCLE["crystal"][0] + cr.CYCLE["crystal"][1] + cr.CYCLE["crystal"][2] * (80.0 / 130.0)
	await _f(1)
	cr.t = cr.CYCLE["crystal"][0] + cr.CYCLE["crystal"][1] + cr.CYCLE["crystal"][2] * (80.0 / 130.0)
	var g_hit: bool = cr._hits(pl.get_rect(), pl.global_position)
	var r2: Rect2 = pl.get_rect()
	r2.position.y -= 60
	var j_hit: bool = cr._hits(r2, pl.global_position + Vector2(0, -60))
	print("crystal dx ", pl.global_position.x - cr.global_position.x, " k ", cr._phase_k(), " ph ", cr._phase(), " feet ", pl.get_rect().end.y, " cy ", cr.global_position.y)
	print("crystal: grounded hit=", g_hit, " jumping hit=", j_hit)
	if not g_hit or j_hit: ok = false
	cr.queue_free()
	# un rampant sur une herse active : blessé
	var e := CharacterBody2D.new()
	e.set_script(main.CrawlerScript)
	e.main = main
	e.position = Vector2(px + 450, feet - 12)
	main.add_child(e)
	await _f(10)
	e.lunge_cd = 99.0
	var hp0: int = e.hp
	var sp = main._make_trap("spikes", Vector2(e.global_position.x, feet), {})
	sp.t = sp.CYCLE["spikes"][0] + sp.CYCLE["spikes"][1] - 0.02
	await _f(10)
	print("crawler on spikes hp ", hp0, " -> ", e.hp if is_instance_valid(e) else -1)
	if is_instance_valid(e) and e.hp >= hp0 and not e.dead: ok = false
	sp.queue_free()
	# gravats
	var r0 := _count("rock")
	main.debris_rain(px, feet)
	await _f(90)
	print("debris rocks spawned=", _count("rock") - r0)
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

extends SceneTree
# Tisseuse : crache de la toile qui englue le héros (vitesse réduite), la ruée l'arrache,
# la toile ratée reste au sol ; touchée elle tombe, puis remonte quand le héros s'éloigne.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.prog["can_dash"] = true
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	var pl = main.player
	print("sitting=", pl.sitting)
	pl.sitting = false
	var ok := true
	var e := CharacterBody2D.new()
	e.set_script(main.WeaverScript)
	e.main = main
	e.position = pl.global_position + Vector2(180, -40)
	main.add_child(e)
	await _f(2)
	print("anchor ", e.anchor, " pos ", e.global_position, " player ", pl.global_position)
	var shot := false
	var patch := false
	for i in 300:
		await physics_frame
		for pr in get_nodes_in_group("projectiles"):
			if pr.kind == "web":
				shot = true
				if i % 10 == 0: print("  web at ", pr.global_position, " life ", pr.life)
			if pr.kind == "webpatch": patch = true
		if pl.web_t > 0.0: break
	print("web shot=", shot, " ensnared=", pl.web_t, " patch=", patch)
	if not shot: ok = false
	if pl.web_t > 0.0:
		var rs: float = pl.run_speed()
		if rs >= pl.RUN_SPEED * 0.9: ok = false; print("FAIL speed not reduced ", rs)
		Input.action_press("dash")
		await _f(3)
		Input.action_release("dash")
		print("after dash web_t=", pl.web_t)
		if pl.web_t > 0.0: ok = false
	# touchée : elle tombe
	e.take_hit(1, Vector2.RIGHT)
	await _f(60)
	print("after hit state=", e.state, " floor=", e.is_on_floor())
	if e.state == "hang" or e.state == "windup_web": ok = false
	# le héros s'éloigne : elle remonte
	pl.global_position.x = e.global_position.x - 500
	var climbed := false
	for i in 240:
		await physics_frame
		pl.global_position.x = e.global_position.x - 500
		if e.state == "climb" or (e.state == "hang"): climbed = true
	print("climbed=", climbed, " state=", e.state)
	if not climbed: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

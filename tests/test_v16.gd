extends SceneTree
# Armes, accroupi, combo aérien, plongée, parade parfaite → critique. --shots : captures.
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _tap(a: String) -> void:
	Input.action_press(a); await _frames(2); Input.action_release(a)
func _shot(n: String) -> void:
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % n)
func _target(main, offset: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(main.CrawlerScript)
	e.main = main
	e.position = main.player.global_position + offset
	main.add_child(e)
	await _frames(2)
	e.hp = 999
	e.hp_max = 999
	e.set_physics_process(false)
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["weapon"] = "aiguille"
	change_scene_to_file("res://main.tscn")
	paused = false
	Engine.time_scale = 1.0
	await _frames(5)
	var main = current_scene
	var pl = main.player
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	pl.can_dash = true
	pl.facing = 1
	pl.global_position = Vector2(36 * 32, 16 * 32)
	await _frames(30)
	var d = await _target(main, Vector2(46, 0))
	# --- dégâts par arme
	for w in ["aiguille", "fouet", "marteau", "shuriken"]:
		gs.prog["weapon"] = w
		pl.global_position = Vector2(d.global_position.x - (110.0 if w == "fouet" else 46.0), pl.global_position.y)
		pl.attack_cd = 0.0
		pl.combo_t = 0.0
		await _frames(3)
		var h0: int = d.hp
		_tap("attack")
		await _frames(50)
		print("arme %s : dégâts %d, cd %.2f" % [w, h0 - d.hp, pl.ATTACK_COOLDOWN * float(pl.weapon()["cd"])])
		if w == "fouet" or w == "shuriken":
			pl.global_position.x = d.global_position.x - (110.0 if w == "fouet" else 200.0)
			_tap("attack"); await _frames(4)
			await _shot("w_" + w)
			await _frames(40)
	gs.prog["weapon"] = "aiguille"
	# --- accroupi : la boîte rétrécit
	Input.action_press("down"); await _frames(10)
	print("accroupi : ", pl.crouching, " rect ", pl.get_rect().size)
	pl.global_position.x = d.global_position.x - 46.0
	await _frames(3)
	var h1: int = d.hp
	_tap("attack"); await _frames(5)
	print("coup bas : ", pl.attack_kind)
	await _shot("crouch")
	await _frames(40)
	Input.action_release("down"); await _frames(10)
	print("relevé : ", not pl.crouching, " dégâts coup bas ", h1 - d.hp)
	# --- combo aérien
	pl.global_position.x = d.global_position.x - 150.0
	await _frames(5)
	Input.action_press("jump"); await _frames(14); Input.action_release("jump")
	print("sol avant combo aérien : ", pl.is_on_floor(), " vel ", pl.velocity)
	var ak := []
	for i in 3:
		pl.attack_cd = 0.0
		print("  cd ", pl.attack_cd, " knock ", pl.knock_t, " charge ", pl.charge_t, " attack_t ", pl.attack_t, " pressed ", Input.is_action_pressed("attack"))
		Input.action_press("attack")
		for j in 3:
			await _frames(1)
			print("    j", j, " kind ", pl.attack_kind, " t ", pl.attack_t)
		Input.action_release("attack"); await _frames(1)
		ak.append("%s/sol=%s/t=%.2f" % [pl.attack_kind, pl.is_on_floor(), pl.attack_t])
		await _frames(12)
	print("combo aérien : ", ak)
	await _frames(80)
	# --- plongée
	pl.global_position = Vector2(d.global_position.x - 60.0, d.global_position.y - 160.0)
	pl.velocity = Vector2.ZERO
	await _frames(3)
	var h2: int = d.hp
	print("avant plongée : sol ", pl.is_on_floor(), " pos ", pl.global_position, " dash_t ", pl.dash_t, " knock ", pl.knock_t)
	Input.action_press("down"); await _frames(1)
	Input.action_press("dash")
	for i in 3:
		await _frames(1)
		print("  f", i, " plunging ", pl.plunging, " down ", Input.is_action_pressed("down"), " dash ", Input.is_action_pressed("dash"))
	Input.action_release("dash")
	print("plongée en cours : ", pl.plunging, " pos ", pl.global_position, " vel ", pl.velocity)
	await _frames(6)
	await _shot("plunge")
	Input.action_release("down")
	await _frames(40)
	print("plongée terminée : ", not pl.plunging, " dégâts onde ", h2 - d.hp)
	# --- parade parfaite → critique
	pl.global_position.x = d.global_position.x - 46.0
	await _frames(20)
	pl.parry_cd = 0.0
	_tap("parry"); await _frames(3)
	var ok: bool = pl.receive_hit(pl.global_position + Vector2(30, 0), null)
	print("parade : ", ok, " critique prêt : ", pl.crit_ready)
	await _frames(30)
	await _shot("crit_ready")
	pl.attack_cd = 0.0
	pl.combo_t = 0.0
	var h3: int = d.hp
	_tap("attack"); await _frames(40)
	print("coup critique : dégâts %d (normal %d), critique prêt après : %s" % [h3 - d.hp, pl.nail_damage(), pl.crit_ready])
	# parade tardive : pas de critique
	pl.parry_cd = 0.0
	_tap("parry"); await _frames(20)
	ok = pl.receive_hit(pl.global_position + Vector2(30, 0), null)
	print("parade tardive : ", ok, " critique : ", pl.crit_ready)
	# --- arsenal
	main.hub_ui.open_arsenal()
	await _frames(3)
	await _shot("arsenal")
	pl.geo = 1000
	main.hub_ui._pick_weapon("marteau")
	print("arsenal : arme ", gs.weapon(), " éclats ", pl.geo)
	main.hub_ui.close_all()
	quit()

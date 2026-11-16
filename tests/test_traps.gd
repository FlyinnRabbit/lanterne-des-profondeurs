extends SceneTree
# Pièges en hauteur et plateformes spéciales. --shots : captures.
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _shot(n: String) -> void:
	if shots:
		for cam in current_scene.find_children("*", "Camera2D", true, false):
			cam.reset_smoothing()
			cam.force_update_scroll()
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % n)
func _find(main, ch: String) -> Vector2i:
	for y in main.MAP.size():
		var x: int = (main.MAP[y] as String).find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)
func _load(gs, ch: String):
	for p in range(1, 9):
		for st in [1, 2]:
			gs.mode = "descent"
			gs.palier = p
			gs.step = st
			change_scene_to_file("res://main.tscn")
			await process_frame   # le changement de scène est différé
			await process_frame
			paused = false
			Engine.time_scale = 1.0
			await _frames(4)
			var main = current_scene
			var c := _find(main, ch)
			if c.x >= 0:
				for e in get_nodes_in_group("enemies"):
					e.queue_free()
				return [main, c]
	return [null, Vector2i(-1, -1)]
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.run_seed = 4242
	# --- lame-pendule : touche debout, pas accroupi au point bas
	var r = await _load(gs, "U")
	var main = r[0]
	var c: Vector2i = r[1]
	var pl = main.player
	var blade = null
	for n in main.get_children():
		if n.get_script() == main.TrapScript and n.kind == "blade":
			blade = n
			break
	blade.set_physics_process(false)
	blade.t = 0.0
	blade.phase = PI / 2.0 / 1.9 * 0.0 + asin(1.0) / 1.9 * 0.0 + 0.0
	blade.amp = 1.05
	# lame tout à gauche pendant qu'on se place
	blade.phase = -PI / 2.0
	pl.global_position = Vector2(c.x * 32 + 16, blade.floor_y - 18.0)
	Input.action_press("down")
	await _frames(20)
	pl.invuln_t = 0.0
	var hp0: int = pl.hp
	blade.phase = 0.0          # sin(0) = 0 : point bas, juste au-dessus du héros
	blade.set_physics_process(true)
	await _frames(3)
	blade.set_physics_process(false)
	var bp = blade.blade_pos()
	print("   lame ", Rect2(bp - Vector2(16, 9), Vector2(32, 18)), " joueur ", pl.get_rect(), " vel ", pl.velocity, " axe ", Input.get_axis("move_left", "move_right"))
	print("pendule, accroupi : pv %d -> %d (accroupi=%s)" % [hp0, pl.hp, pl.crouching])
	await _shot("trap_blade")
	Input.action_release("down")
	await _frames(10)
	pl.invuln_t = 0.0
	blade.t = 0.0
	blade.set_physics_process(true)
	await _frames(3)
	print("pendule, debout : pv %d -> %d" % [hp0, pl.hp])
	# --- plateforme mobile
	r = await _load(gs, "H")
	main = r[0]; c = r[1]; pl = main.player
	var mover = null
	for n in main.get_children():
		if n.get_script() == main.PlatformScript and n.kind == "mover":
			mover = n
	var x0: float = mover.position.x
	pl.global_position = Vector2(mover.position.x + 48, mover.position.y - 18)
	await _frames(120)
	print("plateforme mobile : x %.0f -> %.0f, joueur porté : %.0f (sur le sol : %s, pv %d)" % [x0, mover.position.x, pl.global_position.x - mover.position.x, pl.is_on_floor(), pl.hp])
	await _shot("trap_mover")
	# --- blocs fragiles
	r = await _load(gs, "C")
	main = r[0]; c = r[1]; pl = main.player
	var cr = null
	for n in main.get_children():
		if n.get_script() == main.PlatformScript and n.kind == "crumble":
			cr = n
			break
	pl.global_position = Vector2(cr.position.x + 16, cr.position.y - 18)
	await _frames(30)
	print("bloc fragile : état ", cr.state)
	await _shot("trap_crumble")
	await _frames(60)
	print("bloc fragile après 0,75 s : état ", cr.state, " (joueur y %.0f, bloc y %.0f)" % [pl.global_position.y, cr.position.y])
	# --- stalactite et totem
	r = await _load(gs, "V")
	main = r[0]; c = r[1]; pl = main.player
	var st = null
	for n in main.get_children():
		if n.get_script() == main.TrapScript and n.kind == "stalactite":
			st = n
			break
	var fy := c.y + 1
	while not main.solid.has(Vector2i(c.x, fy)):
		fy += 1
	pl.global_position = Vector2(st.position.x + 60, fy * 32 - 18)
	await _frames(5)
	pl.global_position.x = st.position.x
	await _frames(30)
	print("stalactite : ", st.state)
	await _shot("trap_stalactite")
	r = await _load(gs, "Z")
	main = r[0]; c = r[1]; pl = main.player
	var tot = null
	for n in main.get_children():
		if n.get_script() == main.TrapScript and n.kind == "dart":
			tot = n
	pl.global_position = Vector2(tot.position.x + tot.dir * 160.0, tot.position.y - 18)
	pl.hp = pl.max_hp
	Input.action_press("down")
	tot.t = tot.period - 0.05
	for i in 15:
		await _frames(10)
		for n in main.get_children():
			if n.get_script() == main.ProjectileScript and n.kind == "dart":
				print("   dart ", n.global_position, " vel ", pl.velocity, " axe ", Input.get_axis("move_left", "move_right"), " recoil ", pl.recoil_t, " knock ", pl.knock_t)
	print("fléchettes accroupi : pv %d / %d" % [pl.hp, pl.max_hp])
	Input.action_release("down")
	await _frames(10)
	pl.invuln_t = 0.0
	pl.global_position = Vector2(tot.position.x + tot.dir * 160.0, tot.position.y - 18)
	tot.t = tot.period - 0.05
	await _frames(40)
	await _shot("trap_dart")
	await _frames(100)
	print("fléchettes debout : pv %d / %d" % [pl.hp, pl.max_hp])
	quit()

extends SceneTree
# Piqué (bas + ruée en l'air) et accroupi : que se passe-t-il à l'atterrissage, et l'inverse ?
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _rel() -> void:
	for a in ["down", "dash", "jump", "move_right", "attack"]:
		Input.action_release(a)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	gs.show_title = false
	gs.unlocked = 5
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	var main = current_scene
	await _frames(60)
	var pl = main.player
	var x0: float = pl.global_position.x
	pl.can_dash = true
	for toggle in [false, true]:
		st.crouch_toggle = toggle
		var tag := "[accroupi en bascule]" if toggle else "[accroupi maintenu]"
		# A. piqué en maintenant bas, puis on garde bas après l'atterrissage
		_rel()
		pl.crouch_latch = false
		pl.global_position = Vector2(x0, pl.global_position.y)
		await _frames(30)
		Input.action_press("jump")
		await _frames(18)
		Input.action_release("jump")
		Input.action_press("down")
		Input.action_press("dash")
		await _frames(2)
		Input.action_release("dash")
		var plunged: bool = pl.plunging
		var guard := 0
		while not pl.is_on_floor() and guard < 200:
			await physics_frame
			guard += 1
		await _frames(6)
		var crouch_after: bool = pl.crouching
		Input.action_press("move_right")
		var xa: float = pl.global_position.x
		await _frames(30)
		var speed: float = (pl.global_position.x - xa) / 0.25
		Input.action_press("attack")
		await _frames(2)
		Input.action_release("attack")
		var kind: String = pl.attack_kind
		print("%s A. piqué %s, bas maintenu à l'atterrissage -> accroupi %s, vitesse %d px/s, attaque « %s »" % [tag, "lancé" if plunged else "PAS lancé", crouch_after, speed, kind])
		_rel()
		await _frames(30)
		# B. piqué puis on relâche bas juste après l'atterrissage
		pl.crouch_latch = false
		Input.action_press("jump")
		await _frames(18)
		Input.action_release("jump")
		Input.action_press("down")
		Input.action_press("dash")
		await _frames(2)
		Input.action_release("dash")
		guard = 0
		while not pl.is_on_floor() and guard < 200:
			await physics_frame
			guard += 1
		Input.action_release("down")
		await _frames(10)
		print("%s B. piqué, bas relâché à l'atterrissage -> accroupi %s" % [tag, pl.crouching])
		# C. accroupi au sol puis ruée
		_rel()
		await _frames(20)
		Input.action_press("down")
		await _frames(10)
		var c0: bool = pl.crouching
		Input.action_press("dash")
		await _frames(2)
		Input.action_release("dash")
		await _frames(4)
		print("%s C. accroupi (%s) + ruée -> ruée %s, piqué %s, accroupi pendant la ruée %s, hauteur de la boîte %d" % [tag, c0, pl.dash_t > 0.0, pl.plunging, pl.crouching, pl.get_rect().size.y])
		await _frames(30)
		print("%s    après la ruée, bas toujours maintenu : accroupi %s" % [tag, pl.crouching])
		_rel()
		await _frames(30)
		# D. accroupi en bas d'une plateforme : sauter, puis piqué tout de suite
		Input.action_press("down")
		await _frames(10)
		Input.action_press("jump")
		await _frames(2)
		var jumped: bool = not pl.is_on_floor() or pl.velocity.y < 0.0
		await _frames(10)
		Input.action_release("jump")
		Input.action_press("dash")
		await _frames(2)
		Input.action_release("dash")
		print("%s D. accroupi + saut -> saute %s ; puis ruée avec bas maintenu -> piqué %s" % [tag, jumped, pl.plunging])
		_rel()
		await _frames(60)
	quit()

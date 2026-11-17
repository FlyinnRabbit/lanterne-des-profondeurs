extends SceneTree
# Arène de boss : depuis l'extérieur de la grille, ni coup ni projectile ne touche le boss.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.difficulty = 1
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 2
	gs.curse = ""
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	var pl = main.player
	var g = main.entry_gate
	var boss = main.boss
	# le combat démarre, puis le héros se retrouve dehors, collé à la grille fermée, le boss juste derrière
	pl.global_position = Vector2(g.rect.end.x + 120, g.rect.end.y - 30)
	await _f(60)
	g.set_closed(true)
	main.boss_started = true
	pl.global_position = Vector2(g.rect.position.x - 20, g.rect.end.y - 24)
	pl.facing = 1.0
	pl.velocity = Vector2.ZERO
	boss.set_physics_process(false)
	boss.global_position = Vector2(g.rect.end.x + 30, g.rect.end.y - 40)
	await _f(10)
	var hp0: int = boss.hp
	for k in 3:
		pl.attack_cd = 0.0
		Input.action_press("attack")
		await _f(2)
		Input.action_release("attack")
		await _f(50)
	var after_melee: int = boss.hp
	# projectile du joueur lancé vers le boss depuis dehors
	main.spawn_projectile(pl.global_position + Vector2(10, -4), Vector2(500, 0), {"kind": "soul", "hostile": false, "damage": 3, "life": 1.0})
	await _f(80)
	var after_proj: int = boss.hp
	print("vie du boss : %d → coups %d → projectile %d" % [hp0, after_melee, after_proj])
	# filet de sécurité : héros dehors pendant le combat → remis dans l'arène
	main.arena_entry_pos = Vector2(g.rect.end.x + 120, g.rect.end.y - 30)
	boss.set_physics_process(true)
	pl.global_position = Vector2(g.rect.position.x - 60, g.rect.end.y - 24)
	await _f(10)
	var back_in: bool = pl.global_position.x > g.rect.end.x
	print("héros remis dans l'arène : ", back_in)
	print("RÉSULTAT : ", "OK" if after_proj == hp0 and back_in else "ÉCHEC")
	quit()

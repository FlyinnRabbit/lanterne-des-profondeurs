extends SceneTree
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _mob(main, script, pos: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(script)
	e.main = main
	e.position = pos
	main.add_child(e)
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["weapon"] = "fouet"
	gs.prog["weapons_owned"] = ["fouet"]
	gs.prog["weapon_lv"] = {"fouet": 2}
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	Engine.time_scale = 1.0
	await _frames(5)
	var main = current_scene
	var pl = main.player
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	pl.global_position = Vector2(20 * 32, 16 * 32)
	pl.facing = 1
	await _frames(20)
	# fouet niv. 2 sur des ennemis de plus en plus loin
	for dist in [110.0, 150.0, 190.0]:
		var e = await _mob(main, main.CrawlerScript, pl.global_position + Vector2(dist, 0))
		await _frames(3)
		e.hp = 99
		pl.hp = pl.max_hp
		pl.invuln_t = 0.0
		pl.attack_cd = 0.0
		Input.action_press("attack"); await _frames(2); Input.action_release("attack")
		await _frames(50)
		print("fouet niv.2 à %d px : arrive à %d px, pv joueur %d/%d, étourdi %s" % [int(dist), int(e.global_position.x - pl.global_position.x), pl.hp, pl.max_hp, e.stun_t > 0.0])
		e.queue_free()
		await _frames(60)
	# étourdissement à la parade : normale / parfaite
	for perfect in [false, true]:
		var c = await _mob(main, main.CrawlerScript, pl.global_position + Vector2(200, 0))
		await _frames(2)
		pl.parry_perfect_now = perfect
		c.parried(Vector2.RIGHT)
		print("parade %s : étourdi %.2f s" % ["parfaite" if perfect else "normale", c.stun_t])
		c.queue_free()
	pl.parry_perfect_now = false
	# boss : pas d'étourdissement en boucle
	gs.mode = "descent"; gs.palier = 1; gs.step = 2
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	await _frames(5)
	main = current_scene
	var b = main.boss
	main.boss_started = true
	b.wake()
	b.parried(Vector2.RIGHT)
	var s1: float = b.stun_t
	await _frames(130)
	b.parried(Vector2.RIGHT)
	var s2: float = b.stun_t
	await _frames(330)
	b.parried(Vector2.RIGHT)
	print("boss : 1re parade étourdi %.2f s, 2e (1 s après) %.2f s, 3e (après immunité) %.2f s" % [s1, s2, b.stun_t])
	quit()

extends SceneTree
# Teste les attaques du joueur (combo, coup final, tourbillon, estoc, sort d'âme)
# et les nouveaux ennemis (bulbe, tisseuse, lancier, spectre). --shots : captures.
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _press(a: String) -> void:
	Input.action_press(a)
func _release(a: String) -> void:
	Input.action_release(a)
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _target(main, script, offset: Vector2):
	var e := CharacterBody2D.new()
	e.set_script(script)
	e.main = main
	e.position = main.player.global_position + offset
	main.add_child(e)
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	paused = false
	await _frames(5)
	var main = current_scene
	var pl = main.player
	for e in get_nodes_in_group("enemies"):
		e.queue_free()
	await _frames(2)
	pl.facing = 1
	pl.can_dash = true
	pl.global_position = Vector2(40 * 32, 16 * 32)
	await _frames(20)
	var dummy = _target(main, main.CrawlerScript, Vector2(46, 0))
	await _frames(2)
	dummy.hp = 999
	dummy.set_physics_process(false)
	var kinds := []
	var dmg := []
	for i in 3:
		pl.global_position.x = dummy.global_position.x - 46.0
		var hp0: int = dummy.hp
		_press("attack"); await _frames(2); _release("attack")
		kinds.append(pl.attack_kind)
		await _frames(48)
		dmg.append(hp0 - dummy.hp)
	print("combo : ", kinds, " dégâts ", dmg)
	await _frames(40)
	pl.global_position.x = dummy.global_position.x - 46.0
	var hp1: int = dummy.hp
	_press("attack"); await _frames(2)
	await _frames(int(0.9 * 120))
	_release("attack"); await _frames(3)
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/spin.png")
	print("coup chargé : ", pl.attack_kind, " dégâts ", hp1 - dummy.hp)
	await _frames(40)
	pl.global_position.x = dummy.global_position.x - 170.0
	await _frames(5)
	var hp2: int = dummy.hp
	_press("dash"); await _frames(3); _release("dash")
	_press("attack"); await _frames(2); _release("attack")
	var k2: String = pl.attack_kind
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/thrust.png")
	await _frames(30)
	print("estoc : ", k2, " dégâts ", hp2 - dummy.hp)
	pl.global_position.x = dummy.global_position.x - 220.0
	pl.facing = 1
	pl.soul = 99
	await _frames(5)
	var hp3: int = dummy.hp
	_press("spell"); await _frames(2); _release("spell")
	await _frames(14)
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/spell.png")
	await _frames(46)
	print("sort d'âme : âme ", pl.soul, " (coûte 33) dégâts ", hp3 - dummy.hp)
	dummy.queue_free()
	# --- nouveaux ennemis ---
	var mobs := {"bulbe": [main.BomberScript, Vector2(200, 0)], "tisseuse": [main.WeaverScript, Vector2(260, -60)],
		"lancier": [main.LancerScript, Vector2(240, 0)], "spectre": [main.WraithScript, Vector2(220, -80)]}
	var seen := {}
	var made := {}
	for n in mobs:
		made[n] = _target(main, mobs[n][0], mobs[n][1])
		seen[n] = {}
	var hits := 0
	var shot := false
	for f in 900:
		pl.hp = pl.max_hp
		if f == 400 and is_instance_valid(made["tisseuse"]):
			pl.global_position.x = made["tisseuse"].global_position.x
		if pl.invuln_t <= 0.0 and f > 0:
			pass
		for n in made:
			var e = made[n]
			if is_instance_valid(e):
				if "state" in e:
					seen[n][e.state] = true
				if n == "tisseuse":
					seen[n]["accrochée" if e.hanging else "au sol"] = true
				if n == "bulbe" and e.fuse >= 0.0:
					seen[n]["mèche"] = true
			else:
				seen[n]["explosé/détruit"] = true
		if shots and not shot and f == 430:
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png("/tmp/mobs.png")
			shot = true
		await physics_frame
	for n in seen:
		print(n, " : ", seen[n].keys())
	print("TEST ATTAQUES/ENNEMIS TERMINÉ")
	quit()

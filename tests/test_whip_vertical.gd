extends SceneTree
# Fouet : les coups vers le haut et vers le bas touchent bien (et se dessinent en liane)
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	gs.prog["weapons_owned"] = ["fouet"]
	gs.prog["weapon"] = "fouet"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	var pl = main.player
	pl.sitting = false
	var ok := true
	print("weapon=", pl.wid())
	# vers le haut
	var e := CharacterBody2D.new()
	e.set_script(main.FlyerScript)
	e.main = main
	e.position = pl.global_position + Vector2(0, -80)
	main.add_child(e)
	await _f(3)
	e.stun_t = 5.0
	e.global_position = pl.global_position + Vector2(0, -80)
	var hp0: int = e.hp
	pl._start_attack("slash", Vector2.UP)
	await _f(3)
	await process_frame
	get_root().get_texture().get_image().save_png("/tmp/whip_up.png")
	await _f(8)
	print("up: hp ", hp0, " -> ", e.hp if is_instance_valid(e) else -1)
	if is_instance_valid(e) and e.hp >= hp0 and not e.dead: ok = false
	if is_instance_valid(e): e.queue_free()
	await _f(30)
	# vers le bas, en l'air
	pl.global_position += Vector2(0, -150)
	pl.velocity = Vector2.ZERO
	var e2 := CharacterBody2D.new()
	e2.set_script(main.FlyerScript)
	e2.main = main
	e2.position = pl.global_position + Vector2(0, 70)
	main.add_child(e2)
	await _f(2)
	e2.stun_t = 5.0
	e2.global_position = pl.global_position + Vector2(0, 70)
	var hp1: int = e2.hp
	pl.attack_cd = 0.0
	pl._start_attack("slash", Vector2.DOWN)
	await _f(3)
	await process_frame
	get_root().get_texture().get_image().save_png("/tmp/whip_down.png")
	await _f(6)
	print("down: hp ", hp1, " -> ", e2.hp if is_instance_valid(e2) else -1, " pogo vy=", pl.velocity.y)
	if is_instance_valid(e2) and e2.hp >= hp1 and not e2.dead: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

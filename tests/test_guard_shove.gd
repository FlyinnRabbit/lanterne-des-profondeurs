extends SceneTree
# Garde : de près, coup de bouclier préparé qui blesse et projette ; une parade l'étourdit.
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
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(20)
	var main = current_scene
	var pl = main.player
	pl.sitting = false
	var ok := true
	var e := CharacterBody2D.new()
	e.set_script(main.GuardScript)
	e.main = main
	e.position = pl.global_position + Vector2(120, -4)
	main.add_child(e)
	var hp0: int = pl.hp
	var wound := false
	var x0: float = pl.global_position.x
	var hit := false
	var maxpush := 0.0
	for i in 200:
		await physics_frame
		if e.windup_t > 0.0: wound = true
		if pl.hp < hp0 and not hit:
			hit = true
			x0 = pl.global_position.x
		if hit: maxpush = maxf(maxpush, absf(pl.global_position.x - x0))
		if hit and absf(pl.global_position.x - x0) < maxpush - 1.0: break
	print("windup=", wound, " hit=", hit, " pushed=", maxpush)
	if not (wound and hit and maxpush > 85): ok = false
	# parade : étourdit
	await _f(90)
	pl.global_position = e.global_position + Vector2(-e.facing * -50, 0)
	e.shove_cd = 0.0
	for i in 120:
		await physics_frame
		if e.windup_t > 0.0 and e.windup_t < 0.08:
			pl.parry_t = pl.parry_window()
		if e.stun_t > 0.5: break
	print("stun after parry=", e.stun_t)
	if e.stun_t <= 0.5: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

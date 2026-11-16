extends SceneTree
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	await _frames(5)
	var main = current_scene
	var pl = main.player
	pl.global_position = Vector2(20 * 32, 16 * 32)
	await _frames(10)
	for elite in [false, true]:
		var f := CharacterBody2D.new()
		f.set_script(main.FlyerScript)
		f.main = main
		f.elite = elite
		f.position = pl.global_position + Vector2(120, -20)
		main.add_child(f)
		await _frames(40)
		if elite:
			f.dive_windup = 0.3   # en pleine préparation de piqué
		pl.parry_perfect_now = false
		f.parried(Vector2.RIGHT)
		var p0: Vector2 = f.global_position
		await _frames(30)
		print("volant%s paré : étourdi %.2f s, inoffensif %s, piqué annulé %s, a bougé de %d px" % [" élite" if elite else "", f.stun_t, not f.is_harmful(), f.dive_windup <= 0.0 and f.dive_t <= 0.0, int(f.global_position.distance_to(p0))])
		await _frames(120)
		print("   1 s plus tard : étourdi %s, dangereux de nouveau %s" % [f.stun_t > 0.0, f.is_harmful()])
		f.queue_free()
	quit()

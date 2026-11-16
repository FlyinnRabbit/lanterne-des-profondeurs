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
	gs.prog["owned"] = [6, 9]
	gs.prog["notches"] = 6
	gs.prog["equipped"] = [9]
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	Engine.time_scale = 1.0
	await _frames(5)
	var main = current_scene
	var pl = main.player
	pl.apply_equipment()
	pl.global_position = Vector2(20 * 32, 16 * 32)
	await _frames(20)
	pl.soul = 0
	pl.combat_t = 99.0
	Input.action_press("down")
	await _frames(120 * 10)
	print("Repos, 10 s accroupi hors combat : âme %d (plafond 33)" % pl.soul)
	pl.combat_t = 0.0
	pl.soul = 0
	await _frames(120 * 2)
	print("Repos, en combat : âme %d (attendu 0)" % pl.soul)
	print("temps de soin : repos %.3f" % pl.focus_time())
	gs.prog["equipped"] = [6, 9]
	print("temps de soin : les deux accroupi %.3f" % pl.focus_time())
	Input.action_release("down")
	await _frames(10)
	print("temps de soin : Concentration Vive debout %.3f" % pl.focus_time())
	# soin accroupi : l'état suit la touche
	pl.soul = 99
	pl.hp = 2
	Input.action_press("focus")
	await _frames(5)
	print("soin debout : accroupi=%s" % pl.crouching)
	Input.action_press("down")
	await _frames(5)
	print("soin + bas : accroupi=%s" % pl.crouching)
	Input.action_release("down")
	Input.action_release("focus")
	await _frames(5)
	quit()

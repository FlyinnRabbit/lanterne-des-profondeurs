extends SceneTree
# La Reine Essaim invoque des ouvrières (volants dessinés en abeilles) ; les volants ordinaires
# restent des moucherons.
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
	var main = current_scene
	await _f(10)
	var q := CharacterBody2D.new()
	q.set_script(load("res://scripts/boss_queen.gd"))
	q.main = main
	q.position = main.player.global_position + Vector2(250, -120)
	main.add_child(q)
	await _f(2)
	q.state = "windup_summon"
	q.state_t = 0.01
	await _f(5)
	var bees := 0
	var others := 0
	for m in main.minions:
		if is_instance_valid(m):
			if m.bee: bees += 1
			else: others += 1
	print("ouvrières invoquées : ", bees, " ; volants ordinaires : ", others)
	print("RÉSULTAT : ", "OK" if bees >= 2 and others == 0 else "ÉCHEC")
	quit()

extends SceneTree
# Rampant : repère le héros devant lui, se ramasse puis charge ; ne charge pas à travers un mur.
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
	for el in [false, true]:
		var e := CharacterBody2D.new()
		e.set_script(main.CrawlerScript)
		e.main = main
		e.elite = el
		e.position = pl.global_position + Vector2(160, -4)
		e.dir = -1
		main.add_child(e)
		var wound := false
		var charged := false
		var lunges := 0
		var was := false
		for i in 150:
			await physics_frame
			pl.invuln_t = 1.0
			if e.windup_t > 0.0: wound = true
			if e.lunge_t > 0.0:
				charged = true
				if not was: lunges += 1
			was = e.lunge_t > 0.0
		print("elite=", el, " windup=", wound, " charged=", charged, " lunges=", lunges)
		if not (wound and charged): ok = false
		if el and lunges < 2: ok = false
		e.queue_free()
		await _f(5)
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

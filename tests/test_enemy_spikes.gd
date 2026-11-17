extends SceneTree
# Un ennemi posé sur les pics d'une fosse est blessé (2 dégâts, puis toutes les 0,5 s).
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	gs.run_seed = 4242
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(5)
	var main = current_scene
	var ok := true
	if main.spikes.is_empty():
		print("no spikes in level"); ok = false
	else:
		var sp: Rect2 = main.spikes[0]
		var e := CharacterBody2D.new()
		e.set_script(main.GuardScript)
		e.main = main
		e.position = Vector2(sp.get_center().x, sp.position.y - 30)
		main.add_child(e)
		await _f(30)
		var hp_idle: int = e.hp
		print("guard idle on spikes hp ", hp_idle, " (expected 4: les ennemis connaissent les pics)")
		if hp_idle < 4: ok = false
		var hp0: int = e.hp
		e.hit_ms = Time.get_ticks_msec()   # le héros vient de le frapper
		await _f(30)
		var hp1: int = e.hp if is_instance_valid(e) else -99
		print("guard on spikes hp ", hp0, " -> ", hp1, " dead=", (not is_instance_valid(e)) or e.dead)
		if is_instance_valid(e) and not e.dead and hp1 >= hp0: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

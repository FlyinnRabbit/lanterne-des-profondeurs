extends SceneTree
# Volant : quand une plateforme le sépare du héros, il en fait le tour au lieu de buter dessous.
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
	var T: float = main.TILE
	var row := ""
	for x in range(10, 22):
		row += "#" if main.solid.has(Vector2i(x, 10)) else "."
	print("row10 cols10-21: ", row)
	var ok := true
	var e := CharacterBody2D.new()
	e.set_script(main.FlyerScript)
	e.main = main
	e.position = Vector2(15.5 * T, 8.5 * T)
	main.add_child(e)
	pl.global_position = Vector2(15.5 * T, 16 * T - 20)
	var reached := false
	for i in 360:
		await physics_frame
		pl.global_position = Vector2(15.5 * T, 16 * T - 20)
		pl.velocity = Vector2.ZERO
		pl.invuln_t = 1.0
		if i % 40 == 0: print("  t=", i, " flyer ", e.global_position.round())
		if e.global_position.y > 11 * T and e.global_position.distance_to(pl.global_position) < 60.0:
			reached = true
			break
	print("reached under platform=", reached)
	if not reached: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

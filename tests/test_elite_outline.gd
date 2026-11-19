extends SceneTree
# Élites : placés dans un CanvasGroup (contour rouge), toujours ennemis actifs, et le groupe
# disparaît avec eux.
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
	await _f(20)
	var pl = main.player
	var ok := true
	var e := CharacterBody2D.new()
	e.set_script(load("res://scripts/crawler.gd"))
	e.main = main
	e.elite = true
	e.position = pl.global_position + Vector2(200, 0)
	main.add_child(e)
	await _f(3)
	var cg = e.get_parent()
	print("dans un CanvasGroup : ", cg is CanvasGroup, " ; ennemi actif : ", e.is_in_group("enemies"))
	if not (cg is CanvasGroup and e.is_in_group("enemies")): ok = false
	await _f(30)
	print("toujours au sol, bouge : ", e.is_on_floor())
	e.take_hit(999, Vector2.RIGHT)
	await _f(5)
	print("groupe libéré après la mort : ", not is_instance_valid(cg))
	if is_instance_valid(cg): ok = false
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

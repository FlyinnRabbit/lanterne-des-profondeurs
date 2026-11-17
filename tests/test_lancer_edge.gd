extends SceneTree
# Lancier au bord d'une plateforme : sa fente ne l'emporte pas dans le vide.
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
	var e := CharacterBody2D.new()
	e.set_script(main.LancerScript)
	e.main = main
	# plateforme du hub : cases 13 à 18 de la ligne 10 ; lancier près du bord droit
	e.position = Vector2(18.3 * T, 10 * T - 21)
	main.add_child(e)
	var ok := true
	var thrusts := 0
	var was := false
	for i in 300:
		await physics_frame
		# héros en l'air, à droite, à portée : le lancier veut frapper vers le vide
		pl.global_position = Vector2(e.global_position.x + 80, 10 * T - 20)
		pl.velocity = Vector2.ZERO
		pl.invuln_t = 1.0
		if e.state == "thrust" and not was: thrusts += 1
		was = e.state == "thrust"
	print("thrusts=", thrusts, " lancer y=", e.global_position.y, " x=", e.global_position.x)
	if thrusts < 1 or e.global_position.y > 10 * T or e.global_position.x > 19 * T - 6: ok = false
	print("RESULT ", "OK" if ok else "FAIL")
	quit()

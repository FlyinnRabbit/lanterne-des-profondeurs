extends SceneTree
# Mode « une seule vie » : mourir en descente efface la sauvegarde et affiche l'écran de fin.
# En mode normal, la mort ramène au Sanctuaire et la sauvegarde reste.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await physics_frame
func _die_once(gs, single: bool) -> Dictionary:
	gs.new_game(true, 1, 3, single)
	await process_frame
	await process_frame
	gs.mode = "descent"
	gs.palier = 1
	gs.step = 1
	gs.save_game()
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	await _f(10)
	var main = current_scene
	main.player.take_damage(99, main.player.global_position.x - 10)
	# attendre la fin de l'animation de chute (plus long quand la machine est chargée)
	for i in 900:
		await process_frame
		if current_scene and current_scene.get("menu") and (current_scene.menu.game_over or gs.mode == "hub"):
			break
	await process_frame
	var m = current_scene.menu
	return {"exists": gs.slot_exists(3), "over": m.game_over, "title_btn": m.title_row.visible, "mode": gs.mode}
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	var a: Dictionary = await _die_once(gs, true)
	print("une seule vie : ", a)
	paused = false
	var b: Dictionary = await _die_once(gs, false)
	print("normal : ", b)
	var ok: bool = (not a["exists"]) and a["over"] and a["title_btn"] and b["exists"] and not b["over"] and b["mode"] == "hub"
	gs.delete_slot(3)
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

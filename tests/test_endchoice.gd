extends SceneTree
func _initialize() -> void:
	_run()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _ending(gs):
	gs.mode = "descent"; gs.palier = 7; gs.step = 2
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	await _frames(6)
	var main = current_scene
	main.play_ending(gs.boss_for(7))
	await _frames(2)
	var e = main.get_children()[-1]
	e.t = e.TOTAL - 0.05
	await _frames(4)
	return e
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.new_game(true, 1, 3) if false else null
	gs.slot = 3
	gs.unlocked = 7
	gs.record = 6
	var e = await _ending(gs)
	print("choix affiché : ", e.choice != null)
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/end_choice.png")
	e._continue()
	await _frames(8)
	print("continuer -> mode %s, record %d, débloqué %d, titre %s" % [gs.mode, gs.record, gs.unlocked, current_scene.menu.title_mode])
	e = await _ending(gs)
	e._end_game()
	await _frames(8)
	print("terminer -> mode %s, écran titre %s, résumé : %s" % [gs.mode, current_scene.menu.title_mode, gs.save_summary(3)])
	quit()

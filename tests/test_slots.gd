extends SceneTree
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	for s in [1, 2, 3]:
		gs.delete_slot(s)
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await _frames(6)
	gs.new_game(true, 0, 1)        # facile dans l'emplacement 1
	await _frames(6)
	current_scene.player.geo = 321
	gs.prog["geo"] = 321
	gs.save_game()
	gs.new_game(true, 3, 2)        # cauchemar dans l'emplacement 2
	await _frames(6)
	print("emplacement 1 : ", gs.save_summary(1))
	print("emplacement 2 : ", gs.save_summary(2))
	print("emplacement 3 existe : ", gs.slot_exists(3))
	gs.continue_game(1)
	await _frames(6)
	print("continuer 1 -> difficulté %s, éclats %d, emplacement actif %d" % [gs.diff_name(), current_scene.player.geo, gs.slot])
	gs.continue_game(2)
	await _frames(6)
	print("continuer 2 -> difficulté %s, éclats %d, dernier emplacement %d" % [gs.diff_name(), current_scene.player.geo, root.get_node("Settings").last_slot])
	gs.show_title = true
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await _frames(8)
	var menu = current_scene.menu
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/slots_title.png")
	menu._open_slots()
	await _frames(4)
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/slots_panel.png")
	gs.delete_slot(1)
	print("après suppression : emplacement 1 existe ", gs.slot_exists(1), ", continuer -> ", gs.continue_slot())
	quit()

extends SceneTree
# Captures de l'écran titre : arrivée du menu, puis menu installé (avec une sauvegarde).
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await process_frame
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	var args := OS.get_cmdline_user_args()
	var lang: String = args[0] if args.size() > 0 else "fr"
	st.set_value("language", ["", "fr", "en", "es", "de"].find(lang))
	# une partie sauvegardée pour avoir « Continuer »
	gs.new_game(true, 2, 2, false)
	await _f(3)
	gs.show_title = true
	gs.mode = "tutorial"
	change_scene_to_file("res://main.tscn")
	await _f(4)
	for c in root.get_children():
		if c.get_script() and String(c.get_script().resource_path).ends_with("loading.gd"):
			c.queue_free()
	await _f(12)
	root.get_viewport().get_texture().get_image().save_png("/tmp/menu/title_intro_%s.png" % lang)
	await _f(70)
	root.get_viewport().get_texture().get_image().save_png("/tmp/menu/title_%s.png" % lang)
	for k in 2:
		var ev := InputEventKey.new()
		ev.keycode = KEY_DOWN
		ev.physical_keycode = KEY_DOWN
		ev.pressed = true
		Input.parse_input_event(ev)
		await _f(2)
		ev = ev.duplicate()
		ev.pressed = false
		Input.parse_input_event(ev)
		await _f(4)
	await _f(20)
	var mn = current_scene.menu
	print("focus : ", mn.get_viewport().gui_get_focus_owner().text if mn.get_viewport().gui_get_focus_owner() else "aucun")
	mn._open_options()
	await _f(10)
	root.get_viewport().get_texture().get_image().save_png("/tmp/menu/title_opts_%s.png" % lang)
	root.get_viewport().get_texture().get_image().save_png("/tmp/menu/title_sel_%s.png" % lang)
	gs.delete_slot(2)
	quit()

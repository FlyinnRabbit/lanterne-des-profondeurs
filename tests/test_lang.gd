extends SceneTree
# Langues : traductions et captures du menu titre / options / sanctuaire. --shots : captures.
var shots := false
func _initialize() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	_run()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _shot(n: String) -> void:
	if shots:
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png("/tmp/%s.png" % n)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var st = root.get_node("Settings")
	var old: int = st.language
	for i in [2, 3, 4, 1]:
		st.set_value("language", i)
		var code: String = root.get_node("Lang").current()
		print(code, " : ", TranslationServer.translate("Nouvelle partie"), " | ", gs.diff_name(), " | ", root.get_node("Controls").device_label())
		gs.show_title = true
		gs.mode = "hub"
		change_scene_to_file("res://main.tscn")
		await process_frame   # le changement de scène est différé
		await process_frame
		await _frames(8)
		var main = current_scene
		await _shot("lang_title_" + code)
		main.menu._open_options()
		await _frames(4)
		await _shot("lang_options_" + code)
		main.menu.close()
		main.menu.title_mode = false
		paused = false
		await _frames(30)
		main.show_message("Bon retour au Sanctuaire.", 5.0)
		main.player.global_position = Vector2(12 * 32, 16 * 32)
		await _frames(20)
		await _shot("lang_hub_" + code)
		main.hub_ui.open_arsenal()
		await _frames(4)
		await _shot("lang_arsenal_" + code)
		main.hub_ui.close_all()
	st.set_value("language", old)
	quit()

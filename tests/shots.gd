extends SceneTree
# Captures d'écran de contrôle (icônes de boutons, logo, menus)
func _initialize() -> void:
	_run()
func _wait(n := 6) -> void:
	for i in n:
		await process_frame
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png("/tmp/shot_%s.png" % name)
	print("capture ", name)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	var c = root.get_node("Controls")
	var st = root.get_node("Settings")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://save.cfg"))
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	await _wait(10)
	await _shot("titre")
	gs.show_title = false
	gs.mode = "hub"
	gs.pending_message = "Emblème obtenu : Cape Rapide\nÉquipe-le depuis l'inventaire ({inventory|1}) en te reposant sur un banc."
	change_scene_to_file("res://main.tscn")
	await process_frame   # le changement de scène est différé
	await process_frame
	paused = false
	await _wait(10)
	var main = current_scene
	main.hud.t = 0.0
	main.player.global_position = main.signs[0][0].position + Vector2(0, -20)
	await _wait(8)
	await _shot("hub_clavier")
	c.using_pad = true
	st.pad_style = 1
	await _wait(4)
	await _shot("hub_xbox")
	st.pad_style = 2
	await _wait(4)
	await _shot("hub_ps")
	main.menu.open()
	main.menu._open_controls()
	await _wait(6)
	await _shot("commandes_ps")
	st.pad_style = 1
	main.menu._refresh()
	await _wait(4)
	await _shot("commandes_xbox")
	main.menu.close()
	c.using_pad = false
	main.hub_ui.open_shop()
	await _wait(6)
	await _shot("marchand")
	quit()

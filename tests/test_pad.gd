extends SceneTree
# Vérifie qu'on peut naviguer et valider les menus avec une manette (A / croix / B)
func _initialize() -> void:
	_run()
func _btn(i: int, pressed: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	e.pressed = pressed
	e.device = 0
	Input.parse_input_event(e)
func _tap(i: int) -> void:
	_btn(i, true)
	await process_frame
	await process_frame
	_btn(i, false)
	await process_frame
	await process_frame
func _run() -> void:
	await process_frame
	for f in ["save.cfg", "save_1.cfg", "save_2.cfg", "save_3.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://" + f))
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	var m = main.menu
	print("titre visible : ", m.title_panel.get_parent().visible, " focus : ", root.gui_get_focus_owner().text if root.gui_get_focus_owner() else "aucun")
	await _tap(JOY_BUTTON_A)     # Jouer
	print("après A -> parties visible : ", m.slots_panel.get_parent().visible, " focus : ", root.gui_get_focus_owner().text)
	await _tap(JOY_BUTTON_B)     # retour
	print("après B -> titre visible : ", m.title_panel.get_parent().visible)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	await _tap(JOY_BUTTON_DPAD_DOWN)
	print("croix bas x2 -> focus : ", root.gui_get_focus_owner().text)
	await _tap(JOY_BUTTON_A)     # Options
	print("après A -> options visible : ", m.options_panel.get_parent().visible)
	await _tap(JOY_BUTTON_B)
	await _tap(JOY_BUTTON_DPAD_UP)
	await _tap(JOY_BUTTON_DPAD_UP)
	await _tap(JOY_BUTTON_A)     # Jouer -> parties
	await _tap(JOY_BUTTON_A)     # emplacement 1 (vide) -> difficulté
	await _tap(JOY_BUTTON_A)     # Normal (difficulté actuelle) -> lance la partie
	await process_frame
	await process_frame
	print("partie lancée : ", not paused, " mode ", root.get_node("GameState").mode)
	quit()

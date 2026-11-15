extends SceneTree
# Vérifie les noms de commandes affichés selon le périphérique et le style de manette
func _initialize() -> void:
	_run()
func _run() -> void:
	await process_frame
	var c = root.get_node("Controls")
	var s = root.get_node("Settings")
	var gs = root.get_node("GameState")
	gs.show_title = false
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	var k := InputEventKey.new()
	k.physical_keycode = KEY_D
	k.pressed = true
	Input.parse_input_event(k)
	await process_frame
	print("[", c.device_label(), "] ", main.fmt("{attack} frapper, {dash} ruée, {parry} parade, {pause} pause"))
	var j := InputEventJoypadButton.new()
	j.button_index = JOY_BUTTON_A
	j.pressed = true
	Input.parse_input_event(j)
	await process_frame
	print("[", c.device_label(), "] ", main.fmt("{attack} frapper, {dash} ruée, {parry} parade, {pause} pause"))
	s.set_value("pad_style", 2)
	print("[", c.device_label(), "] ", main.fmt("{attack} frapper, {dash} ruée, {parry} parade, {focus} soin, {pause} pause"))
	print("détection : ", c.detect_kind("PS5 Controller"), " ", c.detect_kind("DualSense Wireless Controller"), " ", c.detect_kind("XInput Gamepad (GLFW)"))
	s.set_value("fps_cap", 3)
	print("max_fps = ", Engine.max_fps)
	s.set_value("fps_cap", 6)
	print("max_fps (illimité) = ", Engine.max_fps)
	s.reset_defaults()
	main.menu.open()
	main.menu._open_options()
	main.menu._open_controls()
	print("en-tête manette : ", main.menu.pad_header.text)
	quit()

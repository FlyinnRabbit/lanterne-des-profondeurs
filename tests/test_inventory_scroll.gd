extends SceneTree
# Inventaire : la molette fait défiler la grille d'une rangée par cran, le stick droit aussi,
# et le stick gauche maintenu fait avancer la sélection jusqu'en bas.
func _initialize() -> void:
	_run()
func _wheel(pos: Vector2, down: bool) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_WHEEL_DOWN if down else MOUSE_BUTTON_WHEEL_UP
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		e.factor = 1.0
		Input.parse_input_event(e)
func _axis(axis: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = v
	Input.parse_input_event(e)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await process_frame
	await process_frame
	paused = false
	for i in 10:
		await physics_frame
	var main = current_scene
	main.player.sitting = true
	main.inventory.open()
	for i in 5:
		await process_frame
	var inv = main.inventory
	var g: ScrollContainer = inv.grid_scroll
	var pos: Vector2 = g.get_global_transform_with_canvas() * (g.size / 2.0)
	var ok := true
	var seq := []
	for k in 2:
		_wheel(pos, true)
		for i in 4:
			await process_frame
		seq.append(g.scroll_vertical)
	_wheel(pos, false)
	for i in 4:
		await process_frame
	seq.append(g.scroll_vertical)
	print("molette bas, bas, haut : ", seq)
	ok = ok and seq == [inv.ROW_PITCH, 2 * inv.ROW_PITCH, inv.ROW_PITCH]
	# stick droit
	g.scroll_vertical = 0
	for i in 3:
		await process_frame
	_axis(JOY_AXIS_RIGHT_Y, 1.0)
	for i in 3:
		await process_frame
	_axis(JOY_AXIS_RIGHT_Y, 0.0)
	for i in 3:
		await process_frame
	print("stick droit : ", g.scroll_vertical)
	ok = ok and g.scroll_vertical == inv.ROW_PITCH
	# stick gauche maintenu
	g.scroll_vertical = 0
	inv.slots[0].grab_focus()
	for i in 3:
		await process_frame
	_axis(JOY_AXIS_LEFT_Y, 1.0)
	# la répétition dépend du temps de jeu : on attend qu'elle arrive en bas (machine lente)
	var f := 0
	for i in 600:
		await process_frame
		f = inv.slots.find(root.get_viewport().gui_get_focus_owner())
		if f >= 21:
			break
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	print("stick gauche maintenu : case ", f, ", défilement ", g.scroll_vertical)
	ok = ok and f >= 21 and g.scroll_vertical > 0 and g.scroll_vertical % inv.ROW_PITCH == 0
	print("RÉSULTAT : ", "OK" if ok else "ÉCHEC")
	quit()

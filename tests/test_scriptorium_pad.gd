extends SceneTree
# Scriptorium à la manette : LB / RB changent d'onglet (gauche / droite aussi sur les pages sans grille),
# le stick parcourt directement la grille, B ferme.
func _initialize() -> void:
	_run()
func _f(n):
	for i in n:
		await process_frame
func _axis(ax: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = ax
	e.axis_value = v
	e.device = 0
	Input.parse_input_event(e)
func _btn(i: int, p: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	e.pressed = p
	e.device = 0
	Input.parse_input_event(e)
func _stick(ax: int, v: float) -> void:
	_axis(ax, v)
	await _f(3)
	_axis(ax, 0.0)
	await _f(3)
func _tap(i: int) -> void:
	_btn(i, true)
	await _f(3)
	_btn(i, false)
	await _f(3)
func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.show_title = false
	gs.mode = "hub"
	change_scene_to_file("res://main.tscn")
	await _f(3)
	paused = false
	var sc = current_scene.scriptorium
	sc.open()
	await _f(15)
	await _tap(JOY_BUTTON_RIGHT_SHOULDER)
	var p0: int = sc.page
	await _stick(JOY_AXIS_LEFT_X, 1.0)        # page sans grille : droite = onglet suivant
	var p1: int = sc.page
	var g1: bool = sc.focus_grid
	await _stick(JOY_AXIS_LEFT_X, 1.0)        # page en grille : droite = case suivante
	var s1: int = sc.sel
	await _tap(JOY_BUTTON_LEFT_SHOULDER)
	var p2: int = sc.page
	await _tap(JOY_BUTTON_B)
	var closed: bool = not sc.visible
	print("RB -> page %d (attendu 1), droite -> page %d (attendu 2), grille %s, sélection %d (attendu 1), LB -> page %d (attendu 1), fermé %s" % [p0, p1, g1, s1, p2, closed])
	print("RÉSULTAT : ", "OK" if p0 == 1 and p1 == 2 and g1 and s1 == 1 and p2 == 1 and closed else "ÉCHEC")
	quit()

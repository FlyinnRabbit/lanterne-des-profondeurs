extends CanvasLayer
# Carte du niveau (touche Carte) : cases déjà vues, banc, sortie, ombre, objets, joueur.
# main.explored garde les cases découvertes (la Plume du cartographe révèle tout).
var main
var view: Control

func _ready() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_map)
	add_child(view)
	visible = false

func toggle() -> void:
	if visible:
		visible = false
		get_tree().paused = false
	elif not get_tree().paused:
		visible = true
		get_tree().paused = true
		view.queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		if main.menu.visible or (main.inventory and main.inventory.visible) or main.hub_ui.visible:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and (event.is_action_pressed("pause_menu") or event.is_action_pressed("inventory") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)):
		toggle()
		get_viewport().set_input_as_handled()

static func cell_color(ch: String, pal: Dictionary) -> Color:
	match ch:
		"#": return Color(0.55, 0.6, 0.75)
		"^": return Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.9, 0.3, 0.25)
		"C": return Color(0.65, 0.5, 0.4)
		"H": return Color(0.5, 0.75, 0.9)
	return Color(0, 0, 0, 0)

func _draw_map() -> void:
	var sz := view.size
	var font := ThemeDB.fallback_font
	view.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.03, 0.88))
	var title := tr("Carte") + " — " + tr(main.level["name"])
	view.draw_string(font, Vector2(0, 50), title, HORIZONTAL_ALIGNMENT_CENTER, sz.x, 28, Color(1.0, 0.88, 0.6))
	var ms: Vector2i = main.map_size
	var area := Vector2(sz.x - 80.0, sz.y - 170.0)
	var c := floorf(minf(area.x / ms.x, area.y / ms.y))
	c = maxf(c, 2.0)
	var origin := Vector2((sz.x - ms.x * c) / 2.0, 80.0 + (area.y - ms.y * c) / 2.0)
	draw_cells(view, main, origin, c, Rect2i(Vector2i.ZERO, ms))
	draw_markers(view, main, origin, c, Rect2i(Vector2i.ZERO, ms), true)
	Glyphs.draw_rich(view, font, 0, sz.x, sz.y - 30, "{map|1} / {pause|1} : fermer", 16, Color(0.75, 0.8, 0.9))

# Cases (utilisé aussi par la mini-carte du HUD)
static func draw_cells(ci: CanvasItem, m, origin: Vector2, c: float, r: Rect2i) -> void:
	for y in range(maxi(r.position.y, 0), mini(r.end.y, m.map_size.y)):
		var row: String = m.MAP[y]
		for x in range(maxi(r.position.x, 0), mini(r.end.x, m.map_size.x)):
			if not m.is_explored(x, y):
				continue
			var p := origin + Vector2(x - r.position.x, y - r.position.y) * c
			var ch: String = row[x] if x < row.length() else "."
			var col := cell_color(ch, m.pal)
			if col.a > 0.0:
				ci.draw_rect(Rect2(p, Vector2(c, c)), col)
			else:
				ci.draw_rect(Rect2(p, Vector2(c, c)), Color(0.12, 0.14, 0.22, 0.55))

static func draw_markers(ci: CanvasItem, m, origin: Vector2, c: float, r: Rect2i, big: bool) -> void:
	var T: float = m.TILE
	var rs := 5.0 if big else 3.0
	var off := Vector2(r.position) * c
	var _pt := func(world: Vector2) -> Vector2:
		return origin + world / T * c - off
	var inside := func(world: Vector2) -> bool:
		var cell := Vector2i(floori(world.x / T), floori(world.y / T))
		return r.has_point(cell) and m.is_explored(cell.x, cell.y)
	for b in m.benches:
		if inside.call(b):
			ci.draw_rect(Rect2(_pt.call(b) - Vector2(rs, rs * 0.6), Vector2(rs * 2, rs * 1.2)), Color(1.0, 0.8, 0.45))
	if m.exit_door and is_instance_valid(m.exit_door) and inside.call(m.exit_door.position):
		ci.draw_circle(_pt.call(m.exit_door.position + Vector2(0, -16)), rs + 1.0, Color(0.6, 0.85, 1.0))
	if m.shrine and is_instance_valid(m.shrine) and inside.call(m.shrine.position):
		ci.draw_circle(_pt.call(m.shrine.position + Vector2(0, -16)), rs + 1.0, Color(1.0, 0.85, 0.55))
	if m.shade_node and is_instance_valid(m.shade_node) and not m.shade_node.dead:
		ci.draw_circle(_pt.call(m.shade_node.global_position), rs + 1.0, Color(0.65, 0.45, 1.0))
	for pk in m.pickups:
		if is_instance_valid(pk[0]) and inside.call(pk[0].position):
			ci.draw_colored_polygon(DUtil.diamond(_pt.call(pk[0].position), Vector2(rs, rs * 1.3)), Color(1.0, 0.92, 0.6))
	for it in m.interactables:
		if is_instance_valid(it[0]) and inside.call(it[0].position):
			ci.draw_circle(_pt.call(it[0].position + Vector2(0, -16)), rs, Color(0.9, 0.7, 1.0))
	if m.boss and is_instance_valid(m.boss) and not m.boss_dead and inside.call(m.boss.global_position):
		ci.draw_circle(_pt.call(m.boss.global_position), rs + 3.0, Color(1.0, 0.35, 0.3))
	var pp: Vector2 = m.player.global_position
	var blink := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 150.0)
	ci.draw_circle(_pt.call(pp), rs + 1.5, Color(1, 1, 1, blink))
	ci.draw_circle(_pt.call(pp), rs - 1.0, Color(0.3, 0.6, 1.0))

const Glyphs = preload("res://scripts/glyphs.gd")
const DUtil = preload("res://scripts/draw_util.gd")

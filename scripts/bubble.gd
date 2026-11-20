extends Node2D
# Bulle de dialogue au-dessus d'un habitant du Sanctuaire : apparaît, reste lisible, s'efface.

var text := ""
var t := 0.0
const LIFE := 4.5

func _ready() -> void:
	z_index = 60

func _process(delta: float) -> void:
	t += delta
	if t > LIFE:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var f := ThemeDB.fallback_font
	var fs := 13
	var w := minf(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x, 230.0)
	var lines := []
	var line := ""
	for word in text.split(" "):
		var test := word if line == "" else line + " " + word
		if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 230.0 and line != "":
			lines.append(line)
			line = word
		else:
			line = test
	lines.append(line)
	var a := clampf(t / 0.2, 0.0, 1.0) * clampf((LIFE - t) / 0.5, 0.0, 1.0)
	var h := lines.size() * 17.0 + 12.0
	var lift := -6.0 * (1.0 - clampf(t / 0.2, 0.0, 1.0))
	var r := Rect2(Vector2(-w / 2.0 - 10, -h + lift), Vector2(w + 20, h))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.92, 0.82, 0.93 * a)
	sb.border_color = Color(0.45, 0.33, 0.2, a)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	draw_style_box(sb, r)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, lift - 1), Vector2(7, lift - 1), Vector2(0, lift + 9)]), Color(0.96, 0.92, 0.82, 0.93 * a))
	for i in lines.size():
		draw_string(f, Vector2(-w / 2.0, -h + lift + 18 + i * 17.0), lines[i], HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(0.2, 0.14, 0.1, a))

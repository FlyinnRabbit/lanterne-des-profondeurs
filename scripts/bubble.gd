extends Node2D
# Bulle de dialogue au-dessus d'un habitant du Sanctuaire : apparaît, reste lisible, s'efface.
# La découpe en lignes est calculée une seule fois ; chaque image ne redessine que la boîte.

var text := ""
var t := 0.0
const LIFE := 4.5
var life := LIFE          # raccourcie quand un message du jeu s'affiche (la bulle se tait)
var _lines := []
var _w := 0.0
var _sb: StyleBoxFlat

func _ready() -> void:
	z_index = 60
	var f := ThemeDB.fallback_font
	var line := ""
	for word in text.split(" "):
		var test := word if line == "" else line + " " + word
		if f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x > 230.0 and line != "":
			_lines.append(line)
			line = word
		else:
			line = test
	_lines.append(line)
	_w = minf(f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, 230.0)
	_sb = StyleBoxFlat.new()
	_sb.set_border_width_all(2)
	_sb.set_corner_radius_all(8)

func _process(delta: float) -> void:
	t += delta
	if t > LIFE:
		queue_free()
		return
	if t < 0.25 or t > life - 0.55 or t > LIFE - 0.55:
		queue_redraw()        # seulement pendant l'apparition et l'effacement

func _alpha() -> float:
	return clampf(t / 0.2, 0.0, 1.0) * clampf((minf(life, LIFE) - t) / 0.5, 0.0, 1.0)

func _draw() -> void:
	var f := ThemeDB.fallback_font
	var fs := 13
	var w := _w
	var a := _alpha()
	if t > life:
		queue_free()
		return
	var h := _lines.size() * 17.0 + 12.0
	var lift := -6.0 * (1.0 - clampf(t / 0.2, 0.0, 1.0))
	var r := Rect2(Vector2(-w / 2.0 - 10, -h + lift), Vector2(w + 20, h))
	_sb.bg_color = Color(0.96, 0.92, 0.82, 0.93 * a)
	_sb.border_color = Color(0.45, 0.33, 0.2, a)
	draw_style_box(_sb, r)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, lift - 1), Vector2(7, lift - 1), Vector2(0, lift + 9)]), Color(0.96, 0.92, 0.82, 0.93 * a))
	for i in _lines.size():
		draw_string(f, Vector2(-w / 2.0, -h + lift + 18 + i * 17.0), _lines[i], HORIZONTAL_ALIGNMENT_CENTER, w, fs, Color(0.2, 0.14, 0.1, a))

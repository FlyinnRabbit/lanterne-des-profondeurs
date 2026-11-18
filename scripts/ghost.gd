extends Node2D
# Fantôme : silhouette translucide qui rejoue le parcours du premier du classement
# (Descente du jour, Défi de la semaine). Il ne touche rien et ne gêne pas.

var frames: Array = []       # [Vector2, facing]
var who := ""
var t := 0.0
var done := false

func setup(data: String, name: String) -> void:
	who = name
	z_index = 5
	for part in data.split(";", false):
		var v := part.split(",")
		if v.size() >= 3:
			frames.append([Vector2(float(v[0]), float(v[1])), 1.0 if v[2] == "1" else -1.0])
	if not frames.is_empty():
		position = frames[0][0]

func at(time: float) -> void:
	if frames.is_empty():
		return
	t = time
	var f := time * 10.0
	var i := int(f)
	if i >= frames.size() - 1:
		position = frames[frames.size() - 1][0]
		done = true
	else:
		var k := f - i
		position = (frames[i][0] as Vector2).lerp(frames[i + 1][0], k)
		scale.x = frames[i][1]
	queue_redraw()

func _draw() -> void:
	if frames.is_empty():
		return
	var a := 0.32 if not done else 0.32 * clampf(1.0 - (t - frames.size() / 10.0) * 0.5, 0.0, 1.0)
	if a <= 0.01:
		return
	var c := Color(0.6, 0.85, 1.0, a)
	# capuche et cape, comme le héros, en lumière froide
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 20), Vector2(-8, -8), Vector2(0, -22), Vector2(8, -8), Vector2(10, 20)]), c)
	draw_circle(Vector2(3, -8), 5.0, Color(0.05, 0.08, 0.15, a))
	draw_circle(Vector2(4, -8), 2.0, Color(0.9, 1.0, 1.0, a * 2.0))
	for k in 3:
		draw_circle(Vector2(0, 0), 18.0 + k * 6.0, Color(0.6, 0.85, 1.0, a * 0.08))
	if who != "":
		var f := ThemeDB.fallback_font
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))
		draw_string(f, Vector2(-60, -32), who, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(0.75, 0.9, 1.0, a * 2.2))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

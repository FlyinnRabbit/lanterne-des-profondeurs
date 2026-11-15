extends Node2D
# Annonce d'attaque : un « ! » au-dessus d'un ennemi qui prépare un coup.
#  jaune  : attaque normale (parade possible)
#  orange avec flèche vers le bas : attaque haute, on peut s'accroupir dessous
var k := 0.0
var kind := 0

func _ready() -> void:
	z_index = 21
	z_as_relative = false

func _process(delta: float) -> void:
	var e = get_parent()
	if not is_instance_valid(e) or not e.has_method("telegraph"):
		return
	var t: int = e.telegraph() if Settings.telegraphs else 0
	if t > 0:
		kind = t
		k = minf(k + delta * 10.0, 1.0)
	else:
		k = maxf(k - delta * 6.0, 0.0)
	visible = k > 0.0
	position = Vector2(0, -e.size.y / 2.0 - 30.0)
	queue_redraw()

func _draw() -> void:
	var s := 0.6 + 0.4 * k
	var col := Color(1.0, 0.85, 0.3, k) if kind == 1 else Color(1.0, 0.5, 0.2, k)
	if Settings.colorblind:
		col = Color(1.0, 1.0, 1.0, k)
	draw_circle(Vector2.ZERO, 11.0 * s, Color(0.05, 0.03, 0.05, 0.75 * k))
	draw_arc(Vector2.ZERO, 11.0 * s, 0.0, TAU, 20, col, 2.0)
	draw_line(Vector2(0, -6) * s, Vector2(0, 2) * s, col, 3.0)
	draw_circle(Vector2(0, 6) * s, 1.8 * s, col)
	if kind == 2:
		# flèche vers le bas : s'accroupir
		draw_colored_polygon(PackedVector2Array([Vector2(14, -2) * s, Vector2(24, -2) * s, Vector2(19, 6) * s]), col)

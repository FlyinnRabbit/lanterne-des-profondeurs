extends StaticBody2D
# Grille d'arène : bloque le passage quand elle est fermée.

var rect := Rect2()
var start_closed := false
var closed := false
var openness := 0.0   # 0 = fermée, 1 = ouverte (animée)
var cs: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var s := RectangleShape2D.new()
	s.size = rect.size
	cs = CollisionShape2D.new()
	cs.shape = s
	cs.position = rect.get_center()
	add_child(cs)
	set_closed(start_closed)
	openness = 0.0 if closed else 1.0

func set_closed(v: bool) -> void:
	closed = v
	cs.set_deferred("disabled", not v)

func _process(delta: float) -> void:
	openness = move_toward(openness, 0.0 if closed else 1.0, delta * 3.0)
	queue_redraw()

func _draw() -> void:
	var h := rect.size.y * (1.0 - openness)
	if h <= 1.0:
		return
	var bars := 3
	for i in bars:
		var x := rect.position.x + 2.0 + i * (rect.size.x - 4.0) / (bars - 1)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + h), Color(0.55, 0.58, 0.68), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, rect.position.y + h - 6), Vector2(x + 4, rect.position.y + h - 6), Vector2(x, rect.position.y + h + 4)]), Color(0.7, 0.72, 0.82))
	for j in int(h / 48.0):
		var y := rect.position.y + 24.0 + j * 48.0
		draw_line(Vector2(rect.position.x - 2, y), Vector2(rect.end.x + 2, y), Color(0.4, 0.42, 0.52), 3.0)

extends StaticBody2D
const DU = preload("res://scripts/draw_util.gd")
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
	# herse de fer forgé : barreaux ronds, traverses rivetées, pointes
	var iron := Color(0.36, 0.38, 0.46)
	var bars := 3
	for j in int(h / 48.0):
		var y := rect.position.y + 24.0 + j * 48.0
		DU.box(self, Rect2(rect.position.x - 3, y - 3, rect.size.x + 6, 6), iron.darkened(0.15))
		for i in bars:
			var x := rect.position.x + 2.0 + i * (rect.size.x - 4.0) / (bars - 1)
			draw_circle(Vector2(x, y), 1.6, iron.lightened(0.3))
	for i in bars:
		var x := rect.position.x + 2.0 + i * (rect.size.x - 4.0) / (bars - 1)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + h), iron.darkened(0.5), 4.6)
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + h), iron, 3.0)
		draw_line(Vector2(x - 0.8, rect.position.y), Vector2(x - 0.8, rect.position.y + h), DU.lit(iron, 1.7, 0.08), 1.0)
		DU.poly(self, PackedVector2Array([Vector2(x - 4.5, rect.position.y + h - 6), Vector2(x + 4.5, rect.position.y + h - 6), Vector2(x, rect.position.y + h + 6)]), iron.lightened(0.15))

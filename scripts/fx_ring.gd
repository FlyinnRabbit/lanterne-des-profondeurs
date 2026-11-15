extends Node2D
# Onde de choc de l'ultime.

var radius := 260.0
var t := 0.0
const DURATION := 0.5

func _ready() -> void:
	z_index = 5

func _process(delta: float) -> void:
	t += delta
	if t >= DURATION:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := t / DURATION
	var r := radius * ease(k, 0.4)
	draw_circle(Vector2.ZERO, r, Color(1.0, 0.9, 0.6, 0.18 * (1.0 - k)))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1.0, 0.95, 0.75, 1.0 - k), 10.0 * (1.0 - k) + 2.0)
	draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 48, Color(0.7, 0.9, 1.0, 0.7 * (1.0 - k)), 4.0)

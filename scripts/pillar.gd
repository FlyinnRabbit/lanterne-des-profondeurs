extends Node2D
# Pilier d'énergie qui jaillit du sol après un avertissement (Chevalier Spectral, Colosse).
# Phase 1 : une lueur clignote au sol (on a le temps de s'écarter) ; phase 2 : colonne dangereuse.

var main
var warn := 0.7
var active := 0.45
var height := 170.0
var width := 34.0
var color := Color(0.55, 0.85, 1.0)
var t := 0.0
var hit_done := false
var style := ""      # "" colonne d'énergie, "tentacle" tentacule (Œil d'en Dessous), "fire" flammes (Cerbère)

func _ready() -> void:
	z_index = 3

func get_rect() -> Rect2:
	return Rect2(global_position + Vector2(-width / 2.0, -height), Vector2(width, height))

func _physics_process(delta: float) -> void:
	t += delta
	if t > warn + active:
		queue_free()
		return
	if t >= warn and not hit_done:
		var p = main.player
		if not p.dead and p.dash_t <= 0.0 and get_rect().intersects(p.get_rect()):
			hit_done = true
			p.receive_hit(global_position, self)
		if t - delta < warn:
			main.shake(3)
			main.spawn_burst(global_position, color, 10, 220.0, -100.0)
	queue_redraw()

func _draw() -> void:
	if t < warn:
		var k := t / warn
		var blink := 0.35 + 0.35 * absf(sin(t * 18.0))
		draw_rect(Rect2(-width / 2.0, -6, width, 6), Color(color, blink))
		draw_circle(Vector2(0, -3), width * (0.4 + 0.6 * k), Color(color, 0.15 * k))
	else:
		var k := 1.0 - (t - warn) / active
		var h := height * minf((t - warn) / 0.08, 1.0)
		if style == "tentacle":
			var pts := PackedVector2Array()
			var n := 10
			for i in n + 1:
				var u := float(i) / n
				var sway := sin(t * 9.0 + u * 5.0) * 10.0 * u
				pts.append(Vector2(-width / 2.0 * (1.0 - u * 0.8) + sway, -h * u))
			for i in range(n, -1, -1):
				var u := float(i) / n
				var sway := sin(t * 9.0 + u * 5.0) * 10.0 * u
				pts.append(Vector2(width / 2.0 * (1.0 - u * 0.8) + sway, -h * u))
			draw_colored_polygon(pts, Color(color.darkened(0.3), 0.95))
			for i in 4:
				var u := 0.2 + i * 0.2
				draw_circle(Vector2(sin(t * 9.0 + u * 5.0) * 10.0 * u + 4.0, -h * u), 3.0, Color(1.0, 0.75, 0.9, 0.8))
			return
		if style == "fire":
			for i in 5:
				var fx := -width / 2.0 + i * width / 4.0
				var fh := h * (0.6 + 0.4 * absf(sin(t * 20.0 + i)))
				draw_colored_polygon(PackedVector2Array([Vector2(fx - 8, 0), Vector2(fx + 8, 0), Vector2(fx, -fh)]), Color(1.0, 0.45 + 0.1 * i, 0.15, 0.85 * k))
			return
		draw_rect(Rect2(-width / 2.0, -h, width, h), Color(color, 0.55 * k))
		draw_rect(Rect2(-width / 4.0, -h, width / 2.0, h), Color(1, 1, 1, 0.7 * k))
		draw_circle(Vector2(0, -h), width * 0.6, Color(color, 0.4 * k))

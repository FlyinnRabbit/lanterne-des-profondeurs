extends Node2D
const DU = preload("res://scripts/draw_util.gd")
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
		DU.glow(self, Vector2(0, -3), width * (0.6 + 0.9 * k), color, 0.5 * k)
		draw_rect(Rect2(-width / 2.0, -5, width, 5), Color(color, blink))
		# fissures qui s'ouvrent dans le sol
		for i in 3:
			var x := (i - 1) * width * 0.3
			draw_line(Vector2(x, 0), Vector2(x + (i - 1) * 5.0, -4.0 * k), Color(color.lightened(0.4), blink), 1.4)
		for i in 3:
			var px := fposmod(t * 80.0 + i * 13.0, width) - width / 2.0
			draw_circle(Vector2(px, -4 - fposmod(t * 40.0 + i * 7.0, 14.0)), 1.4, Color(color, blink))
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
			DU.poly(self, pts, color.darkened(0.3))
			for i in 5:
				var u := 0.15 + i * 0.17
				var c := Vector2(sin(t * 9.0 + u * 5.0) * 10.0 * u + width * 0.18 * (1.0 - u), -h * u)
				draw_circle(c, 3.4 * (1.0 - u * 0.5), Color(0.6, 0.3, 0.5))
				draw_circle(c, 2.0 * (1.0 - u * 0.5), Color(1.0, 0.75, 0.9, 0.85))
			return
		if style == "fire":
			DU.glow(self, Vector2(0, -h * 0.3), width * 1.6, Color(1.0, 0.5, 0.15), 0.5 * k)
			for layer in 2:
				for i in 5:
					var fx := -width / 2.0 + i * width / 4.0
					var fh := h * (0.6 + 0.4 * absf(sin(t * 20.0 + i + layer))) * (1.0 - layer * 0.35)
					var c := Color(1.0, 0.4 + 0.1 * i, 0.12, 0.85 * k) if layer == 0 else Color(1.0, 0.85, 0.45, 0.85 * k)
					DU.flat(self, PackedVector2Array([Vector2(fx - 8 + layer * 3, 0), Vector2(fx - 3, -fh * 0.5), Vector2(fx + sin(t * 15.0 + i) * 3.0, -fh), Vector2(fx + 3, -fh * 0.5), Vector2(fx + 8 - layer * 3, 0)]), c)
			return
		# colonne d'énergie : halo, cœur blanc, anneaux qui montent
		DU.glow(self, Vector2(0, -h * 0.5), width * 1.8, color, 0.5 * k)
		DU.vgrad(self, Rect2(-width / 2.0, -h, width, h), Color(color, 0.25 * k), Color(color, 0.7 * k))
		DU.vgrad(self, Rect2(-width / 4.0, -h, width / 2.0, h), Color(1, 1, 1, 0.4 * k), Color(1, 1, 1, 0.85 * k))
		for i in 3:
			var ry := -fposmod(t * 400.0 + i * h / 3.0, h)
			draw_line(Vector2(-width / 2.0, ry), Vector2(width / 2.0, ry), Color(1, 1, 1, 0.5 * k), 2.0)
		DU.glow(self, Vector2(0, -h), width * 0.9, color, 0.7 * k)

extends Node2D
# Onde de choc de l'ultime. Son apparence dépend du cosmétique « ultime » équipé (style).

var radius := 260.0
var t := 0.0
var style := "ult_or"
var c1 := Color(1.0, 0.9, 0.6)
var c2 := Color(0.7, 0.9, 1.0)
const DURATION := 0.5

func _ready() -> void:
	z_index = 5

func _process(delta: float) -> void:
	t += delta
	if t >= DURATION * (1.5 if style in ["ult_etoile", "ult_essaim", "ult_nuee", "ult_coeur", "ult_eclosion"] else 1.0):
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf(t / DURATION, 0.0, 1.0)
	var r := radius * ease(k, 0.4)
	match style:
		"ult_givre":
			# nova de givre : anneau à pointes de cristal
			draw_circle(Vector2.ZERO, r, Color(c1, 0.14 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c1, 1.0 - k), 6.0 * (1.0 - k) + 2.0)
			for i in 16:
				var a := i * TAU / 16.0
				var d := Vector2.from_angle(a)
				var n := Vector2(-d.y, d.x)
				var ln := 46.0 if i % 2 == 0 else 26.0
				draw_colored_polygon(PackedVector2Array([d * (r - 8.0) + n * 7.0, d * (r + ln * (1.0 - k * 0.5)), d * (r - 8.0) - n * 7.0]), Color(c1.lerp(c2, 0.4), 0.9 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r * 0.6, 0.0, TAU, 40, Color(c2, 0.6 * (1.0 - k)), 3.0)
		"ult_brasier":
			# brasier : langues de flammes qui montent le long de l'onde
			draw_circle(Vector2.ZERO, r, Color(c1, 0.16 * (1.0 - k)))
			for i in 28:
				var a := i * TAU / 28.0 + sin(i * 3.1) * 0.08
				var d := Vector2.from_angle(a)
				var h := (30.0 + 26.0 * absf(sin(i * 1.7 + t * 18.0))) * (1.0 - k * 0.6)
				var p := d * r
				draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 4), p + Vector2(0, -h), p + Vector2(8, 4)]), Color(c1, 0.85 * (1.0 - k)))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 4), p + Vector2(0, -h * 0.55), p + Vector2(4, 4)]), Color(c2, 0.9 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c2, 0.8 * (1.0 - k)), 4.0)
		"ult_eclipse":
			# éclipse : disque noir bordé d'une couronne blanche
			draw_circle(Vector2.ZERO, r, Color(c1, 0.75 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c2, 1.0 - k * 0.6), 5.0)
			for i in 24:
				var a := i * TAU / 24.0
				var d := Vector2.from_angle(a)
				draw_line(d * (r + 4.0), d * (r + 20.0 + 26.0 * absf(sin(i * 2.3))), Color(c2, 0.8 * (1.0 - k)), 2.0)
		"ult_essaim":
			# essaim spectral : feux follets qui tournoient vers l'extérieur
			var kk := clampf(t / (DURATION * 1.5), 0.0, 1.0)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c1, 0.7 * (1.0 - k)), 3.0)
			for i in 22:
				var a := i * TAU / 22.0 + kk * 2.6
				var rr := radius * ease(kk, 0.5) * (0.55 + 0.45 * fposmod(i * 0.37, 1.0))
				var p := Vector2.from_angle(a) * rr
				var col := c1 if i % 2 == 0 else c2
				draw_circle(p, 9.0 * (1.0 - kk), Color(col, 0.25 * (1.0 - kk)))
				draw_circle(p, 4.0 * (1.0 - kk) + 1.0, Color(col, 1.0 - kk))
				draw_line(p, Vector2.from_angle(a - 0.25) * rr * 0.92, Color(col, 0.5 * (1.0 - kk)), 2.0)
		"ult_etoile":
			# étoile de Noël : grande étoile à huit branches et pluie de flocons
			var kk2 := clampf(t / (DURATION * 1.5), 0.0, 1.0)
			draw_circle(Vector2.ZERO, r, Color(c1, 0.12 * (1.0 - k)))
			var pts := PackedVector2Array()
			for i in 16:
				var a := i * TAU / 16.0 - PI / 2.0
				pts.append(Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.42))
			pts.append(pts[0])
			draw_polyline(pts, Color(c1, 1.0 - k), 5.0 * (1.0 - k) + 2.0)
			draw_arc(Vector2.ZERO, r * 0.42, 0.0, TAU, 40, Color(c2, 0.7 * (1.0 - k)), 3.0)
			for i in 26:
				var a := i * 2.4
				var p := Vector2.from_angle(a) * radius * (0.2 + 0.8 * fposmod(i * 0.61, 1.0)) + Vector2(0, kk2 * 70.0)
				for j in 3:
					var d := Vector2.from_angle(j * PI / 3.0) * 5.0
					draw_line(p - d, p + d, Color(1, 1, 1, 0.9 * (1.0 - kk2)), 1.2)
		"ult_nuee":
			# nuée de chauves-souris qui s'envole en spirale
			var kb := clampf(t / (DURATION * 1.5), 0.0, 1.0)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c2, 0.8 * (1.0 - k)), 3.0)
			draw_circle(Vector2.ZERO, r, Color(c1, 0.14 * (1.0 - k)))
			for i in 20:
				var a := i * TAU / 20.0 + kb * 1.8
				var p := Vector2.from_angle(a) * radius * ease(kb, 0.5) * (0.5 + 0.5 * fposmod(i * 0.43, 1.0)) + Vector2(0, -kb * 30.0)
				var fl := sin(t * 40.0 + i) * 4.0
				for sgn in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([p, p + Vector2(sgn * 13.0, -5 - fl), p + Vector2(sgn * 9.0, 2), p + Vector2(sgn * 4.0, 4)]), Color(c1.darkened(0.4), 1.0 - kb))
				draw_circle(p, 3.0, Color(c1.darkened(0.5), 1.0 - kb))
		"ult_coeur":
			# coup de foudre : l'onde a la forme d'un cœur, des petits cœurs s'envolent
			var kh := clampf(t / (DURATION * 1.5), 0.0, 1.0)
			var pts := PackedVector2Array()
			for i in 49:
				var a := i * TAU / 48.0
				pts.append(Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * (r / 15.0))
			draw_polyline(pts, Color(c1, 0.35 * (1.0 - k)), 18.0)
			draw_polyline(pts, Color(c2, 1.0 - k), 4.0)
			for i in 14:
				var p := Vector2.from_angle(i * 2.4) * radius * (0.25 + 0.6 * fposmod(i * 0.61, 1.0)) + Vector2(0, -kh * 60.0)
				var s2 := 5.0 * (1.0 - kh) + 2.0
				draw_circle(p + Vector2(-s2 * 0.5, 0), s2 * 0.6, Color(c1, 1.0 - kh))
				draw_circle(p + Vector2(s2 * 0.5, 0), s2 * 0.6, Color(c1, 1.0 - kh))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-s2 * 1.05, s2 * 0.25), p + Vector2(s2 * 1.05, s2 * 0.25), p + Vector2(0, s2 * 1.4)]), Color(c1, 1.0 - kh))
		"ult_eclosion":
			# éclosion : anneaux pastel et éclats de coquille
			var ke := clampf(t / (DURATION * 1.5), 0.0, 1.0)
			var pastel := [c1, c2, Color(1.0, 0.9, 0.5), Color(0.7, 0.9, 1.0)]
			for i in 4:
				draw_arc(Vector2.ZERO, r * (1.0 - i * 0.18), 0.0, TAU, 56, Color(pastel[i], (1.0 - k) * (1.0 - i * 0.15)), 6.0 - i)
			for i in 18:
				var a := i * TAU / 18.0
				var p := Vector2.from_angle(a) * radius * ease(ke, 0.45) * (0.6 + 0.4 * fposmod(i * 0.37, 1.0)) + Vector2(0, ke * ke * 60.0)
				var rot := a + ke * 5.0
				draw_colored_polygon(PackedVector2Array([p + Vector2.from_angle(rot) * 8.0, p + Vector2.from_angle(rot + 2.2) * 6.0, p + Vector2.from_angle(rot + 4.0) * 7.0]), Color(pastel[i % 4].lightened(0.3), 1.0 - ke))
		_:
			draw_circle(Vector2.ZERO, r, Color(c1, 0.18 * (1.0 - k)))
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(c1.lightened(0.3), 1.0 - k), 10.0 * (1.0 - k) + 2.0)
			draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 48, Color(c2, 0.7 * (1.0 - k)), 4.0)

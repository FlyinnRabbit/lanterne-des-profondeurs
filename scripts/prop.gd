extends Node2D
# Éléments du décor interactifs : banc, orbe de pouvoir, sanctuaire final.

const DU = preload("res://scripts/draw_util.gd")

var kind := "bench"
var color := Color(1, 1, 1)
var lit := false

func DU_ellipse_half() -> PackedVector2Array:
	return DU.ellipse(Vector2(0, -80), Vector2(20, 20), 16, PI, TAU)
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	match kind:
		"bench":
			var wood := Color(0.35, 0.28, 0.25)
			var metal := Color(0.5, 0.52, 0.6)
			draw_rect(Rect2(-26, -16, 52, 5), wood)
			draw_rect(Rect2(-26, -30, 52, 4), wood)
			draw_rect(Rect2(-26, -38, 52, 4), wood)
			for x in [-22, 20]:
				draw_line(Vector2(x, -40), Vector2(x, 0), metal, 3.0)
			# petite lanterne
			draw_line(Vector2(0, -40), Vector2(0, -52), metal, 2.0)
			draw_circle(Vector2(0, -56), 5.0 + sin(t * 3.0) * 0.5, Color(1.0, 0.8, 0.45))
			draw_circle(Vector2(0, -56), 11.0, Color(1.0, 0.8, 0.45, 0.2))
		"orb":
			var y := sin(t * 2.0) * 5.0
			draw_circle(Vector2(0, y), 18.0, Color(0.5, 0.85, 1.0, 0.18))
			draw_circle(Vector2(0, y), 10.0, Color(0.6, 0.9, 1.0, 0.9))
			draw_circle(Vector2(0, y), 5.0, Color(1, 1, 1))
			for i in 3:
				var a := t * 2.0 + i * TAU / 3.0
				draw_circle(Vector2(cos(a) * 22.0, y + sin(a) * 8.0), 2.0, Color(0.7, 0.95, 1.0))
		"door":
			# arche de pierre avec un voile lumineux : passage vers le niveau suivant
			var stone := Color(0.28, 0.3, 0.4)
			draw_rect(Rect2(-30, -80, 10, 80), stone)
			draw_rect(Rect2(20, -80, 10, 80), stone)
			draw_arc(Vector2(0, -80), 25.0, PI, TAU, 20, stone, 10.0)
			var a := 0.35 + sin(t * 2.5) * 0.12
			draw_rect(Rect2(-20, -80, 40, 80), Color(0.55, 0.8, 1.0, a))
			draw_colored_polygon(DU_ellipse_half(), Color(0.55, 0.8, 1.0, a))
			for i in 4:
				var y := -fmod(t * 30.0 + i * 20.0, 80.0)
				draw_circle(Vector2(sin(t + i) * 10.0, y), 1.5, Color(0.85, 0.95, 1.0, 0.8))
		"charm":
			var y := sin(t * 2.2) * 4.0
			draw_circle(Vector2(0, y), 18.0, Color(color, 0.15))
			draw_colored_polygon(DU.diamond(Vector2(0, y), Vector2(9, 12)), color)
			draw_colored_polygon(DU.diamond(Vector2(0, y), Vector2(4, 6)), Color(1, 1, 1, 0.8))
			draw_arc(Vector2(0, y), 14.0, t, t + 4.0, 16, Color(color, 0.6), 1.5)
		"notch":
			var y2 := sin(t * 2.0) * 4.0
			draw_circle(Vector2(0, y2), 16.0, Color(1.0, 0.9, 0.6, 0.15))
			draw_arc(Vector2(0, y2), 9.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.6), 3.0)
			draw_circle(Vector2(0, y2), 4.0 + sin(t * 4.0), Color(1.0, 0.95, 0.8))
		"sign":
			var wood := Color(0.38, 0.3, 0.26)
			draw_line(Vector2(0, 0), Vector2(0, -40), wood, 4.0)
			draw_rect(Rect2(-20, -58, 40, 26), wood)
			draw_rect(Rect2(-20, -58, 40, 26), Color(0.55, 0.45, 0.35), false, 2.0)
			var g := 0.9 if lit else 0.45 + sin(t * 3.0) * 0.2
			draw_colored_polygon(DU.diamond(Vector2(0, -45), Vector2(6, 8)), Color(0.6, 0.85, 1.0, g))
			if not lit:
				draw_string(ThemeDB.fallback_font, Vector2(-4, -64 + sin(t * 4.0) * 3.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.9, 0.6))
		"shrine":
			var stone := Color(0.3, 0.32, 0.42)
			draw_rect(Rect2(-40, -10, 80, 10), stone)
			draw_rect(Rect2(-30, -90, 10, 80), stone)
			draw_rect(Rect2(20, -90, 10, 80), stone)
			draw_rect(Rect2(-40, -100, 80, 12), stone)
			# grande lanterne
			var glow := 0.6 + sin(t * 2.0) * 0.15
			draw_line(Vector2(0, -88), Vector2(0, -70), Color(0.5, 0.52, 0.6), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -70), Vector2(10, -70), Vector2(7, -44), Vector2(-7, -44)]), Color(1.0, 0.82, 0.5, glow))
			draw_circle(Vector2(0, -57), 26.0, Color(1.0, 0.85, 0.55, 0.15))

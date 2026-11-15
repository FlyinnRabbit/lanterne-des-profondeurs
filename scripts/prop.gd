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
		"merchant":
			# Marchand : grand papillon de nuit voyageur, cape ronde et sac de babioles
			var bob := sin(t * 1.6) * 1.5
			var cloak := Color(0.32, 0.24, 0.3)
			draw_colored_polygon(DU.ellipse(Vector2(14, -24 + bob), Vector2(14, 16)), Color(0.45, 0.33, 0.22))   # sac
			for i in 3:
				draw_circle(Vector2(8 + i * 6, -34 + bob + (i % 2) * 4), 2.5, [Color(1, 0.8, 0.4), Color(0.6, 0.9, 1), Color(0.9, 0.6, 1)][i])
			draw_colored_polygon(PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(10, -36 + bob), Vector2(-10, -36 + bob)]), cloak)
			draw_colored_polygon(DU.ellipse(Vector2(0, -42 + bob), Vector2(13, 11)), Color(0.85, 0.82, 0.72))      # tête duveteuse
			draw_line(Vector2(-5, -51 + bob), Vector2(-14, -64 + bob + sin(t * 2.0) * 2.0), Color(0.85, 0.82, 0.72), 2.0)
			draw_line(Vector2(5, -51 + bob), Vector2(14, -64 + bob - sin(t * 2.0) * 2.0), Color(0.85, 0.82, 0.72), 2.0)
			draw_circle(Vector2(-5, -42 + bob), 3.0, Color(0.1, 0.05, 0.1))
			draw_circle(Vector2(5, -42 + bob), 3.0, Color(0.1, 0.05, 0.1))
			draw_circle(Vector2(-4, -43 + bob), 1.0, Color(1, 1, 1))
			draw_circle(Vector2(6, -43 + bob), 1.0, Color(1, 1, 1))
			# lanterne tenue
			draw_line(Vector2(-14, -20 + bob), Vector2(-22, -14 + bob), Color(0.5, 0.45, 0.4), 2.0)
			draw_circle(Vector2(-23, -9 + bob), 5.0 + sin(t * 3.0) * 0.6, Color(1.0, 0.8, 0.45))
			draw_circle(Vector2(-23, -9 + bob), 11.0, Color(1.0, 0.8, 0.45, 0.2))
		"cache":
			# coffret de trésor
			var wood := Color(0.45, 0.3, 0.18)
			draw_rect(Rect2(-14, -18, 28, 18), wood)
			draw_colored_polygon(DU.ellipse(Vector2(0, -18), Vector2(14, 7), 12, PI, TAU), wood.lightened(0.1))
			draw_rect(Rect2(-14, -12, 28, 3), Color(0.85, 0.7, 0.3))
			draw_rect(Rect2(-3, -16, 6, 7), Color(0.95, 0.8, 0.35))
			draw_circle(Vector2(0, -12), 18.0 + sin(t * 3.0) * 2.0, Color(1.0, 0.85, 0.4, 0.12))
		"challenge":
			# stèle au sablier : lance le défi chronométré
			var st := Color(0.4, 0.38, 0.42)
			draw_rect(Rect2(-10, -46, 20, 46), st)
			draw_rect(Rect2(-13, -50, 26, 5), st.lightened(0.15))
			var gc := Color(1.0, 0.75, 0.35) if not lit else Color(0.5, 0.5, 0.5)
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -40), Vector2(6, -40), Vector2(0, -28)]), gc)
			draw_colored_polygon(PackedVector2Array([Vector2(-6, -16), Vector2(6, -16), Vector2(0, -28)]), gc)
			if not lit:
				draw_string(ThemeDB.fallback_font, Vector2(-4, -58 + sin(t * 4.0) * 3.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.8, 0.4))
		"flag":
			draw_line(Vector2(0, 0), Vector2(0, -56), Color(0.6, 0.5, 0.4), 3.0)
			var wave := sin(t * 5.0) * 3.0
			var fc := Color(1.0, 0.75, 0.35) if not lit else Color(0.6, 1.0, 0.6)
			draw_colored_polygon(PackedVector2Array([Vector2(1, -56), Vector2(26, -50 + wave), Vector2(1, -40)]), fc)
		"altar":
			var stn := Color(0.35, 0.3, 0.33)
			draw_rect(Rect2(-22, -14, 44, 14), stn)
			draw_rect(Rect2(-16, -34, 32, 20), stn.lightened(0.08))
			var ec := Color(1.0, 0.35, 0.3, 0.9) if not lit else Color(0.4, 0.35, 0.35, 0.8)
			for i in 3:
				draw_circle(Vector2(-10 + i * 10, -24), 3.5 + (sin(t * 4.0 + i) if not lit else 0.0), ec)
			if not lit:
				draw_circle(Vector2(0, -24), 26.0, Color(1.0, 0.3, 0.25, 0.08 + 0.05 * sin(t * 2.0)))
		"smith":
			# forgeronne : grand scarabée au tablier de cuir, marteau à l'épaule
			var bob := sin(t * 1.5) * 1.0
			var shell := Color(0.25, 0.3, 0.42)
			draw_colored_polygon(DU.ellipse(Vector2(0, -24 + bob), Vector2(16, 22)), shell)
			draw_rect(Rect2(-11, -26 + bob, 22, 22), Color(0.45, 0.3, 0.2))
			draw_colored_polygon(DU.ellipse(Vector2(0, -50 + bob), Vector2(11, 10)), shell.lightened(0.15))
			draw_line(Vector2(-4, -58 + bob), Vector2(-9, -72 + bob), shell, 3.0)
			draw_circle(Vector2(-4, -50 + bob), 2.5, Color(1.0, 0.7, 0.3))
			draw_circle(Vector2(4, -50 + bob), 2.5, Color(1.0, 0.7, 0.3))
			draw_line(Vector2(12, -40 + bob), Vector2(22, -64 + bob), Color(0.5, 0.4, 0.3), 3.0)
			draw_rect(Rect2(16, -72 + bob, 14, 9), Color(0.55, 0.55, 0.62))
			# enclume et braises
			draw_colored_polygon(PackedVector2Array([Vector2(-44, 0), Vector2(-24, 0), Vector2(-28, -10), Vector2(-20, -16), Vector2(-48, -16), Vector2(-40, -10)]), Color(0.25, 0.26, 0.32))
			draw_circle(Vector2(-34, -20), 2.0 + sin(t * 7.0), Color(1.0, 0.6, 0.2, 0.8))
		"cartographer":
			# cartographe : petite mite à lunettes et rouleau de carte
			var bob2 := sin(t * 2.0) * 1.5
			var fur := Color(0.75, 0.7, 0.6)
			draw_colored_polygon(DU.ellipse(Vector2(0, -18 + bob2), Vector2(12, 18)), Color(0.35, 0.3, 0.38))
			draw_colored_polygon(DU.ellipse(Vector2(0, -40 + bob2), Vector2(11, 10)), fur)
			draw_arc(Vector2(-4, -40 + bob2), 3.5, 0.0, TAU, 10, Color(0.9, 0.85, 0.5), 1.5)
			draw_arc(Vector2(4, -40 + bob2), 3.5, 0.0, TAU, 10, Color(0.9, 0.85, 0.5), 1.5)
			draw_line(Vector2(-3, -49 + bob2), Vector2(-10, -60 + bob2), fur, 2.0)
			draw_line(Vector2(3, -49 + bob2), Vector2(10, -60 + bob2), fur, 2.0)
			draw_rect(Rect2(8, -26 + bob2, 22, 12), Color(0.9, 0.85, 0.7))
			draw_line(Vector2(12, -22 + bob2), Vector2(26, -18 + bob2), Color(0.5, 0.4, 0.3), 1.0)
		"elder":
			# l'ancien : vieil escargot sous une capuche, lanterne éteinte à ses pieds
			var bob3 := sin(t * 0.8) * 1.0
			draw_colored_polygon(DU.ellipse(Vector2(-6, -18 + bob3), Vector2(20, 18)), Color(0.5, 0.4, 0.32))
			draw_arc(Vector2(-6, -18 + bob3), 10.0, 0.0, TAU * 0.85, 16, Color(0.35, 0.27, 0.22), 3.0)
			draw_colored_polygon(DU.ellipse(Vector2(14, -6), Vector2(16, 6)), Color(0.6, 0.6, 0.55))
			draw_colored_polygon(DU.ellipse(Vector2(20, -30 + bob3), Vector2(8, 12)), Color(0.3, 0.25, 0.35))
			draw_circle(Vector2(22, -30 + bob3), 2.0, Color(1.0, 0.9, 0.6))
			draw_rect(Rect2(-36, -14, 10, 14), Color(0.3, 0.3, 0.35))
			draw_circle(Vector2(-31, -8), 3.0, Color(0.4, 0.35, 0.3))
		"arsenal":
			# Arsenal : râtelier de bois avec les armes exposées et une enclume
			var wood := Color(0.36, 0.27, 0.22)
			draw_rect(Rect2(-34, -70, 68, 6), wood)
			draw_rect(Rect2(-34, -40, 68, 5), wood)
			draw_line(Vector2(-32, 0), Vector2(-32, -70), wood, 4.0)
			draw_line(Vector2(32, 0), Vector2(32, -70), wood, 4.0)
			draw_line(Vector2(-22, -64), Vector2(-14, -8), Color(0.8, 0.82, 0.9), 2.0)          # aiguille
			draw_arc(Vector2(-4, -54), 7.0, 0.0, TAU, 14, Color(0.5, 0.75, 0.4), 2.5)           # fouet enroulé
			draw_line(Vector2(-4, -47), Vector2(-2, -20), Color(0.5, 0.7, 0.4), 2.0)
			draw_line(Vector2(12, -64), Vector2(12, -12), Color(0.5, 0.4, 0.3), 3.0)             # marteau
			draw_rect(Rect2(5, -70, 14, 10), Color(0.55, 0.55, 0.62))
			for i in 4:                                                                          # étoile
				var a3 := i * PI / 2.0 + t
				draw_colored_polygon(PackedVector2Array([Vector2(25, -52), Vector2(25, -52) + Vector2.from_angle(a3 - 0.4) * 3.0, Vector2(25, -52) + Vector2.from_angle(a3) * 7.0]), Color(0.8, 0.85, 0.95))
			draw_colored_polygon(PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(12, -10), Vector2(22, -16), Vector2(-22, -16), Vector2(-12, -10)]), Color(0.25, 0.26, 0.32))
			draw_circle(Vector2(0, -26), 3.0 + sin(t * 3.0), Color(1.0, 0.7, 0.35, 0.8))
		"elevator":
			# Ascenseur : cage de fer suspendue à des chaînes, panneau lumineux
			var iron := Color(0.4, 0.42, 0.5)
			var cage := Rect2(-26, -78, 52, 78)
			draw_rect(cage, Color(0.08, 0.09, 0.13, 0.85))
			draw_rect(cage, iron, false, 3.0)
			for i in 5:
				var x := -26.0 + i * 13.0
				draw_line(Vector2(x, -78), Vector2(x, 0), Color(iron, 0.7), 2.0)
			draw_line(Vector2(-26, -40), Vector2(26, -40), Color(iron, 0.7), 2.0)
			for cx in [-16.0, 16.0]:
				var y := -78.0
				while y > -300.0:
					draw_arc(Vector2(cx, y - 6), 4.0, 0.0, TAU, 8, Color(0.35, 0.36, 0.42), 2.0)
					y -= 12.0
			# rouage
			var g := Vector2(0, -92)
			draw_circle(g, 10.0, Color(0.3, 0.31, 0.38))
			for i in 8:
				var a2 := t * 0.8 + i * TAU / 8.0
				draw_line(g, g + Vector2(cos(a2), sin(a2)) * 14.0, Color(0.45, 0.46, 0.55), 3.0)
			# panneau
			var glow := 0.6 + sin(t * 2.5) * 0.25
			draw_rect(Rect2(30, -44, 12, 18), Color(0.2, 0.22, 0.3))
			draw_circle(Vector2(36, -35), 3.5, Color(0.6, 0.9, 1.0, glow))
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

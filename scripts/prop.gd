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
			# Forgeronne : scarabée trapu au tablier de cuir, devant sa forge de pierre et son enclume
			var bob := sin(t * 1.5) * 1.0
			var shell := Color(0.25, 0.3, 0.42)
			var stone2 := Color(0.32, 0.3, 0.3)
			# forge : foyer de pierre, braises, cheminée et soufflet
			draw_rect(Rect2(-92, -40, 46, 40), stone2)
			draw_rect(Rect2(-86, -110, 22, 70), stone2.darkened(0.15))
			draw_rect(Rect2(-88, -32, 38, 18), Color(0.1, 0.05, 0.03))
			var ember := 0.6 + 0.4 * sin(t * 6.0)
			for i in 5:
				draw_circle(Vector2(-82 + i * 7, -20), 3.0 + ember, Color(1.0, 0.45 + 0.08 * i, 0.15, 0.9))
			draw_circle(Vector2(-69, -24), 26.0, Color(1.0, 0.5, 0.2, 0.12 * ember))
			for i in 3:
				var sy := -110.0 - fmod(t * 30.0 + i * 20.0, 60.0)
				draw_circle(Vector2(-75 + sin(t * 2.0 + i) * 4.0, sy), 4.0 + i, Color(0.4, 0.4, 0.42, 0.25))
			draw_colored_polygon(PackedVector2Array([Vector2(-46, -22), Vector2(-28, -30 - absf(sin(t * 2.0)) * 6.0), Vector2(-28, -14)]), Color(0.5, 0.35, 0.22))
			# enclume
			draw_colored_polygon(PackedVector2Array([Vector2(26, 0), Vector2(50, 0), Vector2(46, -10), Vector2(56, -18), Vector2(20, -18), Vector2(30, -10)]), Color(0.25, 0.26, 0.32))
			draw_line(Vector2(56, -18), Vector2(66, -15), Color(0.25, 0.26, 0.32), 4.0)
			draw_rect(Rect2(32, -24, 16, 5), Color(1.0, 0.55, 0.25))   # lame rougie
			# râtelier d'outils
			draw_line(Vector2(70, -70), Vector2(100, -70), Color(0.42, 0.3, 0.2), 4.0)
			for i in 3:
				draw_line(Vector2(76 + i * 10, -70), Vector2(76 + i * 10, -44), Color(0.55, 0.55, 0.6), 2.0)
			# la forgeronne
			draw_colored_polygon(DU.ellipse(Vector2(0, -24 + bob), Vector2(17, 23)), shell)
			draw_rect(Rect2(-12, -28 + bob, 24, 26), Color(0.45, 0.3, 0.2))
			draw_colored_polygon(DU.ellipse(Vector2(0, -52 + bob), Vector2(12, 11)), shell.lightened(0.15))
			draw_line(Vector2(-4, -60 + bob), Vector2(-10, -76 + bob), shell, 3.0)
			draw_line(Vector2(4, -60 + bob), Vector2(10, -76 + bob), shell, 3.0)
			draw_circle(Vector2(-4, -52 + bob), 2.5, Color(1.0, 0.7, 0.3))
			draw_circle(Vector2(4, -52 + bob), 2.5, Color(1.0, 0.7, 0.3))
			# marteau qui frappe l'enclume
			var swing := absf(sin(t * 2.4))
			var hand := Vector2(14, -38 + bob)
			var head := hand + Vector2(10 + 8 * swing, -28 + 30 * swing)
			draw_line(hand, head, Color(0.5, 0.4, 0.3), 3.0)
			draw_rect(Rect2(head - Vector2(7, 5), Vector2(14, 10)), Color(0.55, 0.55, 0.62))
			if swing > 0.97:
				for i in 4:
					draw_line(Vector2(40, -24), Vector2(40, -24) + Vector2.from_angle(-PI / 2 + (i - 1.5) * 0.5) * 12.0, Color(1.0, 0.8, 0.4), 1.5)
		"cartographer":
			# Cartographe : mite à lunettes devant sa table à cartes, globe, rouleaux et lanterne
			var bob2 := sin(t * 2.0) * 1.5
			var fur := Color(0.75, 0.7, 0.6)
			var wood := Color(0.42, 0.3, 0.2)
			# étagère de rouleaux
			draw_rect(Rect2(-96, -96, 44, 96), wood.darkened(0.25))
			for r in 3:
				draw_rect(Rect2(-96, -92 + r * 30, 44, 4), wood)
				for k in 4:
					draw_circle(Vector2(-88 + k * 10, -80 + r * 30), 4.0, Color(0.9, 0.85, 0.7))
					draw_circle(Vector2(-88 + k * 10, -80 + r * 30), 1.5, Color(0.6, 0.5, 0.35))
			# globe sur pied
			draw_line(Vector2(-36, 0), Vector2(-36, -30), wood, 3.0)
			draw_circle(Vector2(-36, -42), 13.0, Color(0.35, 0.55, 0.7))
			draw_arc(Vector2(-36, -42), 13.0, 0.0, TAU, 20, Color(0.7, 0.6, 0.35), 2.0)
			draw_colored_polygon(DU.ellipse(Vector2(-36 + sin(t * 0.8) * 5.0, -44), Vector2(5, 7)), Color(0.45, 0.65, 0.4))
			# table à cartes avec carte déroulée et compas
			draw_rect(Rect2(14, -30, 70, 6), wood)
			draw_line(Vector2(20, -24), Vector2(20, 0), wood.darkened(0.2), 4.0)
			draw_line(Vector2(78, -24), Vector2(78, 0), wood.darkened(0.2), 4.0)
			draw_colored_polygon(PackedVector2Array([Vector2(18, -32), Vector2(80, -32), Vector2(76, -40), Vector2(22, -40)]), Color(0.92, 0.86, 0.68))
			draw_polyline(PackedVector2Array([Vector2(28, -35), Vector2(40, -37), Vector2(52, -34), Vector2(66, -38)]), Color(0.6, 0.3, 0.25), 1.5)
			draw_line(Vector2(56, -40), Vector2(62, -50), Color(0.6, 0.6, 0.65), 1.5)
			draw_line(Vector2(62, -50), Vector2(68, -40), Color(0.6, 0.6, 0.65), 1.5)
			draw_circle(Vector2(84, -48), 4.0 + sin(t * 3.0) * 0.5, Color(1.0, 0.8, 0.45))   # bougie
			draw_line(Vector2(84, -44), Vector2(84, -32), Color(0.95, 0.92, 0.85), 3.0)
			# le cartographe, plume à la main
			draw_colored_polygon(DU.ellipse(Vector2(0, -18 + bob2), Vector2(12, 18)), Color(0.35, 0.3, 0.38))
			draw_colored_polygon(DU.ellipse(Vector2(0, -40 + bob2), Vector2(11, 10)), fur)
			draw_arc(Vector2(-4, -40 + bob2), 3.5, 0.0, TAU, 10, Color(0.9, 0.85, 0.5), 1.5)
			draw_arc(Vector2(4, -40 + bob2), 3.5, 0.0, TAU, 10, Color(0.9, 0.85, 0.5), 1.5)
			draw_line(Vector2(-3, -49 + bob2), Vector2(-10, -60 + bob2), fur, 2.0)
			draw_line(Vector2(3, -49 + bob2), Vector2(10, -60 + bob2), fur, 2.0)
			var qx := 16.0 + sin(t * 4.0) * 3.0
			draw_line(Vector2(8, -26 + bob2), Vector2(qx, -38), Color(0.95, 0.95, 0.9), 2.0)   # plume
			draw_colored_polygon(PackedVector2Array([Vector2(qx, -38), Vector2(qx + 6, -50), Vector2(qx + 2, -38)]), Color(0.95, 0.95, 0.9))
		"elder":
			# L'ancien : vieil escargot encapuchonné, assis près d'un petit autel de bougies
			# et d'une vieille lanterne éteinte (celle qu'il a portée autrefois)
			var bob3 := sin(t * 0.8) * 1.0
			var stone3 := Color(0.33, 0.31, 0.34)
			# autel de pierre et bougies
			draw_rect(Rect2(-80, -26, 40, 26), stone3)
			draw_rect(Rect2(-84, -30, 48, 6), stone3.lightened(0.12))
			for i in 3:
				var bx := -74.0 + i * 13.0
				var bh := 10.0 + (i % 2) * 6.0
				draw_rect(Rect2(bx, -30 - bh, 5, bh), Color(0.92, 0.88, 0.78))
				var fl := 1.0 + 0.3 * sin(t * 9.0 + i * 2.0)
				draw_colored_polygon(DU.ellipse(Vector2(bx + 2.5, -34 - bh), Vector2(2.2, 4.0 * fl)), Color(1.0, 0.75, 0.3))
				draw_circle(Vector2(bx + 2.5, -34 - bh), 9.0, Color(1.0, 0.75, 0.3, 0.12))
			# tapis
			draw_colored_polygon(DU.ellipse(Vector2(4, 0), Vector2(40, 5)), Color(0.45, 0.2, 0.22))
			# coquille spiralée
			var sc := Vector2(-6, -22 + bob3)
			draw_colored_polygon(DU.ellipse(sc, Vector2(21, 19)), Color(0.5, 0.4, 0.32))
			for k in 3:
				draw_arc(sc + Vector2(k * 2.0, 0), 15.0 - k * 5.0, 0.4 * k, TAU * 0.85 + 0.4 * k, 18, Color(0.35, 0.27, 0.22), 2.5)
			# corps et capuche
			draw_colored_polygon(DU.ellipse(Vector2(16, -6), Vector2(18, 6)), Color(0.6, 0.6, 0.55))
			draw_colored_polygon(PackedVector2Array([Vector2(10, -6), Vector2(32, -6), Vector2(28, -40 + bob3), Vector2(14, -40 + bob3)]), Color(0.28, 0.24, 0.34))
			draw_colored_polygon(DU.ellipse(Vector2(21, -40 + bob3), Vector2(10, 11)), Color(0.28, 0.24, 0.34))
			draw_colored_polygon(DU.ellipse(Vector2(23, -38 + bob3), Vector2(5, 6)), Color(0.08, 0.06, 0.1))
			draw_circle(Vector2(25, -39 + bob3), 1.6, Color(1.0, 0.9, 0.6))
			# barbe de mousse et canne
			draw_colored_polygon(PackedVector2Array([Vector2(19, -33 + bob3), Vector2(27, -33 + bob3), Vector2(23, -22 + bob3)]), Color(0.55, 0.65, 0.45))
			draw_line(Vector2(36, 0), Vector2(32, -50), Color(0.4, 0.3, 0.2), 3.0)
			draw_circle(Vector2(32, -52), 3.0, Color(0.4, 0.3, 0.2))
			# vieille lanterne éteinte à ses pieds
			var lc := Vector2(50, 0)
			draw_colored_polygon(PackedVector2Array([lc + Vector2(-8, -18), lc + Vector2(8, -18), lc + Vector2(0, -26)]), Color(0.3, 0.3, 0.35))
			draw_rect(Rect2(lc + Vector2(-7, -18), Vector2(14, 16)), Color(0.12, 0.1, 0.12))
			for i in 3:
				draw_line(lc + Vector2(-7 + i * 7, -18), lc + Vector2(-7 + i * 7, -2), Color(0.3, 0.3, 0.35), 1.5)
			draw_rect(Rect2(lc + Vector2(-9, -3), Vector2(18, 3)), Color(0.3, 0.3, 0.35))
			# fumée d'encens
			for i in 3:
				var sy2 := -46.0 - fmod(t * 14.0 + i * 15.0, 45.0)
				draw_circle(Vector2(-62 + sin(t + i) * 5.0, sy2), 3.0 + i, Color(0.7, 0.7, 0.75, 0.15))
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
			# Monte-charge de bois : cabine à claire-voie, cordes, grande roue de treuil et levier
			var wood := Color(0.42, 0.3, 0.2)
			var dark := Color(0.24, 0.16, 0.11)
			var rope := Color(0.72, 0.62, 0.42)
			var bob2 := sin(t * 1.2) * 1.0
			# portique de poutres
			draw_rect(Rect2(-44, -150, 9, 150), dark)
			draw_rect(Rect2(35, -150, 9, 150), dark)
			draw_rect(Rect2(-50, -160, 100, 12), wood)
			draw_line(Vector2(-35, -148), Vector2(-14, -126), dark, 4.0)
			draw_line(Vector2(35, -148), Vector2(14, -126), dark, 4.0)
			# roue de treuil (tourne lentement)
			var g := Vector2(0, -176)
			draw_arc(g, 22.0, 0.0, TAU, 28, wood, 5.0)
			draw_arc(g, 14.0, 0.0, TAU, 20, dark, 2.0)
			for i in 6:
				var a2 := t * 0.6 + i * TAU / 6.0
				draw_line(g, g + Vector2(cos(a2), sin(a2)) * 22.0, wood, 3.0)
				draw_circle(g + Vector2(cos(a2), sin(a2)) * 26.0, 3.0, dark)   # poignées
			draw_circle(g, 5.0, Color(0.55, 0.5, 0.42))
			# cordes jusqu'à la cabine (et plus haut, vers la surface)
			for cx in [-18.0, 18.0]:
				draw_line(Vector2(cx, -400), Vector2(cx, -82 + bob2), rope, 2.0)
				for k in 12:
					var ky := -400.0 + k * 26.0
					draw_line(Vector2(cx - 2, ky), Vector2(cx + 2, ky + 6), rope.darkened(0.3), 1.0)
			# cabine à claire-voie
			var cab := Rect2(-30, -82 + bob2, 60, 82)
			draw_rect(cab, Color(0.1, 0.07, 0.05, 0.75))
			draw_rect(Rect2(-32, -84 + bob2, 64, 8), wood)
			draw_rect(Rect2(-32, -6, 64, 8), wood)
			for i in 5:
				draw_line(Vector2(-28 + i * 14, -78 + bob2), Vector2(-28 + i * 14, -6), wood.darkened(0.1), 3.0)
			draw_line(Vector2(-30, -78 + bob2), Vector2(30, -8), dark, 3.0)          # croisillon
			draw_line(Vector2(30, -78 + bob2), Vector2(-30, -8), dark, 3.0)
			draw_circle(Vector2(0, -50), 5.0 + sin(t * 3.0) * 0.6, Color(1.0, 0.8, 0.45))   # lanterne dans la cabine
			draw_circle(Vector2(0, -50), 14.0, Color(1.0, 0.8, 0.45, 0.18))
			# levier de bois (au lieu d'un bouton)
			var lv := Vector2(52, 0)
			draw_rect(Rect2(lv.x - 8, -12, 16, 12), dark)
			var ang := -0.5 + sin(t * 0.8) * 0.05
			var top := lv + Vector2(0, -10) + Vector2(sin(ang), -cos(ang)) * 34.0
			draw_line(lv + Vector2(0, -10), top, wood, 4.0)
			draw_circle(top, 5.0, Color(0.6, 0.25, 0.2))
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

extends Node2D
# Éléments du décor interactifs : banc, orbe de pouvoir, sanctuaire final.

const DU = preload("res://scripts/draw_util.gd")

var kind := "bench"
var charm_id := -1
const CharmIcon = preload("res://scripts/charm_icon.gd")
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
			# banc de bois sombre à pieds de fer forgé, petite lanterne
			var wood := Color(0.3, 0.21, 0.16)
			var metal := Color(0.32, 0.33, 0.4)
			for x in [-22.0, 20.0]:
				draw_line(Vector2(x, -40), Vector2(x, 0), metal.darkened(0.4), 4.0)
				draw_line(Vector2(x - 0.7, -40), Vector2(x - 0.7, 0), metal, 2.0)
				draw_arc(Vector2(x, -4), 4.0, PI, TAU, 8, metal, 1.6)
			DU.box(self, Rect2(-27, -17, 54, 6), wood)
			DU.box(self, Rect2(-27, -31, 54, 5), wood.lightened(0.04))
			DU.box(self, Rect2(-27, -39, 54, 5), wood)
			for k in 3:
				draw_line(Vector2(-20 + k * 17, -15.5), Vector2(-12 + k * 17, -15), wood.darkened(0.4), 1.0)
			# petite lanterne
			draw_line(Vector2(0, -40), Vector2(0, -50), metal, 2.0)
			DU.glow(self, Vector2(0, -56), 20.0, Color(1.0, 0.8, 0.45), 0.5)
			DU.box(self, Rect2(-5, -63, 10, 2), metal)
			draw_rect(Rect2(-4, -61, 8, 9), Color(1.0, 0.82, 0.45, 0.9))
			draw_circle(Vector2(0, -56), 2.2 + sin(t * 3.0) * 0.4, Color(1, 1, 0.85))
			DU.box(self, Rect2(-5, -52, 10, 2), metal)
		"orb":
			var y := sin(t * 2.0) * 5.0
			DU.ball(self, Vector2(0, y), 18.0, Color(0.5, 0.85, 1.0, 0.18))
			DU.ball(self, Vector2(0, y), 10.0, Color(0.6, 0.9, 1.0, 0.9))
			DU.ball(self, Vector2(0, y), 5.0, Color(1, 1, 1))
			for i in 3:
				var a := t * 2.0 + i * TAU / 3.0
				DU.ball(self, Vector2(cos(a) * 22.0, y + sin(a) * 8.0), 2.0, Color(0.7, 0.95, 1.0))
		"door":
			_door()
		"charm":
			# emblème qui flotte : médaillon gravé, halo et éclats qui tournent
			var y := sin(t * 2.2) * 4.0
			DU.glow(self, Vector2(0, y), 30.0, color, 0.45)
			if charm_id >= 0:
				CharmIcon.draw(self, Vector2(0, y), 13.0, charm_id, color, false, t)
			else:
				DU.flat(self, DU.diamond(Vector2(0, y), Vector2(9, 12)), color)
			draw_arc(Vector2(0, y), 18.0, t, t + 4.0, 16, Color(color, 0.6), 1.5)
			for k in 3:
				var a := t * 2.0 + k * TAU / 3.0
				draw_circle(Vector2(cos(a) * 20.0, y + sin(a) * 7.0), 1.4, Color(color.lightened(0.4), 0.9))
		"notch":
			var y2 := sin(t * 2.0) * 4.0
			DU.ball(self, Vector2(0, y2), 16.0, Color(1.0, 0.9, 0.6, 0.15))
			draw_arc(Vector2(0, y2), 9.0, 0.0, TAU, 24, Color(1.0, 0.9, 0.6), 3.0)
			DU.ball(self, Vector2(0, y2), 4.0 + sin(t * 4.0), Color(1.0, 0.95, 0.8))
		"sign":
			# panneau de bois : poteau, planches clouées, rune lumineuse
			var wood := Color(0.4, 0.31, 0.25)
			draw_line(Vector2(0, 2), Vector2(0, -40), wood.darkened(0.45), 5.0)
			draw_line(Vector2(-0.8, 2), Vector2(-0.8, -40), wood, 3.0)
			for k in 2:
				DU.box(self, Rect2(-21, -59 + k * 13.5, 42, 13), wood.lightened(0.04 * k))
				draw_line(Vector2(-18 + k * 9, -56 + k * 13.5), Vector2(-6 + k * 9, -55.5 + k * 13.5), wood.darkened(0.35), 1.0)
			for c in [Vector2(-18, -55), Vector2(18, -55), Vector2(-18, -36), Vector2(18, -36)]:
				draw_circle(c, 1.4, Color(0.25, 0.22, 0.22))
				draw_circle(c + Vector2(-0.4, -0.4), 0.6, Color(0.75, 0.72, 0.7))
			var g := 0.9 if lit else 0.45 + sin(t * 3.0) * 0.2
			DU.glow(self, Vector2(0, -45), 16.0, Color(0.6, 0.85, 1.0), g * 0.5)
			DU.flat(self, DU.diamond(Vector2(0, -45), Vector2(6, 8)), Color(0.6, 0.85, 1.0, g))
			DU.flat(self, DU.diamond(Vector2(0, -45), Vector2(2.5, 3.5)), Color(1, 1, 1, g))
			if not lit:
				draw_string(ThemeDB.fallback_font, Vector2(-4, -64 + sin(t * 4.0) * 3.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.9, 0.6))
		"merchant":
			# Marchand : grand papillon de nuit voyageur, cape aux ocelles, sac rapiécé de babioles
			var bob := sin(t * 1.6) * 1.5
			var cloak := Color(0.36, 0.26, 0.32)
			var fur := Color(0.88, 0.84, 0.74)
			# sac de cuir : coutures, pièce, sangle, babioles qui pendent
			var bag := Vector2(15, -24 + bob)
			DU.poly(self, DU.ellipse(bag, Vector2(15, 17), 22), Color(0.48, 0.34, 0.22))
			DU.poly(self, PackedVector2Array([bag + Vector2(-2, -4), bag + Vector2(8, -6), bag + Vector2(9, 4), bag + Vector2(-1, 5)]), Color(0.36, 0.42, 0.3), false)
			for k in 5:
				draw_line(bag + Vector2(-2 + k * 2.4, -4.5 - k * 0.4), bag + Vector2(-2 + k * 2.4, -2.5 - k * 0.4), Color(0.85, 0.8, 0.6), 0.8)
			draw_arc(bag, 11.0, PI * 1.1, PI * 1.9, 14, Color(0.3, 0.2, 0.12), 1.2)
			draw_line(Vector2(-6, -36 + bob), bag + Vector2(4, -15), Color(0.32, 0.22, 0.14), 2.4)
			for i in 3:
				var bc: Color = [Color(1, 0.8, 0.4), Color(0.6, 0.9, 1), Color(0.9, 0.6, 1)][i]
				var bp := Vector2(8 + i * 6, -36 + bob + (i % 2) * 4)
				DU.poly(self, PackedVector2Array([bp + Vector2(-2, -3), bp + Vector2(2, -3), bp + Vector2(3, 3), bp + Vector2(-3, 3)]), bc)
				draw_circle(bp + Vector2(-0.8, -0.5), 0.8, Color(1, 1, 1, 0.8))
			var key := bag + Vector2(4, 16 + sin(t * 2.0))
			draw_line(bag + Vector2(4, 12), key, Color(0.75, 0.65, 0.35), 1.0)
			draw_arc(key + Vector2(0, 2), 2.0, 0.0, TAU, 8, Color(0.85, 0.72, 0.35), 1.2)
			# cape ronde aux ocelles d'aile de papillon de nuit
			var cape := PackedVector2Array([Vector2(-17, 0), Vector2(-14, -10), Vector2(-11, -36 + bob), Vector2(11, -36 + bob), Vector2(14, -10), Vector2(17, 0), Vector2(8, -3), Vector2(0, 0), Vector2(-8, -3)])
			DU.poly(self, cape, cloak)
			for k in [-1.0, 1.0]:
				var oc := Vector2(k * 8, -15 + bob * 0.5)
				draw_circle(oc, 5.0, Color(0.55, 0.38, 0.3))
				draw_circle(oc, 3.0, Color(0.15, 0.1, 0.12))
				draw_circle(oc + Vector2(-0.8, -0.8), 1.0, Color(0.95, 0.9, 0.75))
			draw_polyline(PackedVector2Array([Vector2(-17, 0), Vector2(-8, -3), Vector2(0, 0), Vector2(8, -3), Vector2(17, 0)]), Color(0.75, 0.6, 0.45), 1.4)
			# collerette de fourrure
			for k in 9:
				var a := PI + k * PI / 8.0
				DU.ball(self, Vector2(0, -34 + bob) + Vector2(cos(a) * 12.0, sin(a) * -4.0 + 2.0), 3.6, fur.darkened(0.08))
			# tête duveteuse, grands yeux luisants, antennes plumeuses
			DU.poly(self, DU.ellipse(Vector2(0, -44 + bob), Vector2(13, 11), 20), fur)
			for k in 6:
				var a := PI * 1.1 + k * 0.17
				draw_line(Vector2(0, -44 + bob) + Vector2.from_angle(a) * 11.0, Vector2(0, -44 + bob) + Vector2.from_angle(a) * 14.0, fur.lightened(0.1), 1.4)
			for k in [-1.0, 1.0]:
				var ep := Vector2(k * 5, -43 + bob)
				DU.flat(self, DU.ellipse(ep, Vector2(3.6, 4.2)), Color(0.08, 0.04, 0.1))
				draw_circle(ep + Vector2(-1, -1.4), 1.2, Color(1, 1, 1))
				draw_circle(ep + Vector2(1, 1.2), 0.6, Color(1, 1, 1, 0.6))
				var tip := Vector2(k * 14, -66 + bob + sin(t * 2.0) * 2.0 * k)
				var root := Vector2(k * 5, -53 + bob)
				draw_line(root, tip, fur.darkened(0.2), 1.6)
				for j in 5:
					var q := root.lerp(tip, 0.3 + j * 0.14)
					draw_line(q, q + Vector2(k * 3.0, 1.5), fur.darkened(0.1), 1.0)
					draw_line(q, q + Vector2(-k * 1.5, -2.5), fur.darkened(0.1), 1.0)
			# lanterne tenue
			draw_line(Vector2(-12, -22 + bob), Vector2(-22, -18 + bob), Color(0.45, 0.4, 0.35), 2.0)
			draw_line(Vector2(-22, -18 + bob), Vector2(-23, -14 + bob), Color(0.45, 0.4, 0.35), 1.2)
			var lp := Vector2(-23, -8 + bob)
			DU.glow(self, lp, 22.0, Color(1.0, 0.8, 0.45), 0.4)
			DU.box(self, Rect2(lp + Vector2(-5, -6), Vector2(10, 2)), Color(0.4, 0.35, 0.3))
			draw_rect(Rect2(lp + Vector2(-4, -4), Vector2(8, 9)), Color(1.0, 0.85, 0.5, 0.9))
			draw_circle(lp + Vector2(0, 1), 2.2 + sin(t * 3.0) * 0.4, Color(1, 1, 0.85))
			for k in 3:
				draw_line(lp + Vector2(-4 + k * 4, -4), lp + Vector2(-4 + k * 4, 5), Color(0.35, 0.3, 0.26), 1.0)
			DU.box(self, Rect2(lp + Vector2(-5, 5), Vector2(10, 2)), Color(0.4, 0.35, 0.3))
		"cache":
			# coffret de trésor
			var wood := Color(0.45, 0.3, 0.18)
			DU.box(self, Rect2(-14, -18, 28, 18), wood)
			DU.poly(self, DU.ellipse(Vector2(0, -18), Vector2(14, 7), 12, PI, TAU), wood.lightened(0.1))
			DU.box(self, Rect2(-14, -12, 28, 3), Color(0.85, 0.7, 0.3))
			DU.box(self, Rect2(-3, -16, 6, 7), Color(0.95, 0.8, 0.35))
			DU.ball(self, Vector2(0, -12), 18.0 + sin(t * 3.0) * 2.0, Color(1.0, 0.85, 0.4, 0.12))
		"challenge":
			# stèle au sablier : lance le défi chronométré
			var st := Color(0.4, 0.38, 0.42)
			DU.box(self, Rect2(-10, -46, 20, 46), st)
			DU.box(self, Rect2(-13, -50, 26, 5), st.lightened(0.15))
			var gc := Color(1.0, 0.75, 0.35) if not lit else Color(0.5, 0.5, 0.5)
			DU.poly(self, PackedVector2Array([Vector2(-6, -40), Vector2(6, -40), Vector2(0, -28)]), gc)
			DU.poly(self, PackedVector2Array([Vector2(-6, -16), Vector2(6, -16), Vector2(0, -28)]), gc)
			if not lit:
				draw_string(ThemeDB.fallback_font, Vector2(-4, -58 + sin(t * 4.0) * 3.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1.0, 0.8, 0.4))
		"flag":
			draw_line(Vector2(0, 0), Vector2(0, -56), Color(0.6, 0.5, 0.4), 3.0)
			var wave := sin(t * 5.0) * 3.0
			var fc := Color(1.0, 0.75, 0.35) if not lit else Color(0.6, 1.0, 0.6)
			DU.poly(self, PackedVector2Array([Vector2(1, -56), Vector2(26, -50 + wave), Vector2(1, -40)]), fc)
		"altar":
			var stn := Color(0.35, 0.3, 0.33)
			DU.box(self, Rect2(-22, -14, 44, 14), stn)
			DU.box(self, Rect2(-16, -34, 32, 20), stn.lightened(0.08))
			var ec := Color(1.0, 0.35, 0.3, 0.9) if not lit else Color(0.4, 0.35, 0.35, 0.8)
			for i in 3:
				DU.ball(self, Vector2(-10 + i * 10, -24), 3.5 + (sin(t * 4.0 + i) if not lit else 0.0), ec)
			if not lit:
				DU.ball(self, Vector2(0, -24), 26.0, Color(1.0, 0.3, 0.25, 0.08 + 0.05 * sin(t * 2.0)))
		"smith":
			# Forgeronne : scarabée trapu au tablier de cuir, lunettes sur le front,
			# devant sa forge de pierres maçonnées, son enclume et son râtelier
			var bob := sin(t * 1.5) * 1.0
			var shell := Color(0.25, 0.32, 0.46)
			var stone2 := Color(0.34, 0.31, 0.3)
			var ember := 0.6 + 0.4 * sin(t * 6.0)
			DU.glow(self, Vector2(-69, -24), 60.0, Color(1.0, 0.5, 0.2), 0.35 * ember)
			# cheminée en briques
			DU.box(self, Rect2(-86, -110, 22, 70), stone2.darkened(0.15))
			for r in 9:
				var yy := -110.0 + r * 8.0
				draw_line(Vector2(-86, yy), Vector2(-64, yy), stone2.darkened(0.5), 1.0)
				var off := 0.0 if r % 2 == 0 else 5.5
				for c in 2:
					draw_line(Vector2(-86 + off + c * 11, yy), Vector2(-86 + off + c * 11, yy + 8), stone2.darkened(0.5), 1.0)
			# foyer : pierres irrégulières autour de la gueule
			DU.box(self, Rect2(-92, -40, 46, 40), stone2)
			for k in 8:
				var sp := Vector2(-90 + (k % 4) * 11.5, -38 + (k / 4) * 30)
				DU.poly(self, DU.ellipse(sp + Vector2(5, 4), Vector2(5.5, 4), 10), stone2.lightened(0.05 * (k % 3)))
			DU.box(self, Rect2(-88, -32, 38, 18), Color(0.1, 0.05, 0.03))
			for i in 7:
				var cx := -84.0 + i * 5.5
				draw_circle(Vector2(cx, -20 + (i % 2) * 2), 3.0 + ember * (0.5 + 0.5 * sin(t * 5.0 + i)), Color(1.0, 0.4 + 0.06 * i, 0.12))
				draw_circle(Vector2(cx, -21 + (i % 2) * 2), 1.4, Color(1.0, 0.9, 0.5))
			for k in 3:
				var ft := fposmod(t * 1.3 + k * 0.33, 1.0)
				DU.flat(self, DU.ellipse(Vector2(-74 + k * 8, -24 - ft * 8), Vector2(2.5, 4.0 * (1.0 - ft))), Color(1.0, 0.6, 0.2, 1.0 - ft))
			for i in 3:
				var sy := -110.0 - fmod(t * 30.0 + i * 20.0, 60.0)
				draw_circle(Vector2(-75 + sin(t * 2.0 + i) * 4.0, sy), 4.0 + i, Color(0.4, 0.4, 0.42, 0.25))
			# soufflet de cuir
			var puff := absf(sin(t * 2.0)) * 6.0
			DU.poly(self, PackedVector2Array([Vector2(-46, -22), Vector2(-26, -31 - puff), Vector2(-22, -22), Vector2(-26, -13 + puff * 0.3)]), Color(0.5, 0.33, 0.2))
			for k in 3:
				draw_line(Vector2(-40 + k * 5, -25 - puff * (k / 3.0)), Vector2(-40 + k * 5, -18), Color(0.3, 0.2, 0.12), 1.0)
			draw_line(Vector2(-22, -22), Vector2(-12, -24), Color(0.4, 0.3, 0.2), 2.0)
			# enclume sur billot
			DU.box(self, Rect2(30, -8, 18, 8), Color(0.42, 0.3, 0.2))
			DU.poly(self, PackedVector2Array([Vector2(26, -8), Vector2(52, -8), Vector2(46, -12), Vector2(56, -20), Vector2(20, -20), Vector2(30, -12)]), Color(0.27, 0.28, 0.34))
			DU.poly(self, PackedVector2Array([Vector2(56, -20), Vector2(70, -17), Vector2(56, -15)]), Color(0.27, 0.28, 0.34))
			draw_line(Vector2(21, -19.5), Vector2(56, -19.5), Color(0.75, 0.78, 0.85), 1.0)
			DU.box(self, Rect2(32, -25, 16, 5), Color(1.0, 0.5, 0.2))
			DU.glow(self, Vector2(40, -23), 14.0, Color(1.0, 0.5, 0.2), 0.5)
			# râtelier d'outils : pince, marteau, lime
			DU.box(self, Rect2(68, -73, 34, 5), Color(0.42, 0.3, 0.2))
			draw_line(Vector2(76, -68), Vector2(76, -44), Color(0.55, 0.55, 0.6), 2.0)
			draw_line(Vector2(78, -68), Vector2(80, -46), Color(0.55, 0.55, 0.6), 2.0)
			draw_line(Vector2(87, -68), Vector2(87, -48), Color(0.45, 0.32, 0.2), 2.4)
			DU.box(self, Rect2(83, -50, 8, 5), Color(0.55, 0.55, 0.62))
			draw_line(Vector2(97, -68), Vector2(97, -46), Color(0.6, 0.62, 0.68), 2.0)
			# la forgeronne : carapace, tablier, bras, lunettes
			DU.poly(self, DU.ellipse(Vector2(0, -24 + bob), Vector2(17, 23), 24), shell)
			draw_line(Vector2(0, -46 + bob), Vector2(0, -6 + bob), shell.darkened(0.5), 1.2)
			var apron := PackedVector2Array([Vector2(-12, -30 + bob), Vector2(12, -30 + bob), Vector2(14, -2), Vector2(-14, -2)])
			DU.poly(self, apron, Color(0.5, 0.32, 0.2))
			draw_line(Vector2(-12, -30 + bob), Vector2(-7, -44 + bob), Color(0.38, 0.24, 0.14), 1.6)
			draw_line(Vector2(12, -30 + bob), Vector2(7, -44 + bob), Color(0.38, 0.24, 0.14), 1.6)
			DU.box(self, Rect2(-6, -20 + bob, 12, 8), Color(0.42, 0.27, 0.16))
			for k in 3:
				draw_circle(Vector2(-9 + k * 9, -28 + bob), 0.9, Color(0.85, 0.75, 0.45))
			for k in [-1.0, 1.0]:
				draw_line(Vector2(k * 7, -2), Vector2(k * 8, 0), shell.darkened(0.3), 4.0)
			DU.poly(self, DU.ellipse(Vector2(0, -52 + bob), Vector2(12, 11), 18), shell.lightened(0.15))
			draw_line(Vector2(-4, -61 + bob), Vector2(-10, -76 + bob), shell, 3.0)
			draw_line(Vector2(4, -61 + bob), Vector2(10, -76 + bob), shell, 3.0)
			DU.ball(self, Vector2(-10, -77 + bob), 2.2, shell.lightened(0.2))
			DU.ball(self, Vector2(10, -77 + bob), 2.2, shell.lightened(0.2))
			draw_line(Vector2(-12, -57 + bob), Vector2(12, -57 + bob), Color(0.3, 0.22, 0.15), 2.0)
			for k in [-1.0, 1.0]:
				draw_circle(Vector2(k * 5, -58 + bob), 3.4, Color(0.55, 0.45, 0.3))
				draw_circle(Vector2(k * 5, -58 + bob), 2.4, Color(0.55, 0.8, 0.9))
				draw_circle(Vector2(k * 5 - 0.8, -58.8 + bob), 0.8, Color(1, 1, 1, 0.9))
				draw_circle(Vector2(k * 4, -51 + bob), 2.5, Color(1.0, 0.7, 0.3))
				draw_circle(Vector2(k * 4 - 0.6, -51.8 + bob), 0.8, Color(1, 1, 0.85))
			# marteau qui frappe l'enclume
			var swing := absf(sin(t * 2.4))
			var hand := Vector2(14, -36 + bob)
			var head := hand + Vector2(10 + 8 * swing, -28 + 30 * swing)
			draw_line(Vector2(9, -34 + bob), hand, shell.darkened(0.2), 5.0)
			draw_line(hand, head, Color(0.35, 0.25, 0.15), 3.4)
			draw_line(hand, head, Color(0.6, 0.45, 0.3), 1.2)
			DU.box(self, Rect2(head - Vector2(7, 5), Vector2(14, 10)), Color(0.55, 0.56, 0.64))
			DU.ball(self, hand, 3.6, shell.darkened(0.1))
			if swing > 0.97:
				for i in 6:
					var a := -PI / 2 + (i - 2.5) * 0.4
					draw_line(Vector2(40, -25), Vector2(40, -25) + Vector2.from_angle(a) * (10.0 + (i % 3) * 4.0), Color(1.0, 0.85, 0.4), 1.5)
				DU.glow(self, Vector2(40, -25), 20.0, Color(1.0, 0.8, 0.4), 0.6)
		"cartographer":
			# Cartographe : mite à lunettes et redingote devant sa table à cartes,
			# globe sur pied, étagère de rouleaux et bougie
			var bob2 := sin(t * 2.0) * 1.5
			var fur := Color(0.78, 0.72, 0.6)
			var wood := Color(0.44, 0.31, 0.2)
			# étagère de rouleaux et d'étuis
			DU.box(self, Rect2(-96, -96, 44, 96), wood.darkened(0.3))
			for r in 3:
				DU.box(self, Rect2(-98, -92 + r * 30, 48, 5), wood)
				for k in 4:
					var rc := Vector2(-88 + k * 10, -79 + r * 30)
					if (k + r) % 3 == 0:
						DU.box(self, Rect2(rc + Vector2(-4, -8), Vector2(8, 16)), Color(0.5, 0.25, 0.2))
						draw_line(rc + Vector2(-4, -4), rc + Vector2(4, -4), Color(0.85, 0.7, 0.35), 1.0)
					else:
						DU.ball(self, rc, 4.4, Color(0.92, 0.86, 0.7))
						draw_arc(rc, 2.6, 0.0, TAU, 10, Color(0.65, 0.55, 0.4), 1.0)
						draw_circle(rc, 1.0, Color(0.55, 0.45, 0.3))
			# globe sur pied : méridiens et continents qui tournent
			draw_line(Vector2(-44, 0), Vector2(-36, -12), wood, 3.0)
			draw_line(Vector2(-28, 0), Vector2(-36, -12), wood, 3.0)
			draw_line(Vector2(-36, -12), Vector2(-36, -28), wood, 3.0)
			DU.ball(self, Vector2(-36, -42), 13.0, Color(0.32, 0.52, 0.68))
			var rot := fposmod(t * 0.4, 1.0)
			for k in 2:
				var cx := -36.0 + (fposmod(rot + k * 0.5, 1.0) - 0.5) * 22.0
				if absf(cx + 36.0) < 9.0:
					DU.poly(self, DU.ellipse(Vector2(cx, -44 + k * 6), Vector2(4.0 * (1.0 - absf(cx + 36.0) / 11.0) + 1.0, 5 - k)), Color(0.45, 0.65, 0.38), false)
			draw_line(Vector2(-49, -42), Vector2(-23, -42), Color(0.8, 0.85, 0.9, 0.35), 1.0)
			draw_arc(Vector2(-36, -42), 15.0, PI * 0.6, PI * 2.4, 24, Color(0.75, 0.62, 0.32), 2.2)
			# table : plateau, pieds tournés, carte, compas, encrier
			DU.box(self, Rect2(12, -30, 74, 6), wood)
			for lx in [20.0, 78.0]:
				DU.box(self, Rect2(lx - 2.5, -24, 5, 24), wood.darkened(0.2))
				DU.ball(self, Vector2(lx, -12), 3.6, wood.darkened(0.1))
			DU.poly(self, PackedVector2Array([Vector2(18, -32), Vector2(80, -32), Vector2(76, -41), Vector2(22, -41)]), Color(0.93, 0.87, 0.68))
			draw_polyline(PackedVector2Array([Vector2(27, -35), Vector2(33, -38), Vector2(40, -36), Vector2(46, -39), Vector2(54, -35), Vector2(64, -38), Vector2(70, -36)]), Color(0.55, 0.32, 0.22), 1.2)
			draw_line(Vector2(30, -36.5), Vector2(34, -36.5), Color(0.3, 0.45, 0.6), 1.0)
			for k in 3:
				draw_circle(Vector2(36 + k * 12, -34.5), 0.8, Color(0.75, 0.2, 0.2))
			draw_line(Vector2(56, -41), Vector2(62, -52), Color(0.65, 0.65, 0.7), 1.5)
			draw_line(Vector2(62, -52), Vector2(68, -41), Color(0.65, 0.65, 0.7), 1.5)
			DU.ball(self, Vector2(62, -52), 1.6, Color(0.8, 0.7, 0.4))
			DU.box(self, Rect2(70, -37, 6, 5), Color(0.15, 0.15, 0.2))
			# bougie et cire coulée
			DU.glow(self, Vector2(84, -50), 22.0, Color(1.0, 0.8, 0.45), 0.4)
			DU.box(self, Rect2(81.5, -46, 5, 14), Color(0.95, 0.92, 0.85))
			draw_line(Vector2(82, -46), Vector2(82, -40), Color(0.9, 0.85, 0.75), 1.4)
			DU.flat(self, DU.ellipse(Vector2(84, -50), Vector2(2.0, 3.6 + sin(t * 9.0) * 0.4)), Color(1.0, 0.82, 0.45))
			# le cartographe : redingote, boutons, fourrure, lunettes rondes, plume
			var coat := PackedVector2Array([Vector2(-12, 0), Vector2(-13, -20 + bob2), Vector2(-9, -32 + bob2), Vector2(9, -32 + bob2), Vector2(13, -20 + bob2), Vector2(12, 0), Vector2(3, -4), Vector2(0, 0), Vector2(-3, -4)])
			DU.poly(self, coat, Color(0.3, 0.32, 0.42))
			draw_line(Vector2(0, -31 + bob2), Vector2(0, -4), Color(0.18, 0.18, 0.25), 1.2)
			for k in 3:
				DU.ball(self, Vector2(2.5, -26 + k * 7 + bob2), 1.4, Color(0.85, 0.72, 0.38))
			for k in 7:
				var a := PI + k * PI / 6.0
				DU.ball(self, Vector2(0, -32 + bob2) + Vector2(cos(a) * 10.0, -sin(a) * 2.5), 3.0, fur.darkened(0.06))
			DU.poly(self, DU.ellipse(Vector2(0, -41 + bob2), Vector2(11, 10), 18), fur)
			for k in [-1.0, 1.0]:
				var gp := Vector2(k * 4, -41 + bob2)
				draw_circle(gp, 2.4, Color(0.1, 0.06, 0.1))
				draw_circle(gp + Vector2(-0.6, -0.7), 0.7, Color(1, 1, 1))
				draw_arc(gp, 3.8, 0.0, TAU, 14, Color(0.9, 0.82, 0.45), 1.4)
				draw_circle(gp + Vector2(-1.4, -1.4), 1.2, Color(1, 1, 1, 0.35))
				draw_line(Vector2(k * 3, -50 + bob2), Vector2(k * 10, -61 + bob2), fur.darkened(0.15), 1.8)
				for j in 3:
					var q := Vector2(k * 3, -50 + bob2).lerp(Vector2(k * 10, -61 + bob2), 0.35 + j * 0.25)
					draw_line(q, q + Vector2(k * 2.5, 1.5), fur.darkened(0.1), 1.0)
			draw_line(Vector2(-0.2, -41 + bob2), Vector2(0.2, -41 + bob2), Color(0.9, 0.82, 0.45), 1.2)
			var qx := 16.0 + sin(t * 4.0) * 3.0
			draw_line(Vector2(8, -24 + bob2), Vector2(qx, -36), Color(0.3, 0.32, 0.42), 3.0)
			DU.ball(self, Vector2(qx, -36), 2.4, fur)
			draw_line(Vector2(qx, -36), Vector2(qx + 3, -50), Color(0.95, 0.95, 0.9), 1.2)
			DU.poly(self, PackedVector2Array([Vector2(qx + 1, -40), Vector2(qx + 7, -54), Vector2(qx + 3, -52), Vector2(qx + 2, -44)]), Color(0.95, 0.95, 0.9))
		"elder":
			# L'ancien : vieil escargot encapuchonné, assis sur un tapis près d'un autel
			# de bougies, avec sa canne et la vieille lanterne éteinte qu'il a portée autrefois
			var bob3 := sin(t * 0.8) * 1.0
			var stone3 := Color(0.35, 0.33, 0.36)
			var robe := Color(0.3, 0.25, 0.37)
			# autel de pierre gravée, bougies à cire coulée
			DU.box(self, Rect2(-80, -26, 40, 26), stone3)
			DU.box(self, Rect2(-84, -31, 48, 6), stone3.lightened(0.12))
			draw_arc(Vector2(-60, -12), 6.0, 0.0, TAU, 16, stone3.darkened(0.45), 1.2)
			DU.flat(self, DU.diamond(Vector2(-60, -12), Vector2(2.5, 3.5)), stone3.darkened(0.35))
			for i in 3:
				var bx := -74.0 + i * 13.0
				var bh := 10.0 + (i % 2) * 6.0
				DU.glow(self, Vector2(bx + 2.5, -35 - bh), 16.0, Color(1.0, 0.75, 0.3), 0.35)
				DU.box(self, Rect2(bx, -31 - bh, 5, bh), Color(0.93, 0.89, 0.78))
				draw_line(Vector2(bx + 0.6, -31 - bh), Vector2(bx + 0.6, -31 - bh * 0.4), Color(0.85, 0.8, 0.68), 1.4)
				var fl := 1.0 + 0.3 * sin(t * 9.0 + i * 2.0)
				DU.flat(self, DU.ellipse(Vector2(bx + 2.5, -35 - bh), Vector2(2.2, 4.0 * fl)), Color(1.0, 0.72, 0.28))
				DU.flat(self, DU.ellipse(Vector2(bx + 2.5, -34 - bh), Vector2(1.0, 2.0 * fl)), Color(1.0, 0.95, 0.75))
			# tapis brodé à franges
			DU.poly(self, DU.ellipse(Vector2(4, 0), Vector2(40, 5), 24), Color(0.48, 0.2, 0.22))
			draw_arc(Vector2(4, 0), 30.0, PI * 1.05, PI * 1.95, 20, Color(0.85, 0.65, 0.35, 0.8), 1.0)
			for k in 9:
				draw_line(Vector2(-34 + k * 9, 2), Vector2(-34 + k * 9, 6), Color(0.85, 0.65, 0.35), 1.0)
			# coquille spiralée : dégradé, spirale, stries de croissance, mousse
			var sc := Vector2(-6, -22 + bob3)
			DU.poly(self, DU.ellipse(sc, Vector2(21, 19), 28), Color(0.55, 0.43, 0.33))
			var spiral := PackedVector2Array()
			for k in 40:
				var a := k * 0.35
				var rr := 16.0 * (1.0 - k / 44.0)
				spiral.append(sc + Vector2(cos(a), sin(a)) * rr + Vector2(k * 0.05, 0))
			draw_polyline(spiral, Color(0.32, 0.24, 0.18), 2.2)
			for k in 7:
				var a := PI * 1.1 + k * 0.28
				draw_line(sc + Vector2.from_angle(a) * 14.0, sc + Vector2.from_angle(a) * 20.0, Color(0.42, 0.32, 0.25), 1.0)
			for k in 5:
				var a := PI * 1.25 + k * 0.2
				DU.ball(self, sc + Vector2.from_angle(a) * 19.0, 2.6, Color(0.42, 0.55, 0.38))
			# corps, robe à capuche avec plis
			DU.poly(self, DU.ellipse(Vector2(16, -6), Vector2(18, 6), 18), Color(0.62, 0.62, 0.56))
			var gown := PackedVector2Array([Vector2(8, -4), Vector2(34, -4), Vector2(29, -30 + bob3), Vector2(27, -44 + bob3), Vector2(21, -51 + bob3), Vector2(14, -46 + bob3), Vector2(12, -30 + bob3)])
			DU.poly(self, gown, robe)
			for k in 3:
				draw_line(Vector2(15 + k * 6, -32 + bob3), Vector2(13 + k * 8, -5), robe.darkened(0.4), 1.0)
			draw_line(Vector2(10, -6), Vector2(33, -6), Color(0.75, 0.6, 0.35), 1.4)
			DU.poly(self, DU.ellipse(Vector2(23, -38 + bob3), Vector2(5.5, 6.5), 14), Color(0.07, 0.05, 0.09), false)
			var blink := 0.3 if fmod(t, 5.0) < 0.15 else 1.6
			DU.flat(self, DU.ellipse(Vector2(25, -39 + bob3), Vector2(1.6, blink)), Color(1.0, 0.9, 0.6))
			DU.glow(self, Vector2(25, -39 + bob3), 6.0, Color(1.0, 0.85, 0.5), 0.4)
			# barbe de mousse en mèches
			for k in 4:
				var bx := 19.5 + k * 2.2
				draw_line(Vector2(bx, -33 + bob3), Vector2(bx + 1.0 - k * 0.3, -21 + bob3 + (k % 2) * 3), Color(0.5, 0.62, 0.42), 2.0)
			# canne sculptée avec un petit grelot
			draw_line(Vector2(36, 0), Vector2(32, -50), Color(0.32, 0.23, 0.15), 3.6)
			draw_line(Vector2(35.4, 0), Vector2(31.4, -50), Color(0.55, 0.42, 0.28), 1.2)
			for k in 3:
				draw_line(Vector2(35.2 - k * 0.4, -14 - k * 10), Vector2(33.0 - k * 0.4, -16 - k * 10), Color(0.25, 0.18, 0.12), 1.0)
			DU.ball(self, Vector2(32, -53), 3.6, Color(0.45, 0.33, 0.22))
			draw_line(Vector2(31, -52), Vector2(27, -48 + sin(t * 1.5)), Color(0.6, 0.55, 0.45), 0.8)
			DU.ball(self, Vector2(27, -46 + sin(t * 1.5)), 1.8, Color(0.85, 0.72, 0.35))
			# vieille lanterne éteinte à ses pieds, verre fêlé
			var lc := Vector2(50, 0)
			DU.poly(self, PackedVector2Array([lc + Vector2(-9, -18), lc + Vector2(9, -18), lc + Vector2(0, -27)]), Color(0.3, 0.3, 0.36))
			draw_arc(lc + Vector2(0, -28), 3.0, PI, TAU, 8, Color(0.3, 0.3, 0.36), 1.4)
			draw_rect(Rect2(lc + Vector2(-7, -18), Vector2(14, 16)), Color(0.1, 0.09, 0.12))
			draw_polyline(PackedVector2Array([lc + Vector2(-5, -16), lc + Vector2(-1, -10), lc + Vector2(-4, -5)]), Color(0.6, 0.65, 0.75, 0.6), 0.8)
			for i in 3:
				draw_line(lc + Vector2(-7 + i * 7, -18), lc + Vector2(-7 + i * 7, -2), Color(0.32, 0.32, 0.38), 1.6)
			DU.box(self, Rect2(lc + Vector2(-9, -3), Vector2(18, 3)), Color(0.32, 0.32, 0.38))
			# fumée d'encens
			for i in 3:
				var sy2 := -46.0 - fmod(t * 14.0 + i * 15.0, 45.0)
				draw_circle(Vector2(-62 + sin(t + i) * 5.0, sy2), 3.0 + i, Color(0.7, 0.7, 0.75, 0.15))
		"arsenal":
			# Arsenal : présentoir de bois à auvent, fond de planches, bannière,
			# les quatre armes exposées sur leurs crochets, caisse et lanterne
			var wood := Color(0.36, 0.26, 0.19)
			var dark := wood.darkened(0.45)
			# fond de planches
			for k in 6:
				DU.box(self, Rect2(-36 + k * 12, -84, 12, 84), wood.darkened(0.25 + 0.04 * (k % 2)))
				draw_circle(Vector2(-30 + k * 12, -80), 0.9, Color(0.6, 0.55, 0.5))
			# montants et auvent de bardeaux
			for x in [-39.0, 39.0]:
				DU.box(self, Rect2(x - 3, -92, 6, 92), wood)
			var roof := PackedVector2Array([Vector2(-48, -88), Vector2(48, -88), Vector2(40, -104), Vector2(-40, -104)])
			DU.poly(self, roof, Color(0.42, 0.2, 0.16))
			for k in 8:
				draw_line(Vector2(-44 + k * 12, -88), Vector2(-38 + k * 11, -104), Color(0.3, 0.13, 0.1), 1.0)
			for k in 7:
				DU.flat(self, DU.ellipse(Vector2(-42 + k * 14, -88), Vector2(7, 3), 10, 0.0, PI), Color(0.48, 0.24, 0.18))
			# bannière aux armes croisées
			DU.poly(self, PackedVector2Array([Vector2(-8, -86), Vector2(8, -86), Vector2(8, -66), Vector2(0, -61), Vector2(-8, -66)]), Color(0.55, 0.15, 0.18))
			draw_line(Vector2(-5, -82), Vector2(5, -68), Color(0.9, 0.78, 0.4), 1.4)
			draw_line(Vector2(5, -82), Vector2(-5, -68), Color(0.9, 0.78, 0.4), 1.4)
			draw_circle(Vector2(0, -75), 1.8, Color(0.95, 0.85, 0.5))
			# étagère et crochets
			DU.box(self, Rect2(-38, -44, 76, 5), wood.lightened(0.05))
			for x in [-26.0, -9.0, 9.0, 26.0]:
				draw_line(Vector2(x, -60), Vector2(x + 3, -57), Color(0.6, 0.6, 0.66), 1.6)
			# aiguille : lame, garde dorée, poignée
			draw_line(Vector2(-26, -58), Vector2(-26, -50), Color(0.35, 0.25, 0.18), 2.6)
			draw_line(Vector2(-30, -50), Vector2(-22, -50), Color(0.85, 0.7, 0.35), 2.0)
			DU.flat(self, PackedVector2Array([Vector2(-27.5, -49), Vector2(-26, -16), Vector2(-24.5, -49)]), Color(0.86, 0.9, 0.98))
			draw_line(Vector2(-26.6, -48), Vector2(-26.2, -20), Color(1, 1, 1, 0.8), 0.8)
			# fouet de ronces enroulé
			draw_arc(Vector2(-9, -52), 7.0, 0.0, TAU, 16, Color(0.3, 0.45, 0.22), 3.4)
			draw_arc(Vector2(-9, -52), 7.0, 0.0, TAU, 16, Color(0.55, 0.78, 0.42), 1.8)
			draw_arc(Vector2(-9, -52), 3.5, 0.0, TAU, 12, Color(0.5, 0.72, 0.38), 1.6)
			for k in 6:
				var aa := k * TAU / 6.0
				draw_line(Vector2(-9, -52) + Vector2.from_angle(aa) * 7.0, Vector2(-9, -52) + Vector2.from_angle(aa + 0.3) * 9.5, Color(0.8, 0.88, 0.6), 1.0)
			draw_polyline(PackedVector2Array([Vector2(-9, -45), Vector2(-7, -36), Vector2(-10, -28), Vector2(-8, -20)]), Color(0.5, 0.72, 0.38), 2.0)
			# marteau d'enclume
			draw_line(Vector2(9, -60), Vector2(9, -18), Color(0.3, 0.2, 0.12), 3.6)
			draw_line(Vector2(8.4, -60), Vector2(8.4, -18), Color(0.58, 0.42, 0.27), 1.4)
			DU.box(self, Rect2(1, -62, 16, 11), Color(0.5, 0.52, 0.6))
			draw_line(Vector2(1, -61), Vector2(17, -61), Color(0.85, 0.87, 0.95), 1.0)
			# étoiles de lune sur un coussin
			DU.poly(self, DU.ellipse(Vector2(26, -47), Vector2(8, 3.5), 14), Color(0.3, 0.3, 0.55))
			for j in 2:
				var sc := Vector2(23 + j * 7, -53 - j * 3)
				for i in 4:
					var a3 := i * PI / 2.0 + t * (1.0 + j)
					DU.flat(self, PackedVector2Array([sc, sc + Vector2.from_angle(a3 - 0.4) * 2.6, sc + Vector2.from_angle(a3) * 6.0]), Color(0.82, 0.88, 0.98))
				draw_circle(sc, 1.2, Color(0.3, 0.35, 0.45))
			DU.glow(self, Vector2(26, -52), 14.0, Color(0.7, 0.85, 1.0), 0.35)
			# caisse et lanterne
			DU.box(self, Rect2(-36, -14, 22, 14), wood.lightened(0.08))
			draw_line(Vector2(-36, -14), Vector2(-14, 0), dark, 1.2)
			draw_line(Vector2(-14, -14), Vector2(-36, 0), dark, 1.2)
			DU.glow(self, Vector2(30, -70), 18.0, Color(1.0, 0.8, 0.45), 0.5)
			draw_line(Vector2(30, -88), Vector2(30, -76), Color(0.4, 0.4, 0.45), 1.2)
			DU.box(self, Rect2(26, -77, 8, 2), Color(0.35, 0.33, 0.36))
			draw_rect(Rect2(27, -75, 6, 8), Color(1.0, 0.82, 0.45, 0.9))
			DU.box(self, Rect2(26, -67, 8, 2), Color(0.35, 0.33, 0.36))
			# petite enclume de démonstration
			DU.poly(self, PackedVector2Array([Vector2(4, 0), Vector2(22, 0), Vector2(18, -6), Vector2(26, -11), Vector2(0, -11), Vector2(8, -6)]), Color(0.27, 0.28, 0.34))
		"elevator":
			# Monte-charge de bois : cabine à claire-voie, cordes, grande roue de treuil et levier
			var wood := Color(0.42, 0.3, 0.2)
			var dark := Color(0.24, 0.16, 0.11)
			var rope := Color(0.72, 0.62, 0.42)
			var bob2 := sin(t * 1.2) * 1.0
			# portique de poutres
			DU.box(self, Rect2(-44, -150, 9, 150), dark)
			DU.box(self, Rect2(35, -150, 9, 150), dark)
			DU.box(self, Rect2(-50, -160, 100, 12), wood)
			draw_line(Vector2(-35, -148), Vector2(-14, -126), dark, 4.0)
			draw_line(Vector2(35, -148), Vector2(14, -126), dark, 4.0)
			# roue de treuil (tourne lentement)
			var g := Vector2(0, -176)
			draw_arc(g, 22.0, 0.0, TAU, 28, wood, 5.0)
			draw_arc(g, 14.0, 0.0, TAU, 20, dark, 2.0)
			for i in 6:
				var a2 := t * 0.6 + i * TAU / 6.0
				draw_line(g, g + Vector2(cos(a2), sin(a2)) * 22.0, wood, 3.0)
				DU.ball(self, g + Vector2(cos(a2), sin(a2)) * 26.0, 3.0, dark)   # poignées
			DU.ball(self, g, 5.0, Color(0.55, 0.5, 0.42))
			# cordes jusqu'à la cabine (et plus haut, vers la surface)
			for cx in [-18.0, 18.0]:
				draw_line(Vector2(cx, -400), Vector2(cx, -82 + bob2), rope, 2.0)
				for k in 12:
					var ky := -400.0 + k * 26.0
					draw_line(Vector2(cx - 2, ky), Vector2(cx + 2, ky + 6), rope.darkened(0.3), 1.0)
			# cabine à claire-voie
			var cab := Rect2(-30, -82 + bob2, 60, 82)
			DU.box(self, cab, Color(0.1, 0.07, 0.05, 0.75))
			DU.box(self, Rect2(-32, -84 + bob2, 64, 8), wood)
			DU.box(self, Rect2(-32, -6, 64, 8), wood)
			for i in 5:
				draw_line(Vector2(-28 + i * 14, -78 + bob2), Vector2(-28 + i * 14, -6), wood.darkened(0.1), 3.0)
			draw_line(Vector2(-30, -78 + bob2), Vector2(30, -8), dark, 3.0)          # croisillon
			draw_line(Vector2(30, -78 + bob2), Vector2(-30, -8), dark, 3.0)
			DU.ball(self, Vector2(0, -50), 5.0 + sin(t * 3.0) * 0.6, Color(1.0, 0.8, 0.45))   # lanterne dans la cabine
			DU.ball(self, Vector2(0, -50), 14.0, Color(1.0, 0.8, 0.45, 0.18))
			# levier de bois (au lieu d'un bouton)
			var lv := Vector2(52, 0)
			DU.box(self, Rect2(lv.x - 8, -12, 16, 12), dark)
			var ang := -0.5 + sin(t * 0.8) * 0.05
			var top := lv + Vector2(0, -10) + Vector2(sin(ang), -cos(ang)) * 34.0
			draw_line(lv + Vector2(0, -10), top, wood, 4.0)
			DU.ball(self, top, 5.0, Color(0.6, 0.25, 0.2))
		"shrine":
			var stone := Color(0.3, 0.32, 0.42)
			DU.box(self, Rect2(-40, -10, 80, 10), stone)
			DU.box(self, Rect2(-30, -90, 10, 80), stone)
			DU.box(self, Rect2(20, -90, 10, 80), stone)
			DU.box(self, Rect2(-40, -100, 80, 12), stone)
			# grande lanterne
			var glow := 0.6 + sin(t * 2.0) * 0.15
			draw_line(Vector2(0, -88), Vector2(0, -70), Color(0.5, 0.52, 0.6), 2.0)
			DU.poly(self, PackedVector2Array([Vector2(-10, -70), Vector2(10, -70), Vector2(7, -44), Vector2(-7, -44)]), Color(1.0, 0.82, 0.5, glow))
			DU.ball(self, Vector2(0, -57), 26.0, Color(1.0, 0.85, 0.55, 0.15))


# ---------------------------------------------------------------- portails de fin de niveau, un par biome
const DOOR_COLORS := {"jardins": Color(0.6, 1.0, 0.6), "citadelle": Color(0.85, 0.75, 1.0), "cristal": Color(0.55, 1.0, 1.0),
	"forge": Color(1.0, 0.6, 0.3), "bibliotheque": Color(1.0, 0.85, 0.5), "glace": Color(0.82, 0.95, 1.0),
	"ruche": Color(1.0, 0.8, 0.3), "ossuaire": Color(0.8, 0.92, 0.75)}

static func door_color(biome: String) -> Color:
	return DOOR_COLORS.get(biome, Color(0.55, 0.8, 1.0))

func _biome() -> String:
	var m = get_parent()
	if m and "pal" in m:
		return String(m.pal.get("id", ""))
	return ""

# forme de l'ouverture (là où brille le voile)
func _opening(shape: String) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match shape:
		"gothic":
			pts.append(Vector2(-20, 0))
			for k in 11:
				var ang := PI + k * (PI / 3.0) / 10.0
				pts.append(Vector2(20, -76) + Vector2.from_angle(ang) * 40.0)
			for k in range(1, 11):
				var ang := -PI / 3.0 + k * (PI / 3.0) / 10.0
				pts.append(Vector2(-20, -76) + Vector2.from_angle(ang) * 40.0)
			pts.append(Vector2(20, 0))
		"hex":
			for k in 6:
				pts.append(Vector2(0, -48) + Vector2(cos(k * PI / 3.0) * 30.0, sin(k * PI / 3.0) * 46.0))
		"rect":
			pts = PackedVector2Array([Vector2(-20, 0), Vector2(-20, -92), Vector2(20, -92), Vector2(20, 0)])
		_:
			pts.append(Vector2(-20, 0))
			pts.append(Vector2(-20, -80))
			for k in 17:
				pts.append(Vector2(0, -80) + Vector2.from_angle(PI + k * PI / 16.0) * 20.0)
			pts.append(Vector2(20, 0))
	return pts

func _veil(shape: String, c: Color, a: float) -> void:
	DU.glow(self, Vector2(0, -50), 85.0, c, a * 0.9)
	var op := _opening(shape)
	DU.flat(self, op, Color(c.darkened(0.45), 0.6 + a * 0.35))
	# dégradé intérieur : plus clair en bas
	var cols := PackedColorArray()
	for q in op:
		cols.append(Color(c.lightened(0.3), clampf((q.y + 100.0) / 100.0, 0.0, 1.0) * a * 1.2))
	if not Geometry2D.triangulate_polygon(op).is_empty():
		draw_polygon(op, cols)
	for k in 3:
		var r := 6.0 + k * 5.0 + fposmod(t * 6.0, 5.0)
		draw_arc(Vector2(0, -50), r, t * (1.5 + k * 0.5), t * (1.5 + k * 0.5) + 4.0, 16, Color(c.lightened(0.5), 0.35 - k * 0.08), 1.4)
	for i in 6:
		var y := -fmod(t * 30.0 + i * 14.0, 88.0)
		var pt := Vector2(sin(t + i) * 12.0, y)
		if Geometry2D.is_point_in_polygon(pt, op):
			draw_circle(pt, 1.4, Color(c.lightened(0.6), 0.85))

func _door() -> void:
	var b := _biome()
	var c := door_color(b)
	var a := 0.35 + sin(t * 2.5) * 0.12
	match b:
		"jardins": _door_mushroom(c, a)
		"citadelle": _door_gothic(c, a)
		"cristal": _door_crystal(c, a)
		"forge": _door_forge(c, a)
		"bibliotheque": _door_books(c, a)
		"glace": _door_ice(c, a)
		"ruche": _door_hive(c, a)
		"ossuaire": _door_bones(c, a)
		_: _door_stone(c, a, Color(0.34, 0.35, 0.44), Color(0.3, 0.48, 0.32))

# arche de pierre en plein cintre (Profondeurs, tutoriel, Sanctuaire) ; sert aussi de base
func _arch_frame(stone: Color, joints := true) -> void:
	var frame := PackedVector2Array([Vector2(-33, 0), Vector2(-33, -80)])
	for k in 17:
		frame.append(Vector2(0, -80) + Vector2.from_angle(PI + k * PI / 16.0) * 33.0)
	frame.append(Vector2(33, 0))
	frame.append(Vector2(20, 0))
	for k in 17:
		frame.append(Vector2(0, -80) + Vector2.from_angle(TAU - k * PI / 16.0) * 20.0)
	frame.append(Vector2(-20, 0))
	DU.poly(self, frame, stone)
	if joints:
		var joint := stone.darkened(0.5)
		for side: float in [-1.0, 1.0]:
			for k in range(1, 5):
				draw_line(Vector2(side * 20, -k * 16.0), Vector2(side * 33, -k * 16.0), joint, 1.2)
			for k in 5:
				var jx: float = side * (26.5 + (3.0 if k % 2 == 0 else -3.0))
				draw_line(Vector2(jx, -k * 16.0), Vector2(jx, -k * 16.0 - 16.0), joint, 1.0)
		for k in range(1, 8):
			var ang := PI + k * PI / 8.0
			draw_line(Vector2(0, -80) + Vector2.from_angle(ang) * 20.0, Vector2(0, -80) + Vector2.from_angle(ang) * 33.0, joint, 1.2)
	draw_arc(Vector2(0, -80), 20.5, PI, TAU, 24, stone.darkened(0.6), 1.6)
	draw_arc(Vector2(0, -80), 32.5, PI * 1.05, PI * 1.5, 14, DU.lit(stone, 1.5, 0.06), 1.4)

func _steps(stone: Color) -> void:
	DU.box(self, Rect2(-38, -5, 76, 5), stone.darkened(0.1))
	DU.box(self, Rect2(-34, -9, 68, 4), stone.lightened(0.02))

func _door_stone(c: Color, a: float, stone: Color, leaf: Color) -> void:
	_veil("round", c, a)
	_arch_frame(stone)
	var key := PackedVector2Array([Vector2(-7, -100), Vector2(7, -100), Vector2(9, -117), Vector2(-9, -117)])
	DU.poly(self, key, stone.lightened(0.08))
	DU.glow(self, Vector2(0, -108), 12.0, c, 0.6 + a)
	DU.flat(self, DU.diamond(Vector2(0, -108), Vector2(3.5, 5)), Color(c.lightened(0.5), 0.6 + a))
	for side in [-1.0, 1.0]:
		DU.box(self, Rect2(side * 26.5 - 9, -84, 18, 5), stone.lightened(0.06))
	_steps(stone)
	var vine := PackedVector2Array()
	for k in 10:
		var ang := PI * 1.05 + k * 0.1
		vine.append(Vector2(0, -80) + Vector2.from_angle(ang) * (33.0 + sin(k * 1.7) * 1.5))
	draw_polyline(vine, leaf.darkened(0.3), 1.4)
	for k in range(0, 10, 2):
		DU.ball(self, vine[k] + Vector2(1, 1), 2.4, leaf)
	for k in 4:
		draw_line(Vector2(-33, -40 - k * 9), Vector2(-35, -36 - k * 9), leaf, 2.0)
	for k in 5:
		draw_circle(Vector2(-30 + k * 15, -9), 2.0, Color(leaf, 0.9))

func _door_mushroom(c: Color, a: float) -> void:
	_veil("round", c, a)
	var stem := Color(0.6, 0.56, 0.46)
	# deux pieds courbes qui se penchent l'un vers l'autre
	for side: float in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(side * 36, 0), Vector2(side * 22, 0)])
		for k in 9:
			var u := k / 8.0
			pts.append(Vector2(side * (22.0 + sin(u * PI) * 3.0 - u * 6.0), -u * 92.0))
		for k in range(8, -1, -1):
			var u := k / 8.0
			pts.append(Vector2(side * (34.0 + sin(u * PI) * 4.0 - u * 8.0), -u * 92.0))
		DU.poly(self, pts, stem)
		for k in 4:
			draw_line(Vector2(side * 25, -16 - k * 18), Vector2(side * 31, -12 - k * 18), stem.darkened(0.35), 1.0)
		# lamelles et chapeau
		var cap_c := Vector2(side * 24, -96)
		var cap := DU.ellipse(cap_c, Vector2(26, 15), 22, PI, TAU)
		DU.poly(self, cap, Color(0.72, 0.25, 0.3) if side < 0 else Color(0.3, 0.62, 0.6))
		for k in 7:
			draw_line(cap_c + Vector2(-22 + k * 7.3, 0), cap_c + Vector2(-18 + k * 6, 4), Color(0.9, 0.82, 0.7), 1.0)
		for k in 4:
			var sp := cap_c + Vector2(-16 + k * 10, -6 - absf(k - 1.5) * -2.5 - 3.0)
			DU.ball(self, sp, 2.4 - (k % 2) * 0.6, Color(1, 0.95, 0.85))
	# spores lumineuses
	for k in 7:
		var u := fposmod(t * 0.3 + k / 7.0, 1.0)
		draw_circle(Vector2(sin(k * 2.1 + t) * 40.0, -100 + u * -40.0), 1.6, Color(c, 0.8 * (1.0 - u)))
	# herbe et petits champignons au pied
	for side in [-1.0, 1.0]:
		for k in 3:
			var g := Vector2(side * (40 + k * 5), 0)
			draw_line(g, g + Vector2(0, -4 - k), Color(0.85, 0.8, 0.7), 1.2)
			DU.flat(self, DU.ellipse(g + Vector2(0, -5 - k), Vector2(3, 2), 10, PI, TAU), c)

func _door_gothic(c: Color, a: float) -> void:
	_veil("gothic", c, a)
	var stone := Color(0.3, 0.26, 0.38)
	var frame := PackedVector2Array([Vector2(-34, 0), Vector2(-34, -76)])
	for k in 11:
		frame.append(Vector2(34, -76) + Vector2.from_angle(PI + k * (PI / 3.0) / 10.0) * 68.0)
	for k in range(1, 11):
		frame.append(Vector2(-34, -76) + Vector2.from_angle(-PI / 3.0 + k * (PI / 3.0) / 10.0) * 68.0)
	frame.append(Vector2(34, 0))
	frame.append(Vector2(20, 0))
	for k in 11:
		frame.append(Vector2(-20, -76) + Vector2.from_angle(k * (PI / 3.0) / 10.0 * -1.0) * 40.0)
	for k in range(1, 11):
		frame.append(Vector2(20, -76) + Vector2.from_angle(PI + PI / 3.0 - k * (PI / 3.0) / 10.0) * 40.0)
	frame.append(Vector2(-20, 0))
	DU.poly(self, frame, stone)
	for side: float in [-1.0, 1.0]:
		for k in range(1, 5):
			draw_line(Vector2(side * 20, -k * 16.0), Vector2(side * 34, -k * 16.0), stone.darkened(0.5), 1.2)
		# colonnette
		draw_line(Vector2(side * 37, 0), Vector2(side * 37, -80), stone.darkened(0.3), 4.0)
		draw_line(Vector2(side * 36.4, 0), Vector2(side * 36.4, -80), DU.lit(stone, 1.4, 0.05), 1.2)
		DU.box(self, Rect2(side * 37 - 4, -84, 8, 4), stone.lightened(0.1))
	# rosace au-dessus, vitrail qui luit
	var rc := Vector2(0, -128)
	DU.ball(self, rc, 11.0, stone)
	DU.glow(self, rc, 16.0, c, 0.5 + a)
	draw_circle(rc, 7.5, Color(c.darkened(0.2), 0.9))
	for k in 6:
		draw_line(rc, rc + Vector2.from_angle(k * PI / 3.0 + 0.3) * 7.5, stone.darkened(0.3), 1.2)
	draw_arc(rc, 4.0, 0.0, TAU, 12, stone.darkened(0.3), 1.0)
	# gouttes d'eau qui tombent du haut
	for k in 2:
		var dy := fposmod(t * 40.0 + k * 33.0, 70.0)
		draw_circle(Vector2(-16 + k * 32, -100 + dy), 1.5, Color(0.7, 0.85, 1.0, 1.0 - dy / 70.0))
	_steps(stone)

func _door_crystal(c: Color, a: float) -> void:
	# étais de mine en bois autour d'une ouverture de cristaux
	_veil("round", c, a)
	var wood := Color(0.42, 0.3, 0.2)
	for side: float in [-1.0, 1.0]:
		DU.box(self, Rect2(side * 30 - 5, -104, 10, 104), wood)
		for k in 3:
			draw_line(Vector2(side * 30 - 3, -20 - k * 30), Vector2(side * 30 + 2, -14 - k * 30), wood.darkened(0.45), 1.0)
	DU.box(self, Rect2(-42, -112, 84, 10), wood.lightened(0.05))
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(side * 30, -107), 1.6, Color(0.6, 0.6, 0.65))
	# grappes de cristaux sur le pourtour
	for k in 11:
		var ang := PI + k * PI / 10.0
		var base := Vector2(0, -80) + Vector2.from_angle(ang) * 22.0
		var dir := Vector2.from_angle(ang)
		var side_v := dir.orthogonal() * 3.6
		var hh := 9.0 + (k % 3) * 5.0
		DU.poly(self, PackedVector2Array([base - side_v, base - side_v + dir * hh * 0.8, base + dir * hh, base + side_v + dir * hh * 0.8, base + side_v]), c.darkened(0.25))
		draw_line(base + dir * 2.0, base + dir * hh * 0.85, Color(1, 1, 1, 0.55), 1.0)
	for side: float in [-1.0, 1.0]:
		for k in 3:
			var base := Vector2(side * 21, -16 - k * 22)
			var dir := Vector2(side, -0.4).normalized()
			DU.poly(self, PackedVector2Array([base, base + dir * 10.0 + Vector2(0, -3), base + dir * 13.0, base + Vector2(0, 5)]), c.darkened(0.3))
	# éclats qui scintillent
	for k in 4:
		var sp := Vector2(0, -80) + Vector2.from_angle(PI + 0.4 + k * 0.7) * 30.0
		var tw := absf(sin(t * 3.0 + k * 1.7))
		draw_line(sp - Vector2(3, 0) * tw, sp + Vector2(3, 0) * tw, Color(1, 1, 1, tw), 1.0)
		draw_line(sp - Vector2(0, 3) * tw, sp + Vector2(0, 3) * tw, Color(1, 1, 1, tw), 1.0)
	_steps(Color(0.25, 0.3, 0.34))

func _door_forge(c: Color, a: float) -> void:
	# porte de fonte rivetée, linteau massif, braises
	DU.glow(self, Vector2(0, -50), 85.0, c, a * 0.9)
	var iron := Color(0.25, 0.23, 0.24)
	_veil("rect", c, a)
	for side: float in [-1.0, 1.0]:
		DU.box(self, Rect2(side * 27 - 7, -100, 14, 100), iron)
		for k in 6:
			DU.ball(self, Vector2(side * 27, -10 - k * 16), 1.8, iron.lightened(0.3))
	DU.box(self, Rect2(-40, -112, 80, 14), iron.lightened(0.05))
	for k in 7:
		DU.ball(self, Vector2(-33 + k * 11, -105), 1.8, iron.lightened(0.3))
	# grille d'aération rougeoyante sur le linteau
	for k in 3:
		draw_line(Vector2(-9 + k * 9, -110), Vector2(-9 + k * 9, -101), Color(1.0, 0.45, 0.15, 0.6 + a), 2.0)
	DU.glow(self, Vector2(0, -106), 14.0, c, 0.5)
	# chaînes et braises qui montent
	for side: float in [-1.0, 1.0]:
		for k in 4:
			draw_arc(Vector2(side * 44, -96 + k * 8), 3.0, 0.0, TAU, 8, iron.lightened(0.15), 1.6)
	for k in 6:
		var u := fposmod(t * 0.5 + k / 6.0, 1.0)
		draw_circle(Vector2(sin(k * 1.9 + t) * 30.0, -10 - u * 110.0), 1.5 * (1.0 - u) + 0.5, Color(1.0, 0.6, 0.2, 1.0 - u))
	DU.box(self, Rect2(-40, -5, 80, 5), Color(0.18, 0.14, 0.13))

func _door_books(c: Color, a: float) -> void:
	_veil("round", c, a)
	var cols := [Color(0.5, 0.2, 0.18), Color(0.25, 0.32, 0.45), Color(0.35, 0.42, 0.25), Color(0.55, 0.45, 0.25), Color(0.4, 0.25, 0.38)]
	# deux piles de livres en guise de jambages
	for side: float in [-1.0, 1.0]:
		var y := 0.0
		var i := 0
		while y < 92.0:
			var h := 7.0 + (i * 3 % 4)
			var w := 14.0 + ((i * 7) % 5)
			var off := side * (27.0 + ((i * 5) % 3) - 1.0)
			var col: Color = cols[(i + (2 if side > 0 else 0)) % cols.size()]
			DU.box(self, Rect2(off - w / 2.0, -y - h, w, h), col)
			draw_line(Vector2(off - w / 2.0 + 1, -y - h * 0.5), Vector2(off + w / 2.0 - 1, -y - h * 0.5), Color(0.9, 0.82, 0.55, 0.7), 0.8)
			y += h
			i += 1
	# grand livre ouvert en guise de linteau
	var bk := Vector2(0, -100)
	DU.poly(self, PackedVector2Array([bk + Vector2(-40, 4), bk + Vector2(-38, -8), bk + Vector2(0, -4), bk + Vector2(38, -8), bk + Vector2(40, 4), bk + Vector2(0, 8)]), Color(0.45, 0.2, 0.16))
	DU.poly(self, PackedVector2Array([bk + Vector2(-36, 1), bk + Vector2(-34, -9), bk + Vector2(0, -6), bk + Vector2(0, 5)]), Color(0.93, 0.88, 0.72))
	DU.poly(self, PackedVector2Array([bk + Vector2(0, -6), bk + Vector2(34, -9), bk + Vector2(36, 1), bk + Vector2(0, 5)]), Color(0.9, 0.85, 0.7))
	for k in 4:
		draw_line(bk + Vector2(-30, -5 + k * 2.5), bk + Vector2(-6, -3 + k * 2.5), Color(0.4, 0.35, 0.3, 0.6), 0.8)
		draw_line(bk + Vector2(6, -3 + k * 2.5), bk + Vector2(30, -5 + k * 2.5), Color(0.4, 0.35, 0.3, 0.6), 0.8)
	DU.glow(self, bk, 30.0, c, 0.4)
	# pages qui volettent
	for k in 3:
		var u := fposmod(t * 0.25 + k / 3.0, 1.0)
		var pp := Vector2(sin(t * 1.3 + k * 2.0) * 34.0, -110 - u * 50.0)
		var flap := sin(t * 6.0 + k) * 3.0
		DU.flat(self, PackedVector2Array([pp, pp + Vector2(6, flap), pp + Vector2(6, 5 + flap), pp + Vector2(0, 5)]), Color(0.95, 0.9, 0.75, 1.0 - u))

func _door_ice(c: Color, a: float) -> void:
	_veil("round", c, a)
	var ice := Color(0.42, 0.56, 0.72)
	_arch_frame(ice, false)
	for k in range(1, 8):
		var ang := PI + k * PI / 8.0
		draw_line(Vector2(0, -80) + Vector2.from_angle(ang) * 21.0, Vector2(0, -80) + Vector2.from_angle(ang + 0.15) * 32.0, Color(1, 1, 1, 0.4), 1.0)
	for side: float in [-1.0, 1.0]:
		draw_line(Vector2(side * 27, -4), Vector2(side * 25, -70), Color(1, 1, 1, 0.35), 1.4)
	# stalactites de glace sous l'arche et sur le pourtour
	for k in 7:
		var ang := PI + 0.35 + k * 0.4
		var base := Vector2(0, -80) + Vector2.from_angle(ang) * 21.0
		var l := 6.0 + (k % 3) * 4.0
		DU.poly(self, PackedVector2Array([base + Vector2(-2.5, 0), base + Vector2(2.5, 0), base + Vector2(0, l)]), ice.lightened(0.2), false)
	# couronne de neige et pics de givre
	DU.flat(self, DU.ellipse(Vector2(0, -111), Vector2(24, 5), 20, PI, TAU), Color(0.85, 0.93, 1.0))
	for k in 5:
		var ang := PI * 1.15 + k * 0.17
		var base := Vector2(0, -80) + Vector2.from_angle(ang) * 33.0
		DU.poly(self, PackedVector2Array([base + Vector2.from_angle(ang + 1.5) * 3.0, base + Vector2.from_angle(ang) * 11.0, base + Vector2.from_angle(ang - 1.5) * 3.0]), ice.lightened(0.15), false)
	_steps(Color(0.82, 0.9, 0.98))
	for k in 5:
		var u := fposmod(t * 0.2 + k / 5.0, 1.0)
		draw_circle(Vector2(sin(k * 2.7) * 40.0 + sin(t + k) * 4.0, -130 + u * 130.0), 1.3, Color(1, 1, 1, 0.8 * sin(u * PI)))

func _door_hive(c: Color, a: float) -> void:
	_veil("hex", c, a)
	var wax := Color(0.78, 0.55, 0.18)
	# anneau d'alvéoles autour de l'ouverture hexagonale
	for k in 18:
		var ang := k * TAU / 18.0
		var cc := Vector2(0, -48) + Vector2(cos(ang) * 40.0, sin(ang) * 56.0)
		if cc.y > -2.0:
			continue
		var hexp := PackedVector2Array()
		for j in 6:
			hexp.append(cc + Vector2.from_angle(PI / 6.0 + j * PI / 3.0) * 8.5)
		DU.poly(self, hexp, wax.lightened(0.05 * (k % 3)))
		draw_circle(cc, 3.6, wax.darkened(0.45) if k % 4 != 0 else Color(1.0, 0.75, 0.25))
	# miel qui coule du haut
	for k in 3:
		var dx := -14.0 + k * 14.0
		var l := 8.0 + fposmod(t * 5.0 + k * 4.0, 14.0)
		draw_line(Vector2(dx, -96), Vector2(dx, -96 + l), Color(1.0, 0.72, 0.18), 2.4)
		draw_circle(Vector2(dx, -96 + l + 1.5), 2.4, Color(1.0, 0.78, 0.25))
	# deux abeilles qui tournent
	for k in 2:
		var ang := t * 2.0 + k * PI
		var bp := Vector2(0, -60) + Vector2(cos(ang) * 46.0, sin(ang) * 30.0)
		DU.ball(self, bp, 2.8, Color(1.0, 0.8, 0.2))
		draw_line(bp + Vector2(-1, -2.5), bp + Vector2(-1, 2.5), Color(0.1, 0.08, 0.05), 1.0)
		draw_circle(bp + Vector2(0, -3), 2.0, Color(1, 1, 1, 0.5))
	DU.box(self, Rect2(-38, -5, 76, 5), wax.darkened(0.3))

func _door_bones(c: Color, a: float) -> void:
	_veil("round", c, a)
	var bone := Color(0.84, 0.81, 0.72)
	# jambages en vertèbres empilées
	for side: float in [-1.0, 1.0]:
		for k in 8:
			var vc := Vector2(side * 27, -6 - k * 11)
			DU.poly(self, DU.ellipse(vc, Vector2(7, 4.6), 14), bone.darkened(0.04 * (k % 2)))
			draw_line(vc + Vector2(-side * 7, 0), vc + Vector2(-side * 10, -2), bone.darkened(0.2), 2.0)
	# arche de côtes et rangée de crânes
	for k in 9:
		var ang := PI + k * PI / 8.0
		var cc := Vector2(0, -80) + Vector2.from_angle(ang) * 27.0
		if k % 2 == 0:
			DU.poly(self, DU.ellipse(cc, Vector2(6.5, 6), 14), bone)
			DU.box(self, Rect2(cc + Vector2(-4, 3), Vector2(8, 3.5)), bone.darkened(0.08))
			for e in [-1.0, 1.0]:
				draw_circle(cc + Vector2(e * 2.4, 0), 1.7, Color(0.08, 0.07, 0.06))
				draw_circle(cc + Vector2(e * 2.4, 0), 0.8, Color(c, 0.6 + a))
		else:
			draw_line(cc + Vector2.from_angle(ang) * -5.0, cc + Vector2.from_angle(ang) * 6.0, bone, 3.4)
	# flammes pâles aux sommets des jambages
	for side: float in [-1.0, 1.0]:
		var fp := Vector2(side * 40, -90)
		draw_line(Vector2(side * 40, -60), fp, bone.darkened(0.3), 2.0)
		var fl := 1.0 + 0.25 * sin(t * 9.0 + side)
		DU.glow(self, fp + Vector2(0, -6), 14.0, c, 0.6)
		DU.flat(self, DU.ellipse(fp + Vector2(0, -6), Vector2(3, 6 * fl)), Color(c, 0.9))
		DU.flat(self, DU.ellipse(fp + Vector2(0, -4), Vector2(1.4, 3 * fl)), Color(1, 1, 1, 0.9))
	DU.box(self, Rect2(-38, -5, 76, 5), Color(0.3, 0.28, 0.26))
	_bone_pile(Vector2(-44, 0))
	_bone_pile(Vector2(44, 0))

func _bone_pile(p: Vector2) -> void:
	var bone := Color(0.84, 0.81, 0.72)
	draw_line(p + Vector2(-6, -2), p + Vector2(6, -4), bone, 2.2)
	DU.ball(self, p + Vector2(0, -7), 4.5, bone)
	draw_circle(p + Vector2(-1.5, -7), 1.1, Color(0.08, 0.07, 0.06))
	draw_circle(p + Vector2(1.5, -7), 1.1, Color(0.08, 0.07, 0.06))

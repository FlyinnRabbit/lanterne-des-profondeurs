# Icônes des emblèmes : un médaillon de laiton gravé et un dessin propre à chaque emblème.
# Servent dans l'inventaire, chez le marchand et pour l'emblème qui flotte dans les niveaux.

const DU = preload("res://scripts/draw_util.gd")

# médaillon + icône ; r = rayon du médaillon, t = temps (petites animations)
static func draw(ci: CanvasItem, c: Vector2, r: float, id: int, col: Color, equipped := false, t := 0.0) -> void:
	var brass := Color(0.72, 0.58, 0.32)
	if equipped:
		DU.glow(ci, c, r * 1.8, col, 0.5)
	ci.draw_circle(c, r + 1.5, Color(0.08, 0.06, 0.05))
	ci.draw_circle(c, r, brass.darkened(0.35))
	ci.draw_arc(c, r - 1.2, PI * 1.05, PI * 1.7, 16, DU.lit(brass, 1.4, 0.08), 2.0)
	# petites encoches gravées sur le pourtour
	for k in 12:
		var a := k * TAU / 12.0
		ci.draw_line(c + Vector2.from_angle(a) * (r - 3.0), c + Vector2.from_angle(a) * (r - 1.0), brass.darkened(0.6), 1.0)
	var inner := r * 0.8
	ci.draw_circle(c, inner, col.darkened(0.78))
	for k in 6:
		var kk := 1.0 - k / 6.0
		ci.draw_circle(c + Vector2(0, -inner * 0.15 * (1.0 - kk)), inner * kk, Color(col.darkened(0.55), 0.18))
	ci.draw_arc(c, inner, 0.0, TAU, 32, brass.darkened(0.55), 1.2)
	glyph(ci, c, inner / 18.0, id, col, t)
	# reflet sur le verre
	ci.draw_arc(c, inner * 0.82, PI * 1.15, PI * 1.45, 10, Color(1, 1, 1, 0.35), 1.6)

# emplacement verrouillé
static func draw_locked(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c, r + 1.5, Color(0.05, 0.05, 0.07))
	ci.draw_circle(c, r, Color(0.16, 0.17, 0.22))
	ci.draw_circle(c, r * 0.8, Color(0.09, 0.1, 0.13))
	ci.draw_arc(c, r * 0.8, 0.0, TAU, 32, Color(0.25, 0.26, 0.32), 1.2)
	ci.draw_string(ThemeDB.fallback_font, c + Vector2(-5, 8) * (r / 22.0), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * r / 22.0), Color(0.4, 0.42, 0.5))

# le dessin de chaque emblème, centré en c, s = échelle (1 pour un médaillon de rayon ~22)
static func glyph(ci: CanvasItem, c: Vector2, s: float, id: int, col: Color, t := 0.0) -> void:
	var hi := col.lightened(0.35)
	var w := Color(1, 1, 1, 0.85)
	var P := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match id:
		0:   # Aiguille Longue : longue aiguille en travers
			DU.poly(ci, PackedVector2Array([P.call(-11, 8), P.call(13, -13), P.call(-8, 11)]), hi)
			ci.draw_line(P.call(-9, 9), P.call(12, -12), w, 1.0 * s)
			ci.draw_line(P.call(-13, 5), P.call(-5, 13), col.darkened(0.2), 2.4 * s)
			ci.draw_line(P.call(-11, 11), P.call(-15, 15), Color(0.55, 0.4, 0.25), 3.0 * s)
		1:   # Cœur de Verre : cœur à facettes
			var pts := PackedVector2Array()
			for k in 24:
				var a := k * TAU / 24.0
				var x := 16.0 * pow(sin(a), 3)
				var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
				pts.append(P.call(x * 0.72, y * 0.72 + 1.0))
			DU.poly(ci, pts, hi)
			ci.draw_line(P.call(0, -5), P.call(0, 11), Color(col.darkened(0.3), 0.8), 1.0 * s)
			ci.draw_line(P.call(-8, -6), P.call(0, 3), Color(col.darkened(0.3), 0.8), 1.0 * s)
			ci.draw_line(P.call(8, -6), P.call(0, 3), Color(col.darkened(0.3), 0.8), 1.0 * s)
			ci.draw_line(P.call(-7, -4), P.call(-4, -7), w, 1.4 * s)
		2:   # Cape Rapide : cape qui flotte et traînées de vitesse
			var f := sin(t * 4.0) * 1.5
			DU.poly(ci, PackedVector2Array([P.call(-2, -11), P.call(5, -11), P.call(9, 0), P.call(12, 10 + f), P.call(4, 7), P.call(-1, 11 - f), P.call(-4, 2)]), hi)
			for k in 3:
				ci.draw_line(P.call(-14, -5 + k * 6), P.call(-6, -5 + k * 6), Color(hi, 0.8 - k * 0.2), 1.6 * s)
			ci.draw_circle(P.call(2, -10), 2.0 * s, Color(0.85, 0.7, 0.35))
		3:   # Coquille Épineuse : coquille en spirale hérissée
			for k in 9:
				var a := PI * 0.9 + k * 0.2
				DU.flat(ci, PackedVector2Array([P.call(cos(a - 0.1) * 9.0, sin(a - 0.1) * 9.0), P.call(cos(a) * 15.0, sin(a) * 15.0), P.call(cos(a + 0.1) * 9.0, sin(a + 0.1) * 9.0)]), col.lightened(0.15))
			DU.poly(ci, DU.ellipse(c, Vector2(10, 10) * s, 20), hi)
			var sp := PackedVector2Array()
			for k in 24:
				var a := k * 0.42
				sp.append(P.call(cos(a) * (8.0 - k * 0.3), sin(a) * (8.0 - k * 0.3)))
			ci.draw_polyline(sp, col.darkened(0.35), 1.4 * s)
		4:   # Miroir Parfait : miroir à main et son éclat
			ci.draw_line(P.call(2, 6), P.call(9, 14), Color(0.6, 0.45, 0.28), 3.0 * s)
			DU.poly(ci, DU.ellipse(P.call(-2, -3), Vector2(9, 11) * s, 20), Color(0.75, 0.6, 0.32))
			ci.draw_colored_polygon(DU.ellipse(P.call(-2, -3), Vector2(7, 9) * s, 20), hi)
			ci.draw_line(P.call(-6, -6), P.call(1, -10), w, 1.6 * s)
			var tw := absf(sin(t * 3.0))
			ci.draw_line(P.call(7, -11) - Vector2(3, 0) * s * tw, P.call(7, -11) + Vector2(3, 0) * s * tw, w, 1.0)
			ci.draw_line(P.call(7, -11) - Vector2(0, 3) * s * tw, P.call(7, -11) + Vector2(0, 3) * s * tw, w, 1.0)
		5:   # Âme Vorace : volute d'âme à la gueule ouverte
			var wisp := PackedVector2Array()
			for k in 20:
				var u := k / 19.0
				wisp.append(P.call(sin(u * PI * 2.0 + t * 2.0) * 3.0 * u + 6.0 * u, -12.0 + u * 4.0 - (1.0 - u) * 2.0))
			ci.draw_polyline(wisp, Color(hi, 0.7), 2.0 * s)
			DU.poly(ci, DU.ellipse(P.call(0, 3), Vector2(10, 9) * s, 20), hi)
			ci.draw_colored_polygon(DU.ellipse(P.call(1, 6), Vector2(6, 3.5) * s, 14), col.darkened(0.75))
			for k in 4:
				ci.draw_colored_polygon(PackedVector2Array([P.call(-4 + k * 3, 3), P.call(-2.6 + k * 3, 3), P.call(-3.3 + k * 3, 5.5)]), w)
			ci.draw_circle(P.call(-4, -1), 1.4 * s, col.darkened(0.75))
			ci.draw_circle(P.call(5, -1), 1.4 * s, col.darkened(0.75))
		6:   # Concentration Vive : œil et anneau de concentration
			ci.draw_arc(c, 13.0 * s, t * 2.0, t * 2.0 + 4.5, 20, Color(hi, 0.8), 1.4 * s)
			var eye := PackedVector2Array()
			for k in 12:
				var u := k / 11.0
				eye.append(P.call(lerpf(-11, 11, u), -sin(u * PI) * 7.0))
			for k in range(10, 0, -1):
				var u := k / 11.0
				eye.append(P.call(lerpf(-11, 11, u), sin(u * PI) * 7.0))
			DU.poly(ci, eye, Color(0.95, 0.92, 0.85))
			ci.draw_circle(c, 5.0 * s, hi.darkened(0.2))
			ci.draw_circle(c, 2.4 * s, Color(0.05, 0.03, 0.05))
			ci.draw_circle(P.call(-1.5, -1.5), 1.0 * s, w)
		7:   # Force Brute : poing serré
			DU.poly(ci, PackedVector2Array([P.call(-9, -4), P.call(9, -4), P.call(10, 8), P.call(6, 12), P.call(-6, 12), P.call(-10, 8)]), hi)
			for k in 4:
				DU.ball(ci, P.call(-6.5 + k * 4.3, -5), 3.4 * s, hi.lightened(0.05))
				ci.draw_line(P.call(-4.4 + k * 4.3, -3), P.call(-4.4 + k * 4.3, 4), hi.darkened(0.35), 1.0 * s)
			DU.poly(ci, PackedVector2Array([P.call(-10, 2), P.call(-3, 0), P.call(2, 3), P.call(-8, 6)]), hi.darkened(0.12))
			ci.draw_line(P.call(-6, 12), P.call(-6, 15), Color(0.6, 0.45, 0.3), 3.0 * s)
			ci.draw_line(P.call(6, 12), P.call(6, 15), Color(0.6, 0.45, 0.3), 3.0 * s)
		8:   # Météore Ardent : boule de feu qui tombe
			for k in 3:
				var off := k * 3.0
				DU.flat(ci, PackedVector2Array([P.call(-14 + off, -14 + off * 0.3), P.call(1 - off * 0.2, -3), P.call(-4, 2 + off * 0.2)]), Color(1.0, 0.45 + k * 0.15, 0.15, 0.55 + k * 0.15))
			DU.glow(ci, P.call(4, 4), 10.0 * s, Color(1.0, 0.6, 0.2), 0.5)
			DU.ball(ci, P.call(4, 4), 6.5 * s, Color(1.0, 0.62, 0.25))
			ci.draw_circle(P.call(5, 5), 3.0 * s, Color(1.0, 0.92, 0.6))
		9:   # Repos de l'Ombre : croissant de lune au-dessus d'un banc
			ci.draw_circle(P.call(2, -6), 7.0 * s, hi)
			ci.draw_circle(P.call(5, -8), 6.0 * s, col.darkened(0.78))
			for k in 3:
				ci.draw_circle(P.call(-9 + k * 3, -12 + k * 2), 0.8 * s, w)
			ci.draw_line(P.call(-11, 6), P.call(11, 6), Color(0.6, 0.45, 0.3), 2.6 * s)
			ci.draw_line(P.call(-11, 2), P.call(11, 2), Color(0.6, 0.45, 0.3), 2.0 * s)
			ci.draw_line(P.call(-8, 2), P.call(-8, 12), Color(0.5, 0.5, 0.58), 1.8 * s)
			ci.draw_line(P.call(8, 2), P.call(8, 12), Color(0.5, 0.5, 0.58), 1.8 * s)
		10:  # Écho Parfait : lame entourée d'ondes
			for k in 3:
				var rr := 6.0 + k * 3.5 + fposmod(t * 6.0, 3.5)
				ci.draw_arc(c, rr * s, -0.7, 0.7, 10, Color(hi, 0.8 - k * 0.22), 1.4 * s)
				ci.draw_arc(c, rr * s, PI - 0.7, PI + 0.7, 10, Color(hi, 0.8 - k * 0.22), 1.4 * s)
			DU.poly(ci, PackedVector2Array([P.call(-2, 7), P.call(-1.6, -9), P.call(0, -13), P.call(1.6, -9), P.call(2, 7)]), Color(0.85, 0.88, 0.95))
			ci.draw_line(P.call(-5, 7), P.call(5, 7), Color(0.75, 0.6, 0.32), 2.2 * s)
			ci.draw_line(P.call(0, 7), P.call(0, 13), Color(0.55, 0.4, 0.25), 2.4 * s)
		11:  # Pas Léger : plume au-dessus d'une empreinte
			var foot := Color(hi, 0.55)
			ci.draw_colored_polygon(DU.ellipse(P.call(-1, 9), Vector2(4.5, 3) * s, 12), foot)
			for k in 4:
				ci.draw_circle(P.call(-5 + k * 2.8, 4.5 - absf(k - 1.5) * 0.6), 1.2 * s, foot)
			var q := PackedVector2Array()
			for k in 10:
				var u := k / 9.0
				q.append(P.call(-9 + u * 18.0, 2.0 - sin(u * PI) * 6.0 - u * 10.0))
			ci.draw_polyline(q, hi, 1.4 * s)
			for k in range(1, 9):
				var b2: Vector2 = q[k]
				ci.draw_line(b2, b2 + Vector2(-2.5, -4.0 + k * 0.2) * s, hi, 1.4 * s)
				ci.draw_line(b2, b2 + Vector2(2.5, 3.0 - k * 0.2) * s, Color(hi, 0.7), 1.2 * s)
		12:  # Lame Rebond : lame pointée vers le bas, flèche de rebond
			DU.poly(ci, PackedVector2Array([P.call(-2.5, -6), P.call(2.5, -6), P.call(1.5, 8), P.call(0, 13), P.call(-1.5, 8)]), Color(0.85, 0.9, 0.98))
			ci.draw_line(P.call(-6, -6), P.call(6, -6), Color(0.75, 0.6, 0.32), 2.4 * s)
			ci.draw_line(P.call(0, -6), P.call(0, -12), Color(0.55, 0.4, 0.25), 2.4 * s)
			var arc := PackedVector2Array()
			var bump := absf(sin(t * 3.0)) * 2.0
			for k in 12:
				var u := k / 11.0
				arc.append(P.call(lerpf(5, 13, u), 10.0 - sin(u * PI) * (14.0 + bump)))
			ci.draw_polyline(arc, hi, 1.8 * s)
			DU.flat(ci, PackedVector2Array([P.call(13, 10), P.call(10.5, 6), P.call(15, 6.5)]), hi)
		13:  # Enclume Tombante : enclume et lignes de chute
			for k in 3:
				ci.draw_line(P.call(-8 + k * 8, -14), P.call(-8 + k * 8, -8), Color(hi, 0.6), 1.4 * s)
			DU.poly(ci, PackedVector2Array([P.call(-13, -5), P.call(9, -5), P.call(13, -2), P.call(6, 0), P.call(4, 5), P.call(-6, 5), P.call(-8, 0), P.call(-13, -1)]), hi)
			DU.poly(ci, PackedVector2Array([P.call(-8, 5), P.call(6, 5), P.call(9, 10), P.call(-11, 10)]), col.darkened(0.25))
			ci.draw_line(P.call(-12, -4.5), P.call(8, -4.5), w, 1.2 * s)
			for k in 2:
				ci.draw_line(P.call(-14 + k * 26, 12), P.call(-17 + k * 32, 14), Color(1.0, 0.8, 0.4, 0.8), 1.4 * s)
		14:  # Parade Tranchante : petit bouclier et lame qui riposte
			DU.poly(ci, PackedVector2Array([P.call(-11, -9), P.call(-1, -9), P.call(-1, 1), P.call(-6, 8), P.call(-11, 1)]), Color(0.7, 0.55, 0.32))
			ci.draw_colored_polygon(PackedVector2Array([P.call(-9.5, -7.5), P.call(-2.5, -7.5), P.call(-2.5, 0.5), P.call(-6, 5.5), P.call(-9.5, 0.5)]), hi)
			DU.poly(ci, PackedVector2Array([P.call(0, 11), P.call(10, -10), P.call(12, -12), P.call(11, -8), P.call(2, 12)]), Color(0.88, 0.9, 0.98))
			ci.draw_line(P.call(-1, 8), P.call(5, 13), Color(0.75, 0.6, 0.32), 2.2 * s)
			var fl := absf(sin(t * 4.0))
			ci.draw_line(P.call(12, -13) - Vector2(3, 0) * s * fl, P.call(12, -13) + Vector2(3, 0) * s * fl, w, 1.0)
		15:  # Ruée Spectrale : silhouette fantôme et traînées
			for k in 3:
				ci.draw_line(P.call(-15, -6 + k * 6), P.call(-6, -6 + k * 6), Color(hi, 0.75 - k * 0.2), 1.6 * s)
			var gh := PackedVector2Array([P.call(-4, 10), P.call(-4, -3)])
			for k in 9:
				var a := PI + k * PI / 8.0
				gh.append(P.call(3 + cos(a) * 7.0, -3 + sin(a) * 7.0))
			gh.append_array(PackedVector2Array([P.call(10, 10), P.call(7, 7), P.call(4, 10), P.call(1, 7)]))
			DU.poly(ci, gh, Color(hi, 0.9))
			ci.draw_circle(P.call(0.5, -3), 1.4 * s, col.darkened(0.7))
			ci.draw_circle(P.call(5.5, -3), 1.4 * s, col.darkened(0.7))
		16:  # Récolte d'Âme : faucille et volute d'âme
			var blade := PackedVector2Array()
			for k in 14:
				var a := -PI * 0.95 + k * PI * 0.8 / 13.0
				blade.append(P.call(2 + cos(a) * 11.0, -2 + sin(a) * 11.0))
			for k in range(13, -1, -1):
				var a := -PI * 0.95 + k * PI * 0.8 / 13.0
				blade.append(P.call(2 + cos(a) * 7.5, 0 + sin(a) * 7.5))
			DU.poly(ci, blade, Color(0.85, 0.88, 0.95))
			ci.draw_line(P.call(-7, 1), P.call(5, 14), Color(0.55, 0.4, 0.25), 2.6 * s)
			var ws := PackedVector2Array()
			for k in 12:
				var u := k / 11.0
				ws.append(P.call(9 + sin(u * 5.0 + t * 3.0) * 2.0, 10 - u * 16.0))
			ci.draw_polyline(ws, Color(hi, 0.85), 2.0 * s)
			DU.glow(ci, P.call(9, -6), 5.0 * s, hi, 0.5)
		17:  # Flair du Pilleur : coffre ouvert et éclats
			DU.poly(ci, PackedVector2Array([P.call(-11, -1), P.call(11, -1), P.call(11, 10), P.call(-11, 10)]), Color(0.55, 0.36, 0.2))
			DU.poly(ci, PackedVector2Array([P.call(-11, -1), P.call(-9, -9), P.call(9, -9), P.call(11, -1)]), Color(0.45, 0.3, 0.17))
			ci.draw_line(P.call(-11, 3), P.call(11, 3), hi, 1.6 * s)
			ci.draw_rect(Rect2(P.call(-1.5, 1.5), Vector2(3, 4) * s), hi)
			for k in 3:
				var g: Vector2 = P.call(-5 + k * 5, -11 - (k % 2) * 3)
				DU.flat(ci, DU.diamond(g, Vector2(2.2, 3.2) * s), Color(0.7, 0.88, 1.0))
			var sp2 := absf(sin(t * 3.5))
			ci.draw_line(P.call(10, -13) - Vector2(2.5, 0) * s * sp2, P.call(10, -13) + Vector2(2.5, 0) * s * sp2, w, 1.0)
		18:  # Nœud de Grimpeur : corde nouée en boucle
			var rope := Color(0.75, 0.6, 0.38)
			ci.draw_arc(P.call(0, -4), 7.0 * s, 0.0, TAU, 20, rope, 3.0 * s)
			ci.draw_arc(P.call(0, -4), 7.0 * s, 0.4, 1.2, 6, hi, 1.2 * s)
			ci.draw_line(P.call(-3, 2), P.call(-6, 14), rope, 3.0 * s)
			ci.draw_line(P.call(3, 2), P.call(7, 14), rope, 3.0 * s)
			DU.ball(ci, P.call(0, 3), 3.4 * s, rope.lightened(0.1))
			for k in 4:
				ci.draw_line(P.call(-5.6 + k * 0.3, 6 + k * 2), P.call(-4.0 + k * 0.3, 7 + k * 2), rope.darkened(0.4), 1.0 * s)
		19:  # Dernier Souffle : masque fêlé et petite flamme
			DU.poly(ci, DU.ellipse(P.call(0, 1), Vector2(9, 11) * s, 20), Color(0.92, 0.9, 0.86))
			ci.draw_circle(P.call(-3.5, 0), 2.2 * s, Color(0.1, 0.06, 0.06))
			ci.draw_circle(P.call(3.5, 0), 2.2 * s, Color(0.1, 0.06, 0.06))
			ci.draw_polyline(PackedVector2Array([P.call(1, -10), P.call(-1, -5), P.call(2, -2), P.call(0, 4)]), Color(0.3, 0.2, 0.2), 1.2 * s)
			var fh := 1.0 + 0.15 * sin(t * 9.0)
			DU.glow(ci, P.call(0, -13), 6.0 * s, hi, 0.5)
			DU.flat(ci, PackedVector2Array([P.call(0, -13 - 6 * fh), P.call(3, -11), P.call(0, -9), P.call(-3, -11)]), hi)
		_:
			ci.draw_colored_polygon(DU.diamond(c, Vector2(8, 11) * s), hi)

# icônes des autres objets du marchand
static func draw_item(ci: CanvasItem, c: Vector2, r: float, kind: String) -> void:
	var brass := Color(0.72, 0.58, 0.32)
	ci.draw_circle(c, r + 1.5, Color(0.08, 0.06, 0.05))
	ci.draw_circle(c, r, brass.darkened(0.35))
	ci.draw_circle(c, r * 0.8, Color(0.08, 0.08, 0.12))
	var s := r / 22.0
	match kind:
		"hp":   # fragment de vie : losange blanc brisé
			ci.draw_colored_polygon(DU.diamond(c, Vector2(8, 11) * s), Color(0.95, 0.96, 1.0))
			ci.draw_line(c + Vector2(-3, -4) * s, c + Vector2(2, 3) * s, Color(0.3, 0.32, 0.4), 1.2 * s)
			DU.glow(ci, c, 14.0 * s, Color(0.8, 0.9, 1.0), 0.4)
		"notch":   # encoche : anneau doré
			ci.draw_arc(c, 8.0 * s, 0.0, TAU, 24, Color(1.0, 0.88, 0.55), 3.0 * s)
			ci.draw_circle(c, 4.0 * s, Color(1.0, 0.9, 0.6, 0.5))

# médaillon d'arme (arsenal)
static func draw_weapon(ci: CanvasItem, c: Vector2, r: float, id: String, t := 0.0) -> void:
	var brass := Color(0.72, 0.58, 0.32)
	ci.draw_circle(c, r + 1.5, Color(0.08, 0.06, 0.05))
	ci.draw_circle(c, r, brass.darkened(0.35))
	ci.draw_circle(c, r * 0.8, Color(0.1, 0.1, 0.15))
	var s := r / 22.0
	var P := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	match id:
		"fouet":
			ci.draw_arc(c, 8.0 * s, 0.0, TAU, 18, Color(0.3, 0.45, 0.22), 4.0 * s)
			ci.draw_arc(c, 8.0 * s, 0.0, TAU, 18, Color(0.55, 0.8, 0.42), 2.0 * s)
			ci.draw_arc(c, 4.0 * s, 0.0, TAU, 12, Color(0.55, 0.8, 0.42), 1.6 * s)
			for k in 6:
				var a := k * TAU / 6.0
				ci.draw_line(c + Vector2.from_angle(a) * 8.0 * s, c + Vector2.from_angle(a + 0.3) * 11.0 * s, Color(0.8, 0.9, 0.6), 1.2 * s)
		"marteau":
			ci.draw_line(P.call(-9, 11), P.call(5, -3), Color(0.3, 0.2, 0.12), 3.6 * s)
			ci.draw_line(P.call(-9, 11), P.call(5, -3), Color(0.58, 0.42, 0.27), 1.4 * s)
			DU.poly(ci, PackedVector2Array([P.call(0, -12), P.call(12, 0), P.call(7, 5), P.call(-5, -7)]), Color(0.6, 0.62, 0.7))
		"shuriken":
			for i in 4:
				var a := i * PI / 2.0 + t
				DU.flat(ci, PackedVector2Array([c, c + Vector2.from_angle(a - 0.35) * 5.0 * s, c + Vector2.from_angle(a) * 12.0 * s]), Color(0.82, 0.88, 0.98))
			ci.draw_circle(c, 2.4 * s, Color(0.3, 0.35, 0.45))
			DU.glow(ci, c, 12.0 * s, Color(0.7, 0.85, 1.0), 0.3)
		_:
			DU.flat(ci, PackedVector2Array([P.call(-9, 7), P.call(12, -12), P.call(-7, 9)]), Color(0.88, 0.92, 1.0))
			ci.draw_line(P.call(-12, 4), P.call(-4, 12), Color(0.85, 0.7, 0.35), 2.4 * s)
			ci.draw_line(P.call(-9, 9), P.call(-13, 13), Color(0.4, 0.28, 0.18), 3.0 * s)

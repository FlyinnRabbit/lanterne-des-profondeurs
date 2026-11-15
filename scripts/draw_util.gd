# Petites fonctions de dessin partagées (tout le jeu est dessiné en code, sans images).

static func ellipse(c: Vector2, r: Vector2, n: int = 24, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var full := (a1 - a0) >= TAU - 0.001
	for i in (n if full else n + 1):
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts

static func diamond(c: Vector2, r: Vector2) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0, -r.y), c + Vector2(r.x, 0), c + Vector2(0, r.y), c + Vector2(-r.x, 0)])

static func radial_texture(size: int = 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t

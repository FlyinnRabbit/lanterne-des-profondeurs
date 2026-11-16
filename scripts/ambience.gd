extends Node2D
# Ambiance animée propre à chaque biome :
#  - particules autour de la caméra (feuilles et spores, neige, pollen, lucioles, pages, feux follets) ;
#  - éléments fixés au décor : gouttes d'eau et ronds dans les flaques (Citadelle),
#    lave qui bouillonne sous les pics (Forge), cristaux qui éclairent vraiment (Mines).

const DU = preload("res://scripts/draw_util.gd")

var main
var biome := ""
var t := 0.0
var flakes := []      # [position relative à la vue, vitesse, phase, taille]
var drips := []       # [x, y du plafond, y du sol, phase]
var crystals := []    # positions des cristaux lumineux
var view := Rect2()

func _ready() -> void:
	z_index = 15
	biome = String(main.pal.get("id", ""))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(main.level.get("seed", 0)) + 99
	var n: int = {"jardins": 34, "glace": 70, "ruche": 30, "profondeurs": 22, "bibliotheque": 16, "ossuaire": 10, "cristal": 18, "citadelle": 14, "forge": 26, "hub": 14}.get(biome, 14)
	for i in n:
		flakes.append([Vector2(rng.randf_range(0, 1400), rng.randf_range(0, 800)), Vector2.ZERO, rng.randf_range(0, TAU), rng.randf_range(0.6, 1.4)])
	var T: int = main.TILE
	# plafonds (bas d'un bloc solide au-dessus du vide) et sols (haut d'un bloc sous le vide)
	var ceilings := []
	var floors := []
	for c in main.solid.keys():
		if not main.solid.has(Vector2i(c.x, c.y + 1)):
			ceilings.append(c)
		if not main.solid.has(Vector2i(c.x, c.y - 1)):
			floors.append(c)
	if biome == "citadelle" or biome == "glace" or biome == "profondeurs":
		ceilings.shuffle()
		for c in ceilings.slice(0, 40):
			var y := int(c.y) + 1
			while y < main.map_size.y and not main.solid.has(Vector2i(c.x, y)):
				y += 1
			if y - c.y > 2 and y < main.map_size.y:
				drips.append([c.x * T + 6 + rng.randf_range(0, 20), (c.y + 1) * T, y * T, rng.randf_range(0, 3.0)])
	if biome == "cristal":
		floors.shuffle()
		for c in floors.slice(0, 14):
			crystals.append(Vector2(c.x * T + 16, c.y * T))
			var l := PointLight2D.new()
			l.texture = main.light_tex
			l.color = Color(0.5, 0.95, 1.0)
			l.texture_scale = 1.4
			l.energy = 0.7
			l.position = Vector2(c.x * T + 16, c.y * T - 10)
			add_child(l)
	if biome == "ossuaire":
		pass

func _process(delta: float) -> void:
	t += delta
	var cam: Camera2D = main.camera
	if cam == null:
		return
	var vs := get_viewport_rect().size / cam.zoom
	view = Rect2(cam.get_screen_center_position() - vs / 2.0, vs)
	for f in flakes:
		var v := _drift(f)
		f[0] += v * delta
		f[2] += delta
		# les particules restent dans la vue (elles bouclent sur les bords)
		f[0].x = fposmod(f[0].x, view.size.x + 40.0)
		f[0].y = fposmod(f[0].y, view.size.y + 40.0)
	queue_redraw()

func _drift(f: Array) -> Vector2:
	var ph: float = f[2]
	match biome:
		"jardins": return Vector2(18.0 + sin(ph * 1.3) * 25.0, 26.0 + sin(ph * 2.0) * 10.0)
		"glace": return Vector2(sin(ph * 0.9) * 14.0 - 6.0, 34.0 * f[3])
		"ruche": return Vector2(sin(ph * 1.7) * 20.0, cos(ph * 1.3) * 14.0 - 4.0)
		"bibliotheque": return Vector2(10.0 + sin(ph) * 18.0, 16.0)
		"forge": return Vector2(sin(ph * 2.0) * 10.0, -40.0 * f[3])
		_: return Vector2(sin(ph * 0.8) * 12.0, cos(ph * 0.6) * 10.0 - 3.0)

func _draw() -> void:
	var o := view.position - Vector2(20, 20)
	# --- éléments fixés au décor
	for d in drips:
		var x: float = d[0]
		if x < view.position.x - 50 or x > view.end.x + 50:
			continue
		var fall: float = d[2] - d[1]
		var period := 1.6 + fposmod(float(d[3]) * 7.0, 1.4)
		var u := fposmod(t + float(d[3]), period) / period
		var drop_c := Color(0.75, 0.88, 1.0) if biome != "glace" else Color(0.9, 0.96, 1.0)
		if u < 0.35:
			# la goutte grossit au plafond
			draw_circle(Vector2(x, d[1] + 2.0), 1.0 + u * 5.0, Color(drop_c, 0.8))
		else:
			var k := (u - 0.35) / 0.65
			var y: float = d[1] + fall * k * k
			if k < 0.92:
				draw_line(Vector2(x, y - 6), Vector2(x, y), Color(drop_c, 0.5), 1.2)
				draw_circle(Vector2(x, y), 1.8, Color(drop_c, 0.9))
			else:
				# rond dans la flaque
				var rr := (k - 0.92) / 0.08
				draw_arc(Vector2(x, d[2] - 1.0), 2.0 + rr * 10.0, PI, TAU, 10, Color(drop_c, 0.6 * (1.0 - rr)), 1.2)
				draw_arc(Vector2(x, d[2] - 1.0), 1.0 + rr * 5.0, PI, TAU, 8, Color(drop_c, 0.6 * (1.0 - rr)), 1.0)
	if biome == "forge":
		# lave sous les pics : bouillonnement et lueur
		for s in main.spikes:
			if s.end.x < view.position.x - 40 or s.position.x > view.end.x + 40:
				continue
			var base: float = s.end.y
			DU.vgrad(self, Rect2(s.position.x - 3, base - 10, s.size.x + 6, 10), Color(1.0, 0.45, 0.1, 0.0), Color(1.0, 0.5, 0.15, 0.35 + 0.1 * sin(t * 3.0)))
			for i in 2:
				var bx: float = s.position.x + fposmod(t * 13.0 + i * 17.0 + s.position.x, s.size.x)
				var bu := fposmod(t * 0.9 + i * 0.5 + s.position.x * 0.01, 1.0)
				draw_circle(Vector2(bx, base - 2.0 - bu * 6.0), 2.0 * (1.0 - bu) + 0.5, Color(1.0, 0.8, 0.3, 1.0 - bu))
	for cp in crystals:
		if cp.x < view.position.x - 60 or cp.x > view.end.x + 60:
			continue
		var pulse := 0.5 + 0.5 * sin(t * 1.5 + cp.x * 0.05)
		DU.glow(self, cp + Vector2(0, -10), 26.0, Color(0.5, 0.95, 1.0), 0.25 + 0.15 * pulse)
		for i in 3:
			var a := -PI / 2.0 + (i - 1) * 0.45
			var dir := Vector2.from_angle(a)
			var side := dir.orthogonal() * 3.2
			var b: Vector2 = cp + Vector2((i - 1) * 5.0, 0)
			var hh := 14.0 - absf(i - 1) * 5.0
			DU.poly(self, PackedVector2Array([b - side, b - side + dir * hh * 0.8, b + dir * hh, b + side + dir * hh * 0.8, b + side]), Color(0.45, 0.85, 0.95))
			draw_line(b + dir * 2.0, b + dir * hh * 0.85, Color(1, 1, 1, 0.5 + 0.4 * pulse), 1.0)
	# --- particules autour de la caméra
	for f in flakes:
		var p: Vector2 = o + f[0]
		var ph: float = f[2]
		var sc: float = f[3]
		match biome:
			"jardins":
				# feuilles qui tournoient et spores
				if int(sc * 10.0) % 2 == 0:
					var a := ph * 2.0
					var leaf := PackedVector2Array([p + Vector2(-4, 0).rotated(a) * sc, p + Vector2(0, -2).rotated(a) * sc, p + Vector2(4, 0).rotated(a) * sc, p + Vector2(0, 2).rotated(a) * sc])
					draw_colored_polygon(leaf, Color(0.45, 0.7, 0.35, 0.8))
				else:
					DU.glow(self, p, 5.0 * sc, Color(0.7, 1.0, 0.6), 0.5)
					draw_circle(p, 1.2 * sc, Color(0.85, 1.0, 0.75, 0.9))
			"glace":
				draw_circle(p, 1.4 * sc, Color(1, 1, 1, 0.85))
			"ruche":
				draw_circle(p, 1.2 * sc, Color(1.0, 0.85, 0.35, 0.8))
			"bibliotheque":
				# pages qui volettent
				var flap := sin(ph * 5.0) * 2.0
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(6, flap) * sc, p + Vector2(6, 5 + flap) * sc, p + Vector2(0, 5) * sc]), Color(0.92, 0.87, 0.72, 0.75))
			"forge":
				draw_circle(p, 1.3 * sc, Color(1.0, 0.6, 0.2, 0.5 + 0.5 * sin(ph * 6.0)))
			"ossuaire":
				# feux follets
				DU.glow(self, p, 12.0 * sc, Color(0.7, 1.0, 0.8), 0.5)
				draw_circle(p, 2.0 * sc, Color(0.85, 1.0, 0.9, 0.9))
			"cristal":
				var tw := absf(sin(ph * 3.0))
				draw_line(p - Vector2(2.5, 0) * tw, p + Vector2(2.5, 0) * tw, Color(0.8, 1.0, 1.0, tw), 1.0)
				draw_line(p - Vector2(0, 2.5) * tw, p + Vector2(0, 2.5) * tw, Color(0.8, 1.0, 1.0, tw), 1.0)
			_:
				# lucioles
				var blink := 0.5 + 0.5 * sin(ph * 3.0)
				DU.glow(self, p, 8.0 * sc, Color(0.6, 0.85, 1.0), 0.4 * blink)
				draw_circle(p, 1.3 * sc, Color(0.85, 0.95, 1.0, blink))

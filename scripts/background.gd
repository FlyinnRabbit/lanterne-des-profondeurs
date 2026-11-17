extends Node2D
# Arrière-plan peint en parallaxe : ciel de caverne en dégradé, trois plans de décor
# propres au biome (brume de plus en plus dense avec la distance), rayons de lumière,
# bancs de brume et quelques silhouettes au premier plan.

const DU = preload("res://scripts/draw_util.gd")

var main
var layers := []   # [Node2D] avec .factor

class SkyGrad extends Node2D:
	var top := Color()
	var bottom := Color()
	var glow := Color()
	func _draw() -> void:
		DU.vgrad(self, Rect2(-3000, -2000, 6000, 4000), top, bottom)
		for i in 5:
			var k := 1.0 - i / 5.0
			DU.flat(self, DU.ellipse(Vector2(0, -420), Vector2(900, 520) * k, 40), Color(glow, 0.02))

class Layer extends Node2D:
	var factor := 0.5
	var kind := 0          # 0 lointain, 1 milieu, 2 proche, 3 premier plan
	var biome := ""
	var col := Color()
	var fog := Color()
	var light := Color()
	var accent := Color()
	var seed_v := 0
	var width := 0.0
	var height := 0.0
	var rng := RandomNumberGenerator.new()
	# Découpage en tranches horizontales : le plan lui-même ne dessine rien, ses tranches
	# (même classe) dessinent chacune les motifs de leur portion — Godot n'affiche que celles
	# qui sont à l'écran. Avant, tout le plan (largeur du niveau entière) partait à chaque image.
	const SEG := 1024.0
	var is_seg := false
	var lo := -INF
	var hi := INF

	func _ready() -> void:
		light_mask = 0          # les lumières 2D ne redessinent pas l'arrière-plan
		if is_seg:
			return
		var x0 := -2400.0
		while x0 < width + 2400.0:
			var sg := Layer.new()
			for k in ["factor", "kind", "biome", "col", "fog", "light", "accent", "seed_v", "width", "height"]:
				sg.set(k, get(k))
			sg.is_seg = true
			sg.lo = x0
			sg.hi = x0 + SEG
			add_child(sg)
			x0 += SEG

	func _in(x: float) -> bool:
		return x >= lo and x < hi

	# Écart entre deux motifs (suite à part : chaque tranche la rejoue sans rien dessiner)
	func _gap(prng: RandomNumberGenerator, s: float) -> float:
		match biome:
			"citadelle", "hub":
				return prng.randf_range(260.0, 420.0) * (0.7 + s)
			"bibliotheque":
				return prng.randf_range(160.0, 300.0) * (0.7 + s)
			"ruche":
				return prng.randf_range(200.0, 380.0) * (0.7 + s)
		return prng.randf_range(80.0, 280.0) * (0.8 + s)

	func _shade(y: float) -> Color:
		var k := clampf(y / maxf(height, 1.0), 0.0, 1.0)
		var top := col.lerp(light, 0.07 if kind < 3 else 0.0)
		var haze := 0.55 - kind * 0.15
		return top.lerp(col.lerp(fog, haze), k)

	func sil(pts: PackedVector2Array, rim := true) -> void:
		var cols := PackedColorArray()
		for p in pts:
			cols.append(_shade(p.y))
		draw_polygon(pts, cols)
		if rim and kind >= 1 and kind < 3:
			var rc := Color(light, 0.04 + 0.05 * kind)
			for i in pts.size():
				var a := pts[i]
				var b := pts[(i + 1) % pts.size()]
				var d := b - a
				if d.length_squared() < 1.0:
					continue
				var n := Vector2(d.y, -d.x).normalized()
				if n.y < -0.3 and n.x < 0.3 or n.x < -0.8:
					draw_line(a, b, rc, 1.5 + kind * 0.5)

	func _draw() -> void:
		if not is_seg:
			return
		rng.seed = seed_v
		if kind == 3:
			_foreground()
			return
		var prng := RandomNumberGenerator.new()
		prng.seed = seed_v * 31 + 7
		var s := 1.25 - factor
		var x := -2200.0
		var i := 0
		while x < width + 2200.0:
			if _in(x):
				rng.seed = seed_v * 1000003 + i * 7919      # chaque motif a sa propre graine
				_motif(x)
			x += _gap(prng, s)
			i += 1
		if int(Settings.gfx_quality) >= 1:
			return               # qualité équilibrée / basse : ni rayons de lumière ni bancs de brume
		if kind == 1:
			_shafts()
		if kind <= 1:
			# banc de brume au pied du plan (portion de la tranche)
			DU.vgrad(self, Rect2(lo, height * 0.55, hi - lo, height * 0.6), Color(fog, 0.0), Color(fog, 0.35 - kind * 0.1))

	func _shafts() -> void:
		rng.seed = seed_v * 17 + 3
		var x := -1500.0
		while x < width + 1500.0:
			x += rng.randf_range(380.0, 900.0)
			var w := rng.randf_range(60.0, 160.0)
			var sk := rng.randf_range(120.0, 320.0)
			var l := height * rng.randf_range(0.6, 1.0)
			if not _in(x):
				continue
			draw_polygon(PackedVector2Array([Vector2(x, -300), Vector2(x + w, -300), Vector2(x + w + sk, l), Vector2(x + sk, l)]),
				PackedColorArray([Color(light, 0.075), Color(light, 0.075), Color(light, 0.0), Color(light, 0.0)]))

	# ---------------------------------------------------------- motifs par biome
	func _motif(x: float) -> float:
		var s := 1.25 - factor          # plus grand quand proche
		var gap := rng.randf_range(80.0, 280.0) * (0.8 + s)
		match biome:
			"jardins":
				if rng.randf() < 0.55:
					_mushroom(x, s)
				else:
					_column(x, s)
			"citadelle", "hub":
				_arcade(x, s)
				return rng.randf_range(260.0, 420.0) * (0.7 + s)
			"cristal":
				_crystal(x, s)
			"forge":
				if rng.randf() < 0.3:
					_chain(x, s)
				else:
					_chimney(x, s)
			"bibliotheque":
				_shelf(x, s)
				return rng.randf_range(160.0, 300.0) * (0.7 + s)
			"glace":
				_ice(x, s)
			"ruche":
				_comb(x, s)
				return rng.randf_range(200.0, 380.0) * (0.7 + s)
			"ossuaire":
				if rng.randf() < 0.4:
					_ribs(x, s)
				else:
					_column(x, s)
			"jungle":
				_tree(x, s)
				return rng.randf_range(160.0, 320.0) * (0.7 + s)
			"desert":
				if rng.randf() < 0.3:
					_obelisk(x, s)
				else:
					_dune(x, s)
				return rng.randf_range(260.0, 460.0) * (0.7 + s)
			"antique":
				if rng.randf() < 0.25:
					_statue(x, s)
				else:
					_fluted(x, s)
				return rng.randf_range(200.0, 340.0) * (0.7 + s)
			_:
				_column(x, s)
		return gap

	func _column(x: float, s: float) -> void:
		var w := rng.randf_range(40.0, 130.0) * s
		var top := rng.randf_range(-200.0, height * 0.4)
		var bottom := height + 400.0
		var pts := PackedVector2Array([Vector2(x, bottom), Vector2(x + w * 0.1, top + 120), Vector2(x + w * 0.3, top + 30),
			Vector2(x + w * 0.5, top), Vector2(x + w * 0.72, top + 50), Vector2(x + w * 0.9, top + 140), Vector2(x + w, bottom)])
		sil(pts)
		# stalactite suspendue en vis-à-vis
		var sx := x + w + rng.randf_range(30.0, 160.0)
		var sl := rng.randf_range(80.0, 380.0)
		var sw := rng.randf_range(18.0, 40.0) * s
		sil(PackedVector2Array([Vector2(sx - sw, -400), Vector2(sx + sw, -400), Vector2(sx + sw * 0.3, sl * 0.6), Vector2(sx, sl)]))

	# arbre géant : tronc, branches, lianes qui pendent
	func _tree(x: float, s: float) -> void:
		var w := rng.randf_range(40.0, 90.0) * s
		var base := height + 400.0
		var bend := rng.randf_range(-40.0, 40.0)
		sil(PackedVector2Array([Vector2(x - w, base), Vector2(x - w * 0.6 + bend, height * 0.2), Vector2(x - w * 0.5 + bend, -400),
			Vector2(x + w * 0.5 + bend, -400), Vector2(x + w * 0.6 + bend, height * 0.2), Vector2(x + w, base)]))
		# racines contreforts
		sil(PackedVector2Array([Vector2(x - w * 2.2, base), Vector2(x - w * 0.6, height * 0.55), Vector2(x - w * 0.4, base)]))
		sil(PackedVector2Array([Vector2(x + w * 0.4, base), Vector2(x + w * 0.6, height * 0.6), Vector2(x + w * 2.0, base)]))
		for i in rng.randi_range(2, 4):
			var vx := x + rng.randf_range(-w * 3.0, w * 3.0)
			var vl := rng.randf_range(height * 0.2, height * 0.7)
			var pts := PackedVector2Array()
			for k in 9:
				var u := k / 8.0
				pts.append(Vector2(vx + sin(u * 4.0 + i) * 10.0 * s, -300.0 + (vl + 300.0) * u))
			draw_polyline(pts, Color(col, 1.0), 3.0 * s + 1.0)
			draw_circle(pts[8], 4.0 * s + 1.0, Color(col, 1.0))
			if rng.randf() < 0.5:
				DU.glow(self, pts[8] + Vector2(0, 6), 12.0 * s + 4.0, accent, 0.3)

	# dune : grande courbe de sable
	func _dune(x: float, s: float) -> void:
		var w := rng.randf_range(260.0, 520.0) * s
		var hh := rng.randf_range(height * 0.15, height * 0.4)
		var base := height + 300.0
		var pts := PackedVector2Array([Vector2(x - w, base)])
		for k in 13:
			var u := k / 12.0
			pts.append(Vector2(x - w + 2.0 * w * u, height - hh * pow(sin(u * PI), 0.8) * (1.0 + 0.15 * sin(u * 9.0))))
		pts.append(Vector2(x + w, base))
		sil(pts)

	# obélisque de grès
	func _obelisk(x: float, s: float) -> void:
		var w := rng.randf_range(26.0, 46.0) * s
		var top := rng.randf_range(height * 0.05, height * 0.35)
		var base := height + 300.0
		sil(PackedVector2Array([Vector2(x - w, base), Vector2(x - w * 0.7, top + w), Vector2(x, top), Vector2(x + w * 0.7, top + w), Vector2(x + w, base)]))
		for k in 3:
			draw_line(Vector2(x - w * 0.25, top + w * 2.0 + k * 40.0 * s), Vector2(x + w * 0.25, top + w * 2.0 + k * 40.0 * s), Color(accent, 0.2), 2.0)

	# colonne cannelée à chapiteau
	func _fluted(x: float, s: float) -> void:
		var w := rng.randf_range(26.0, 44.0) * s
		var top := rng.randf_range(-120.0, height * 0.3)
		var broken := rng.randf() < 0.35
		if broken:
			top = rng.randf_range(height * 0.35, height * 0.65)
		var base := height + 300.0
		sil(PackedVector2Array([Vector2(x - w, base), Vector2(x - w, top), Vector2(x + w, top), Vector2(x + w, base)]))
		if broken:
			sil(PackedVector2Array([Vector2(x - w, top + 2), Vector2(x - w * 0.3, top - 18.0 * s), Vector2(x + w * 0.2, top - 6.0 * s), Vector2(x + w, top - 24.0 * s), Vector2(x + w, top + 2)]))
		else:
			sil(PackedVector2Array([Vector2(x - w * 1.5, top), Vector2(x - w * 1.5, top - 14.0 * s), Vector2(x + w * 1.5, top - 14.0 * s), Vector2(x + w * 1.5, top)]))
			sil(PackedVector2Array([Vector2(x - w * 1.8, top - 14.0 * s), Vector2(x - w * 1.8, top - 26.0 * s), Vector2(x + w * 1.8, top - 26.0 * s), Vector2(x + w * 1.8, top - 14.0 * s)]))
		for k in 3:
			var fx := x - w * 0.5 + k * w * 0.5
			draw_line(Vector2(fx, top + 10), Vector2(fx, height + 200), Color(accent, 0.07), 2.0 * s + 1.0)

	# tête de statue colossale effondrée
	func _statue(x: float, s: float) -> void:
		var r := rng.randf_range(60.0, 110.0) * s
		var base := height + 300.0
		var c := Vector2(x, height - r * 0.4)
		sil(DU.ellipse(c, Vector2(r * 0.8, r)))
		sil(PackedVector2Array([Vector2(c.x - r * 1.2, base), Vector2(c.x - r * 0.9, c.y + r * 0.4), Vector2(c.x + r * 0.9, c.y + r * 0.4), Vector2(c.x + r * 1.2, base)]))
		draw_line(c + Vector2(-r * 0.4, -r * 0.15), c + Vector2(-r * 0.1, -r * 0.15), Color(accent, 0.18), 3.0)
		draw_line(c + Vector2(r * 0.1, -r * 0.15), c + Vector2(r * 0.4, -r * 0.15), Color(accent, 0.18), 3.0)

	func _mushroom(x: float, s: float) -> void:
		var hgt := rng.randf_range(height * 0.3, height * 0.8)
		var base := height + 300.0
		var top := base - hgt - 300.0
		var stw := rng.randf_range(14.0, 30.0) * s
		var bend := rng.randf_range(-60.0, 60.0)
		sil(PackedVector2Array([Vector2(x - stw, base), Vector2(x - stw * 0.7 + bend * 0.5, (base + top) / 2.0), Vector2(x - stw * 0.6 + bend, top),
			Vector2(x + stw * 0.6 + bend, top), Vector2(x + stw * 0.7 + bend * 0.5, (base + top) / 2.0), Vector2(x + stw, base)]), false)
		var cw := rng.randf_range(90.0, 200.0) * s
		var cap := DU.ellipse(Vector2(x + bend, top + 10), Vector2(cw, cw * 0.45), 28, PI, TAU)
		sil(cap)
		# points lumineux sous le chapeau
		for i in 5:
			var px := x + bend + rng.randf_range(-cw * 0.8, cw * 0.8)
			draw_circle(Vector2(px, top + 6), 2.5 * s + 1.0, Color(accent, 0.3))
			DU.glow(self, Vector2(px, top + 6), 14.0 * s + 4.0, accent, 0.25)

	func _arcade(x: float, s: float) -> void:
		var w := rng.randf_range(40.0, 70.0) * s
		var span := rng.randf_range(160.0, 300.0) * s
		var top := rng.randf_range(height * 0.05, height * 0.35)
		var bottom := height + 400.0
		for cx in [x, x + span]:
			sil(PackedVector2Array([Vector2(cx - w * 0.5, bottom), Vector2(cx - w * 0.5, top), Vector2(cx - w * 0.7, top - 14), Vector2(cx + w * 0.7, top - 14), Vector2(cx + w * 0.5, top), Vector2(cx + w * 0.5, bottom)]))
		# arc brisé entre les deux colonnes
		var pts := PackedVector2Array()
		var l := x + w * 0.5
		var r := x + span - w * 0.5
		var mid := (l + r) / 2.0
		var rise := (r - l) * 0.75
		pts.append(Vector2(l, top - 14))
		for i in 9:
			var k := i / 8.0
			pts.append(Vector2(lerpf(l, mid, k), top - sin(k * PI / 2.0) * rise))
		for i in 9:
			var k := i / 8.0
			pts.append(Vector2(lerpf(mid, r, k), top - cos(k * PI / 2.0) * rise))
		pts.append(Vector2(r, top - 14))
		pts.append(Vector2(r + w * 0.7, top - 14))
		pts.append(Vector2(r + w * 0.7, top - rise - 160))
		pts.append(Vector2(l - w * 0.7, top - rise - 160))
		pts.append(Vector2(l - w * 0.7, top - 14))
		sil(pts)
		# vitrail lointain qui luit
		if kind == 0 and rng.randf() < 0.6:
			var wc := Vector2(mid, top - rise * 0.35 + 40)
			DU.flat(self, DU.ellipse(wc, Vector2(18, 34) * s, 18, PI, TAU), Color(accent, 0.22))
			draw_rect(Rect2(wc - Vector2(18, 0) * s, Vector2(36, 50) * s), Color(accent, 0.22))
			DU.glow(self, wc + Vector2(0, 14), 80.0 * s, accent, 0.2)

	func _crystal(x: float, s: float) -> void:
		var bottom := height + 400.0
		var n := rng.randi_range(1, 3)
		for i in n:
			var w := rng.randf_range(30.0, 80.0) * s
			var hgt := rng.randf_range(height * 0.3, height * 0.9)
			var lean := rng.randf_range(-0.35, 0.35)
			var cx := x + i * w * 0.9
			var tip := Vector2(cx + lean * hgt, bottom - hgt - 400)
			var pts := PackedVector2Array([Vector2(cx - w, bottom), Vector2(cx - w + lean * hgt * 0.8, tip.y + w * 1.6), tip, Vector2(cx + w + lean * hgt * 0.8, tip.y + w * 1.6), Vector2(cx + w, bottom)])
			sil(pts)
			draw_line(tip, Vector2(cx, bottom), Color(accent, 0.12 + kind * 0.04), 2.0)
			DU.glow(self, tip + Vector2(0, w), w * 1.8, accent, 0.12)
		# grappe suspendue
		var sx := x + rng.randf_range(60.0, 200.0)
		var sl := rng.randf_range(100.0, 300.0)
		sil(PackedVector2Array([Vector2(sx - 24 * s, -400), Vector2(sx + 24 * s, -400), Vector2(sx + 8 * s, sl - 30), Vector2(sx, sl)]))

	func _chimney(x: float, s: float) -> void:
		var w := rng.randf_range(50.0, 120.0) * s
		var top := rng.randf_range(height * 0.1, height * 0.5)
		var bottom := height + 400.0
		sil(PackedVector2Array([Vector2(x, bottom), Vector2(x + w * 0.15, top), Vector2(x - w * 0.05, top - 20), Vector2(x + w * 1.05, top - 20), Vector2(x + w * 0.85, top), Vector2(x + w, bottom)]))
		# lueur de braise au sommet
		DU.glow(self, Vector2(x + w * 0.5, top - 26), w * 1.3, accent, 0.3)

	func _chain(x: float, s: float) -> void:
		var l := rng.randf_range(height * 0.2, height * 0.7)
		var c := _shade(l * 0.5)
		var y := -300.0
		while y < l:
			draw_arc(Vector2(x, y), 9.0 * s, 0.0, TAU, 10, c, 4.0 * s)
			y += 16.0 * s
		DU.poly(self, PackedVector2Array([Vector2(x - 6 * s, l), Vector2(x + 6 * s, l), Vector2(x + 14 * s, l + 26 * s), Vector2(x, l + 34 * s), Vector2(x - 14 * s, l + 26 * s)]), c, false)

	func _shelf(x: float, s: float) -> void:
		var w := rng.randf_range(110.0, 200.0) * s
		var top := rng.randf_range(-100.0, height * 0.3)
		var bottom := height + 400.0
		sil(PackedVector2Array([Vector2(x, bottom), Vector2(x, top), Vector2(x - 10, top - 16), Vector2(x + w + 10, top - 16), Vector2(x + w, top), Vector2(x + w, bottom)]))
		var y := top + 20.0
		var shelf := _shade(height * 0.2).lightened(0.03)
		var dark := _shade(height * 0.2).darkened(0.45)
		while y < height:
			var hh := 46.0 * s
			draw_rect(Rect2(x + 8, y, w - 16, hh), dark)
			var bx := x + 10.0
			while bx < x + w - 14:
				var bw := rng.randf_range(4.0, 10.0) * s
				var bh := hh * rng.randf_range(0.6, 0.95)
				draw_rect(Rect2(bx, y + hh - bh, bw - 1, bh), shelf.darkened(rng.randf_range(0.0, 0.3)).lerp(Color(accent, 1.0), rng.randf_range(0.0, 0.06)))
				bx += bw
			draw_rect(Rect2(x + 4, y + hh, w - 8, 6 * s), shelf)
			y += hh + 6.0 * s
		# échelle appuyée
		if rng.randf() < 0.25:
			var lx := x + w * 0.7
			var c := shelf.lightened(0.1)
			draw_line(Vector2(lx, height), Vector2(lx + 50, top + 60), c, 3.0)
			draw_line(Vector2(lx + 22, height), Vector2(lx + 72, top + 60), c, 3.0)

	func _ice(x: float, s: float) -> void:
		var bottom := height + 400.0
		var w := rng.randf_range(40.0, 110.0) * s
		var hgt := rng.randf_range(height * 0.4, height * 1.1)
		var pts := PackedVector2Array([Vector2(x, bottom), Vector2(x + w * 0.2, bottom - hgt * 0.6), Vector2(x + w * 0.35, bottom - hgt), Vector2(x + w * 0.55, bottom - hgt * 0.75), Vector2(x + w * 0.7, bottom - hgt * 0.9), Vector2(x + w, bottom)])
		sil(pts)
		draw_line(pts[2], Vector2(x + w * 0.45, bottom), Color(1, 1, 1, 0.08 + 0.03 * kind), 2.0)
		var sx := x + w + rng.randf_range(40.0, 140.0)
		var sl := rng.randf_range(120.0, 420.0)
		sil(PackedVector2Array([Vector2(sx - 22 * s, -400), Vector2(sx + 22 * s, -400), Vector2(sx, sl)]))

	func _comb(x: float, s: float) -> void:
		var r := rng.randf_range(16.0, 26.0) * s
		var top := rng.randf_range(-100.0, height * 0.4)
		var cols := rng.randi_range(3, 6)
		var bottom := height + 400.0
		var w := cols * r * 1.732
		sil(PackedVector2Array([Vector2(x - r, bottom), Vector2(x - r, top), Vector2(x + w * 0.5, top - r * 2.0), Vector2(x + w + r, top), Vector2(x + w + r, bottom)]), true)
		var dark := _shade(height * 0.3).darkened(0.5)
		var y := top + r
		var row := 0
		while y < height:
			for i in cols:
				var c := Vector2(x + i * r * 1.732 + (row % 2) * r * 0.866, y)
				var hex := PackedVector2Array()
				for k in 6:
					hex.append(c + Vector2.from_angle(PI / 6.0 + k * PI / 3.0) * r * 0.86)
				DU.flat(self, hex, dark)
				if rng.randf() < 0.12:
					DU.flat(self, hex, Color(accent, 0.1))
			y += r * 1.5
			row += 1

	func _ribs(x: float, s: float) -> void:
		var bottom := height + 300.0
		var sp := rng.randf_range(120.0, 220.0) * s
		var c := _shade(height * 0.4)
		# colonne vertébrale
		var top := rng.randf_range(height * 0.1, height * 0.4)
		for i in 7:
			var k := i / 6.0
			var rx := x + k * sp * 2.0
			var rt := top + sin(k * PI) * -60.0
			draw_polyline(PackedVector2Array([Vector2(rx, bottom), Vector2(rx - 10 * s, (bottom + rt) / 2.0), Vector2(rx + 20 * s, rt), Vector2(rx + 60 * s, rt + 30 * s)]), c, 10.0 * s)
		draw_line(Vector2(x - 20, top - 10), Vector2(x + sp * 2.0 + 40, top - 10), c, 14.0 * s)

	func _foreground() -> void:
		var c := Color(0.0, 0.0, 0.0, 0.92)
		var x := -1500.0
		while x < width + 1500.0:
			x += rng.randf_range(500.0, 1100.0)
			var w := rng.randf_range(80.0, 200.0)
			var low := rng.randf() < 0.5
			var l := rng.randf_range(80.0, 200.0)
			if not _in(x):
				continue
			if low:
				# roche au ras du sol, en bas de l'écran
				var b := height + 200.0
				DU.flat(self, PackedVector2Array([Vector2(x, b), Vector2(x + w * 0.2, height - 10), Vector2(x + w * 0.5, height - 60), Vector2(x + w * 0.8, height - 20), Vector2(x + w, b)]), c)
			else:
				# racines ou stalactite qui pendent du haut
				DU.flat(self, PackedVector2Array([Vector2(x, -300), Vector2(x + w * 0.5, -300), Vector2(x + w * 0.3, l * 0.5), Vector2(x + w * 0.2, l)]), c)

func _ready() -> void:
	z_index = -10
	var w: float = main.map_size.x * main.TILE
	var h: float = main.map_size.y * main.TILE
	var p: Dictionary = main.pal
	var sd: int = int(main.level.get("seed", 0))
	var biome := String(p.get("id", "profondeurs"))
	var light: Color = p.get("light", Color(1, 0.9, 0.7))
	var fog: Color = (p["bg"] as Color).lerp(p["ambient"], 0.14)
	var sky := SkyGrad.new()
	sky.top = (p["bg"] as Color).lerp(light, 0.03)
	sky.bottom = (p["bg"] as Color).lerp(fog, 0.5)
	sky.glow = light
	sky.z_index = -1
	add_child(sky)
	layers.append(sky)
	sky.set_meta("factor", 1.0)
	var specs := [[0.82, (p["far"] as Color).lerp(fog, 0.25), 7 + sd, 0], [0.62, (p["mid"] as Color).darkened(0.1), 13 + sd, 1], [0.38, (p["near"] as Color).darkened(0.3), 21 + sd, 2]]
	for i in specs.size():
		var l := Layer.new()
		l.factor = specs[i][0]
		l.col = specs[i][1]
		l.seed_v = specs[i][2]
		l.kind = specs[i][3]
		l.biome = biome
		l.fog = fog
		l.light = light
		l.accent = p["moss"]
		l.width = w
		l.height = h
		l.z_index = i
		l.set_meta("factor", l.factor)
		add_child(l)
		layers.append(l)

# Qualité graphique : en basse, seul le plan lointain reste ; brume et rayons sont redessinés.
func apply_quality() -> void:
	var q := int(Settings.gfx_quality)
	for l in layers:
		if l is Layer:
			l.visible = q < 2 or l.kind == 0
			for sg in l.get_children():
				sg.queue_redraw()

func _process(_delta: float) -> void:
	var cam: Camera2D = main.camera
	if cam == null:
		return
	var c := cam.get_screen_center_position()
	for l in layers:
		l.position = c * float(l.get_meta("factor"))

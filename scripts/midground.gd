extends Node2D
# Troisième plan : entre l'arrière-plan peint et le décor où marche le héros, quelques scènes
# propres au biome, posées sur une berge un peu en retrait (légère parallaxe) : étang des
# Profondeurs, marais des Jardins, fontaine sacrée de la Citadelle, rivière de métal des Mines,
# rivière de lave de la Forge, encre et pages de la Bibliothèque, cascade gelée des Abysses,
# rivière de miel de la Ruche, éboulis d'os de l'Ossuaire, rivière et cascade de la Jungle,
# sables mouvants du Désert, fontaine romaine du Temple.
# Purement visuel : ni collision, ni éclairage (comme l'arrière-plan).

const DU = preload("res://scripts/draw_util.gd")
const FACTOR := 0.14        # part du mouvement de la caméra suivie (0 : collé au décor)

var main
var biome := ""
var fog := Color()
var scenes := []            # nœuds Scene

class Scene extends Node2D:
	var kind := ""
	var w := 400.0          # largeur de la scène
	var sd := 0.0
	var t := 0.0
	var fog := Color()
	var pal := {}
	var _acc := 0.0

	func _process(delta: float) -> void:
		t += delta
		_acc += delta
		# animation à ~30 i/s, seulement à l'écran
		if _acc < 0.033:
			return
		_acc = 0.0
		var vp := get_viewport_rect()
		var tr := get_global_transform_with_canvas()
		var x := tr.origin.x
		if x + w > -50.0 and x - w < vp.size.x + 50.0:
			queue_redraw()

	func h(i: int, k := 0) -> float:
		return fposmod(sin(i * 12.9898 + k * 78.233 + sd) * 43758.5453, 1.0)

	func dim(c: Color, k := 0.35) -> Color:
		return c.lerp(fog, k)

	# berge en retrait : un replat de roche brumeuse, plus sombre que le décor jouable
	func bank(top: float, col: Color, depth := 220.0) -> void:
		var pts := PackedVector2Array()
		var n := 14
		for i in n + 1:
			var x := -w / 2.0 - 40.0 + (w + 80.0) * i / n
			var yy := top + sin(i * 1.7 + sd) * 4.0 + (h(i, 3) - 0.5) * 6.0
			if i == 0 or i == n:
				yy += 30.0
			pts.append(Vector2(x, yy))
		pts.append(Vector2(w / 2.0 + 40.0, top + depth))
		pts.append(Vector2(-w / 2.0 - 40.0, top + depth))
		# la berge se fond dans l'arrière-plan vers le bas (pas de bloc plein si le décor s'ouvre)
		var cols := PackedColorArray()
		for i in pts.size():
			cols.append(Color(col, 1.0) if i <= n else Color(col, 0.0))
		draw_polygon(pts, cols)
		var edge := PackedVector2Array()
		for i in n + 1:
			edge.append(pts[i])
		draw_polyline(edge, col.lightened(0.18), 2.0)

	func water_band(y0: float, y1: float, c1: Color, c2: Color, speed: float, streak: Color, n := 14) -> void:
		# nappe en fuseau : épaisse au milieu, effilée aux bouts (pas de barre qui flotte)
		var m := 24
		var top := PackedVector2Array()
		var bot := PackedVector2Array()
		var mid := (y0 + y1) / 2.0
		for i in m + 1:
			var k := float(i) / m
			var x := -w / 2.0 + w * k
			var th := pow(sin(k * PI), 0.45)
			top.append(Vector2(x, mid - (mid - y0) * th))
			bot.append(Vector2(x, mid + (y1 - mid) * th))
		var poly := PackedVector2Array()
		var cols := PackedColorArray()
		for p in top:
			poly.append(p)
			cols.append(c1)
		for i in range(bot.size() - 1, -1, -1):
			poly.append(bot[i])
			cols.append(c2)
		draw_polygon(poly, cols)
		draw_polyline(top, c1.lightened(0.25), 1.2)
		for i in n:
			var lx := fposmod(h(i, 1) * w + t * speed * (0.6 + h(i, 2) * 0.8), w) - w / 2.0
			var k := (lx + w / 2.0) / w
			var th := pow(sin(k * PI), 0.45)
			var ly := mid + (h(i, 4) - 0.5) * (y1 - y0 - 6.0) * th
			var ll := (14.0 + h(i, 5) * 30.0) * th
			var x2 := minf(lx + ll, w / 2.0)
			if x2 > lx and th > 0.3:
				draw_line(Vector2(lx, ly), Vector2(x2, ly), streak, 1.5)

	func _draw() -> void:
		match kind:
			"pond": _pond()
			"swamp": _swamp()
			"sacred": _sacred_fountain()
			"metal": _crystal_mine()
			"lava": _volcano()
			"honey": _honey_river()
			"ink": _armillary()
			"icefall": _ice_fall()
			"bones": _bone_slide()
			"river": _forest_river()
			"quicksand": _quicksand()
			"roman": _roman_fountain()

	# ---- Profondeurs : étang souterrain immobile, reflets bleus, stalagmites
	func _pond() -> void:
		var rock := dim(pal["rock_hi"], 0.25)
		bank(-26.0, rock)
		for i in 5:
			var x := -w / 2.0 + 30.0 + h(i) * (w - 60.0)
			var hh := 30.0 + h(i, 1) * 60.0
			draw_colored_polygon(PackedVector2Array([Vector2(x - 10, -24), Vector2(x + 10, -24), Vector2(x + 2, -24 - hh), Vector2(x - 1, -24 - hh)]), rock.lightened(0.05))
		var pond := DU.ellipse(Vector2(0, -16), Vector2(w * 0.38, 11), 28)
		draw_colored_polygon(pond, Color(0.08, 0.16, 0.28))
		draw_colored_polygon(DU.ellipse(Vector2(0, -18), Vector2(w * 0.35, 7), 24), Color(0.2, 0.36, 0.55))
		DU.glow(self, Vector2(0, -18), w * 0.3, Color(0.4, 0.75, 1.0), 0.18)
		for i in 3:
			var k := fposmod(t * 0.35 + i / 3.0, 1.0)
			var c := Vector2((h(i, 6) - 0.5) * w * 0.4, -16)
			draw_arc(c, 6.0 + k * 40.0, 0, TAU, 24, Color(0.6, 0.85, 1.0, 0.35 * (1.0 - k)), 1.0)
		for i in 6:
			var p := Vector2((h(i, 8) - 0.5) * w * 0.55, -17 + h(i, 9) * 3.0)
			draw_circle(p, 2.0, Color(0.6, 0.9, 1.0, 0.45 + 0.35 * sin(t * 2.0 + i)))

	# ---- Jardins : marais vert, roseaux, nénuphars, bulles
	func _swamp() -> void:
		var mud := dim(Color(0.2, 0.25, 0.12), 0.2)
		bank(-22.0, mud)
		draw_colored_polygon(DU.ellipse(Vector2(0, -12), Vector2(w * 0.44, 12), 28), Color(0.12, 0.2, 0.08))
		draw_colored_polygon(DU.ellipse(Vector2(0, -14), Vector2(w * 0.41, 7), 26), Color(0.24, 0.34, 0.12))
		for i in 5:
			var p := Vector2((h(i, 2) - 0.5) * w * 0.7, -14 + h(i, 3) * 3)
			draw_colored_polygon(DU.ellipse(p, Vector2(9, 3), 10), Color(0.32, 0.55, 0.2))
			if i % 2 == 0:
				draw_circle(p + Vector2(2, -2), 2.0, Color(0.95, 0.75, 0.85))
		for i in 14:
			var x := -w / 2.0 + 10.0 + h(i, 4) * (w - 20.0)
			if absf(x) < w * 0.3:
				continue
			var hh := 26.0 + h(i, 5) * 34.0
			var sway := sin(t * 1.3 + i) * 3.0
			draw_line(Vector2(x, -20), Vector2(x + sway, -20 - hh), Color(0.35, 0.45, 0.18), 2.0)
			draw_colored_polygon(DU.ellipse(Vector2(x + sway, -20 - hh + 6), Vector2(2.5, 7), 8), Color(0.38, 0.25, 0.12))
		for i in 4:
			var k := fposmod(t * 0.6 + h(i, 7), 1.0)
			var p := Vector2((h(i, 8) - 0.5) * w * 0.6, -14 - k * 10.0)
			draw_arc(p, 2.0 + k * 2.0, 0, TAU, 10, Color(0.7, 0.9, 0.5, 0.6 * (1.0 - k)), 1.0)
		# arbre mort
		var tx := w * 0.32
		draw_line(Vector2(tx, -20), Vector2(tx - 6, -110), dim(Color(0.22, 0.18, 0.14), 0.3), 6.0)
		draw_line(Vector2(tx - 4, -70), Vector2(tx + 24, -96), dim(Color(0.22, 0.18, 0.14), 0.3), 3.0)
		draw_line(Vector2(tx - 5, -90), Vector2(tx - 30, -112), dim(Color(0.22, 0.18, 0.14), 0.3), 3.0)

	# ---- Citadelle : fontaine sacrée, statue, jets d'eau, cierges
	func _sacred_fountain() -> void:
		var stone := dim(Color(0.42, 0.38, 0.46), 0.25)
		bank(-14.0, dim(pal["rock_hi"], 0.3))
		var bw := minf(w * 0.6, 240.0)
		DU.vgrad(self, Rect2(-bw / 2.0, -40, bw, 26), stone.lightened(0.1), stone.darkened(0.3))
		draw_rect(Rect2(-bw / 2.0 - 6, -44, bw + 12, 6), stone.lightened(0.2))
		draw_rect(Rect2(-bw / 2.0 + 6, -40, bw - 12, 6), Color(0.35, 0.55, 0.75))
		# colonne et statue voilée
		DU.vgrad(self, Rect2(-10, -110, 20, 70), stone.lightened(0.15), stone.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(-16, -110), Vector2(16, -110), Vector2(8, -160), Vector2(0, -172), Vector2(-8, -160)]), stone.lightened(0.25))
		draw_circle(Vector2(0, -176), 7.0, stone.lightened(0.25))
		DU.glow(self, Vector2(0, -176), 30.0, Color(0.85, 0.9, 1.0), 0.25)
		# jets d'eau en arcs, gouttes qui tombent
		for sdn in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			for i in 12:
				var k := i / 11.0
				pts.append(Vector2(sdn * (8.0 + k * bw * 0.4), -100.0 + k * k * 64.0 - sin(k * PI) * 18.0))
			draw_polyline(pts, Color(0.7, 0.88, 1.0, 0.7), 2.0)
			for d in 3:
				var k := fposmod(t * 0.9 + d / 3.0, 1.0)
				draw_circle(Vector2(sdn * (8.0 + k * bw * 0.4), -100.0 + k * k * 64.0 - sin(k * PI) * 18.0), 1.8, Color(0.85, 0.95, 1.0, 0.9))
		for sdn in [-1.0, 1.0]:
			var cx: float = sdn * (bw / 2.0 + 24.0)
			draw_rect(Rect2(cx - 3, -34, 6, 20), Color(0.9, 0.86, 0.75))
			DU.glow(self, Vector2(cx, -38), 14.0, Color(1.0, 0.75, 0.4), 0.5 + 0.15 * sin(t * 7.0 + sdn))
			draw_circle(Vector2(cx, -38), 2.5, Color(1.0, 0.85, 0.5))

	# ---- Mines de Cristal : entrée de mine boisée dans un piton rocheux, cristaux qui percent
	# la roche, rails et wagonnet chargé, lanterne ; un filet de métal argenté coule devant
	func _crystal(c: Vector2, ang: float, ln: float, wd: float, col: Color) -> void:
		var d := Vector2.from_angle(ang)
		var n := d.orthogonal()
		var tip := c + d * ln
		var pts := PackedVector2Array([c + n * wd, c + d * ln * 0.8 + n * wd * 0.8, tip, c + d * ln * 0.8 - n * wd * 0.8, c - n * wd])
		draw_colored_polygon(pts, col)
		draw_colored_polygon(PackedVector2Array([c + n * wd, c + d * ln * 0.8 + n * wd * 0.8, tip, c + d * ln * 0.5]), col.lightened(0.3))
		draw_line(c + d * ln * 0.15 + n * wd * 0.3, c + d * ln * 0.7 + n * wd * 0.25, Color(1, 1, 1, 0.55), 1.2)
		DU.glow(self, c + d * ln * 0.5, ln * 0.9, col, 0.16)

	func _crystal_mine() -> void:
		var rock := dim(pal["rock_hi"].darkened(0.25), 0.2)
		var cc: Color = pal["moss"]
		bank(-10.0, rock.darkened(0.15))
		# piton rocheux
		var hill := PackedVector2Array([Vector2(-w * 0.46, -8), Vector2(-w * 0.38, -110), Vector2(-w * 0.2, -170), Vector2(w * 0.02, -190), Vector2(w * 0.22, -150), Vector2(w * 0.34, -80), Vector2(w * 0.42, -8)])
		var hc := PackedColorArray()
		for p in hill:
			hc.append(rock.lerp(rock.lightened(0.15), clampf(-p.y / 190.0, 0.0, 1.0)))
		draw_polygon(hill, hc)
		for i in 7:
			var p := Vector2((h(i, 2) - 0.5) * w * 0.6, -30.0 - h(i, 3) * 120.0)
			draw_line(p, p + Vector2(18 + h(i, 4) * 20, 6 + h(i, 5) * 10), rock.darkened(0.35), 1.5)
		# entrée : galerie sombre qui s'enfonce, lueur de cristaux au fond
		var ex := -w * 0.06
		var ew := 64.0
		var eh := 78.0
		var mouth := PackedVector2Array([Vector2(ex - ew / 2, -8), Vector2(ex - ew / 2, -eh + 14), Vector2(ex - ew / 2 + 10, -eh), Vector2(ex + ew / 2 - 10, -eh), Vector2(ex + ew / 2, -eh + 14), Vector2(ex + ew / 2, -8)])
		draw_colored_polygon(mouth, Color(0.02, 0.04, 0.06))
		draw_colored_polygon(DU.ellipse(Vector2(ex, -30), Vector2(ew * 0.32, eh * 0.3), 14), Color(cc.darkened(0.6), 0.9))
		DU.glow(self, Vector2(ex, -30), ew * 0.7, cc, 0.3 + 0.08 * sin(t * 1.5))
		for i in 4:
			_crystal(Vector2(ex - 16 + i * 10, -14), -PI / 2 + (h(i, 6) - 0.5) * 0.8, 12.0 + h(i, 7) * 10.0, 3.0, dim(cc, 0.25))
		# boisage : deux poteaux et un linteau, étais
		var wood := dim(Color(0.42, 0.29, 0.18), 0.15)
		for sx in [-1.0, 1.0]:
			DU.vgrad(self, Rect2(ex + sx * (ew / 2) - 5, -eh - 4, 10, eh - 4), wood.lightened(0.1), wood.darkened(0.3))
		DU.vgrad(self, Rect2(ex - ew / 2 - 10, -eh - 14, ew + 20, 12), wood.lightened(0.15), wood.darkened(0.25))
		draw_line(Vector2(ex - ew / 2 + 4, -eh + 2), Vector2(ex - ew / 2 + 18, -eh - 2), wood.darkened(0.2), 4.0)
		draw_line(Vector2(ex + ew / 2 - 4, -eh + 2), Vector2(ex + ew / 2 - 18, -eh - 2), wood.darkened(0.2), 4.0)
		# lanterne accrochée au linteau
		var lp := Vector2(ex + ew / 2 - 6, -eh + 10)
		draw_line(Vector2(lp.x, -eh - 2), lp + Vector2(0, -6), Color(0.3, 0.25, 0.2), 1.2)
		draw_rect(Rect2(lp + Vector2(-4, -6), Vector2(8, 11)), Color(0.25, 0.2, 0.15))
		DU.glow(self, lp, 26.0, Color(1.0, 0.78, 0.4), 0.55 + 0.1 * sin(t * 6.0))
		draw_rect(Rect2(lp + Vector2(-2.5, -4), Vector2(5, 7)), Color(1.0, 0.85, 0.5))
		# cristaux qui percent la roche
		var spots := [[-0.36, -100, -2.3], [-0.24, -150, -1.9], [-0.02, -186, -1.5], [0.16, -150, -1.1], [0.28, -96, -0.7], [0.36, -40, -0.4], [-0.42, -40, -2.7]]
		for i in spots.size():
			var sp: Array = spots[i]
			var base := Vector2(float(sp[0]) * w, float(sp[1]))
			var big := 1.0 + h(i, 9) * 0.8
			for k in 3:
				_crystal(base + Vector2(k * 5 - 5, 0), float(sp[2]) + (k - 1) * 0.35, (16.0 + h(i, k) * 18.0) * big * (1.2 if k == 1 else 0.8), 4.5 * big, cc.lerp(Color(0.85, 0.6, 1.0), h(i, 11) * 0.35))
		# rails qui sortent de la galerie, wagonnet chargé de cristaux
		var rail := Color(0.62, 0.64, 0.68)
		for i in 7:
			var sx := ex - 20 + i * 22.0
			draw_line(Vector2(sx, -6), Vector2(sx + 8, -6), wood.darkened(0.2), 4.0)
		draw_line(Vector2(ex - 24, -8), Vector2(ex + 150, -8), rail, 2.0)
		var cx := ex + 70.0 + sin(t * 0.4) * 30.0
		DU.vgrad(self, Rect2(cx - 18, -34, 36, 20), dim(Color(0.45, 0.38, 0.32), 0.1), dim(Color(0.25, 0.2, 0.18), 0.1))
		draw_rect(Rect2(cx - 20, -36, 40, 4), dim(Color(0.55, 0.48, 0.4), 0.1))
		for k in 4:
			_crystal(Vector2(cx - 12 + k * 8, -36), -PI / 2 + (k - 1.5) * 0.3, 10.0 + h(k, 12) * 8.0, 3.2, cc)
		for wx in [-11.0, 11.0]:
			draw_circle(Vector2(cx + wx, -12), 4.5, Color(0.18, 0.16, 0.16))
			draw_circle(Vector2(cx + wx, -12), 1.5, rail)
		# filet de métal argenté qui s'échappe sous les rails
		var pts := PackedVector2Array()
		for i in 10:
			var k := i / 9.0
			pts.append(Vector2(ex + 40 + k * w * 0.3, -4 + sin(k * 5.0 + t * 2.0) * 1.5))
		draw_polyline(pts, Color(0.85, 0.92, 1.0, 0.85), 3.0)
		for i in 4:
			var k := fposmod(t * 0.4 + i / 4.0, 1.0)
			draw_circle(Vector2(ex + 40 + k * w * 0.3, -4), 1.2, Color(1, 1, 1, 0.9))

	# ---- Forge : volcan en retrait, coulées de lave sur ses flancs, cratère rougeoyant, fumée
	func _volcano() -> void:
		var rock := dim(Color(0.16, 0.09, 0.08), 0.12)
		var hh := 150.0 + h(1) * 70.0
		var top_w := 34.0
		var base := w * 0.5
		var cone := PackedVector2Array([Vector2(-base, 10), Vector2(-top_w, -hh), Vector2(-top_w * 0.4, -hh + 6), Vector2(top_w * 0.4, -hh + 6), Vector2(top_w, -hh), Vector2(base, 10)])
		var cols := PackedColorArray([rock, rock.lightened(0.12), rock.lightened(0.1), rock.lightened(0.1), rock.lightened(0.12), rock])
		draw_polygon(cone, cols)
		# arêtes de roche
		for i in 5:
			var x0 := (h(i, 2) - 0.5) * top_w * 1.6
			var x1 := (h(i, 3) - 0.5) * base * 1.6
			draw_line(Vector2(x0, -hh + 8), Vector2(x1, 6), rock.darkened(0.35), 2.0)
		DU.glow(self, Vector2(0, -hh), 70.0, Color(1.0, 0.45, 0.12), 0.45 + 0.1 * sin(t * 2.0))
		draw_colored_polygon(DU.ellipse(Vector2(0, -hh + 3), Vector2(top_w * 0.75, 5), 14), Color(1.0, 0.6, 0.18))
		# coulées : rubans de lave qui descendent en serpentant, braises qui y glissent
		for f in 3:
			var side := -1.0 if f == 0 else (1.0 if f == 1 else (h(f, 9) - 0.5))
			var pts := PackedVector2Array()
			var segs := 16
			for i in segs + 1:
				var k := float(i) / segs
				var y := -hh + 4.0 + k * (hh + 4.0)
				var half_w := top_w * 0.4 + (base - top_w * 0.4) * k
				var x := side * half_w * (0.25 + 0.45 * h(f, 4)) + sin(k * 7.0 + f * 2.0) * 10.0 * k
				pts.append(Vector2(x, y))
			for i in segs:
				var k := float(i) / segs
				var wdt := 5.0 + k * 7.0
				draw_line(pts[i], pts[i + 1], Color(0.75, 0.2, 0.05), wdt + 3.0)
				draw_line(pts[i], pts[i + 1], Color(1.0, 0.55 + 0.25 * (1.0 - k), 0.12), wdt)
			for d in 5:
				var k := fposmod(t * 0.18 + d / 5.0 + h(f, 6), 1.0)
				var idx := int(k * segs)
				var p: Vector2 = pts[idx].lerp(pts[mini(idx + 1, segs)], k * segs - idx)
				draw_circle(p, 2.2, Color(1.0, 0.92, 0.55))
			DU.glow(self, pts[segs], 26.0, Color(1.0, 0.45, 0.1), 0.3)
		# panache de fumée
		for i in 6:
			var k := fposmod(t * 0.12 + i / 6.0, 1.0)
			var c := Vector2(sin(k * 3.0 + i) * 10.0 + k * 30.0, -hh - 10.0 - k * 120.0)
			draw_circle(c, 10.0 + k * 22.0, Color(0.25, 0.2, 0.2, 0.35 * (1.0 - k)))
		for i in 8:
			var k := fposmod(t * 0.4 + h(i, 7), 1.0)
			draw_circle(Vector2((h(i, 8) - 0.5) * 50.0 + k * 20.0, -hh - k * 110.0), 1.6, Color(1.0, 0.6, 0.2, 1.0 - k))

	# ---- Ruche : rivière de miel lente, alvéoles en rive
	func _honey_river() -> void:
		bank(-28.0, dim(Color(0.45, 0.3, 0.12), 0.2))
		water_band(-26.0, -6.0, Color(1.0, 0.78, 0.25), Color(0.72, 0.42, 0.08), 10.0, Color(1.0, 0.95, 0.6, 0.7), 8)
		for i in 9:
			var c := Vector2(-w / 2.0 + 20.0 + h(i, 2) * (w - 40.0), -40.0 - h(i, 3) * 40.0)
			if absf(c.x) < w * 0.25:
				continue
			var hex := PackedVector2Array()
			for k in 6:
				hex.append(c + Vector2.from_angle(k * TAU / 6.0 + PI / 6.0) * 11.0)
			draw_colored_polygon(hex, dim(Color(0.85, 0.6, 0.2), 0.25))
			draw_polyline(hex + PackedVector2Array([hex[0]]), dim(Color(0.6, 0.38, 0.1), 0.25), 1.5)
		for i in 3:
			var x := (h(i, 5) - 0.5) * w * 0.8
			var l := 8.0 + fposmod(t * 0.7 + h(i, 6), 1.0) * 20.0
			draw_line(Vector2(x, -80.0), Vector2(x, -80.0 + l), Color(1.0, 0.75, 0.2), 3.0)

	# ---- Bibliothèque : grande sphère armillaire de laiton qui tourne sur son socle, lustre de bougies
	func _armillary() -> void:
		var stone := dim(Color(0.36, 0.3, 0.24), 0.25)
		bank(-16.0, stone)
		var brass := dim(Color(0.85, 0.66, 0.32), 0.2)
		# socle à degrés
		DU.vgrad(self, Rect2(-46, -34, 92, 20), stone.lightened(0.15), stone.darkened(0.2))
		DU.vgrad(self, Rect2(-30, -52, 60, 18), stone.lightened(0.2), stone.darkened(0.15))
		draw_line(Vector2(0, -52), Vector2(0, -78), brass.darkened(0.2), 5.0)
		var c := Vector2(0, -140)
		var R := 62.0
		DU.glow(self, c, R * 1.4, Color(1.0, 0.8, 0.45), 0.12)
		# anneaux qui tournent (ellipses inclinées)
		for i in 4:
			var tilt := i * PI / 4.0 + t * (0.15 + i * 0.05) * (1.0 if i % 2 == 0 else -1.0)
			var sq := 0.25 + 0.75 * absf(cos(t * (0.2 + i * 0.07) + i))
			var pts := PackedVector2Array()
			for k in 41:
				var a2 := k * TAU / 40.0
				var p := Vector2(cos(a2) * R, sin(a2) * R * sq).rotated(tilt)
				pts.append(c + p)
			draw_polyline(pts, brass.darkened(0.25), 4.0)
			draw_polyline(pts, brass, 2.0)
		draw_arc(c, R + 6.0, 0, TAU, 48, brass.darkened(0.3), 3.0)
		# globe central et petites planètes
		draw_circle(c, 13.0, dim(Color(0.3, 0.45, 0.6), 0.2))
		draw_arc(c, 13.0, -0.6, 1.2, 10, Color(1, 1, 1, 0.35), 2.0)
		for i in 3:
			var a3 := t * (0.5 + i * 0.3) + i * 2.0
			var p := c + Vector2(cos(a3) * (R * (0.45 + i * 0.18)), sin(a3) * R * 0.25)
			draw_circle(p, 4.0 - i, [Color(0.9, 0.5, 0.3), Color(0.6, 0.8, 1.0), Color(0.95, 0.9, 0.6)][i])
		# lustre de bougies de part et d'autre
		for sdn in [-1.0, 1.0]:
			var lx: float = sdn * (w * 0.36)
			draw_line(Vector2(lx, -260), Vector2(lx, -150), Color(brass, 0.6), 1.5)
			draw_arc(Vector2(lx, -150), 18.0, 0.1, PI - 0.1, 10, brass, 2.5)
			for k in 3:
				var cx := lx - 16.0 + k * 16.0
				draw_rect(Rect2(cx - 2, -160, 4, 8), Color(0.92, 0.88, 0.75))
				DU.glow(self, Vector2(cx, -164), 10.0, Color(1.0, 0.75, 0.4), 0.45 + 0.15 * sin(t * 8.0 + k + sdn))
				draw_circle(Vector2(cx, -164), 1.8, Color(1.0, 0.85, 0.5))
		# poussière dorée qui flotte
		for i in 10:
			var k := fposmod(t * 0.05 + h(i, 4), 1.0)
			draw_circle(Vector2((h(i, 5) - 0.5) * w * 0.8 + sin(t + i) * 8.0, -30.0 - k * 220.0), 1.2, Color(1.0, 0.85, 0.5, 0.6 * sin(k * PI)))

	# ---- Abysses Gelés : cascade figée et lac de glace craquelé
	func _ice_fall() -> void:
		bank(-22.0, dim(Color(0.32, 0.4, 0.5), 0.3))
		draw_colored_polygon(DU.ellipse(Vector2(0, -14), Vector2(w * 0.42, 9), 26), dim(Color(0.62, 0.78, 0.92), 0.25))
		for i in 4:
			var x := (h(i, 1) - 0.5) * w * 0.6
			draw_line(Vector2(x, -14), Vector2(x + 20, -10), Color(1, 1, 1, 0.6), 1.0)
		# cascade gelée (colonnes de glace qui tombent du haut)
		var fx := -w * 0.15
		for i in 7:
			var x := fx - 40.0 + i * 13.0
			var top := -260.0 - h(i, 3) * 40.0
			var bot := -14.0 - h(i, 4) * 10.0
			var col := Color(0.55, 0.78, 0.95).lerp(Color(0.8, 0.92, 1.0), h(i, 5))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 6, top), Vector2(x + 6, top), Vector2(x + 7, bot), Vector2(x - 5, bot)]), Color(col, 0.9))
			draw_line(Vector2(x - 6, top), Vector2(x - 5, bot), Color(0.3, 0.45, 0.6, 0.8), 1.2)
			draw_line(Vector2(x - 2, top + 10), Vector2(x - 1, bot - 6), Color(1, 1, 1, 0.65), 1.4)
		var sh := 0.4 + 0.3 * sin(t * 1.2)
		draw_line(Vector2(fx - 30, -200), Vector2(fx + 40, -60), Color(1, 1, 1, sh * 0.4), 2.0)

	# ---- Ossuaire : éboulis d'os qui glissent et roulent
	func _bone_slide() -> void:
		var bone := dim(Color(0.86, 0.81, 0.68), 0.3)
		bank(-20.0, dim(pal["rock_hi"], 0.3))
		var heap := PackedVector2Array([Vector2(-w * 0.45, -20), Vector2(-w * 0.1, -110), Vector2(w * 0.05, -120), Vector2(w * 0.42, -20)])
		draw_colored_polygon(heap, bone.darkened(0.45))
		for i in 26:
			var p := Vector2((h(i, 1) - 0.5) * w * 0.8, -22.0 - h(i, 2) * 90.0)
			var lim := -20.0 - (1.0 - absf(p.x + w * 0.02) / (w * 0.44)) * 100.0
			if p.y < lim:
				p.y = lim + 4.0
			var a := h(i, 3) * PI
			draw_line(p - Vector2.from_angle(a) * 7.0, p + Vector2.from_angle(a) * 7.0, bone, 3.0)
			draw_circle(p - Vector2.from_angle(a) * 7.0, 2.4, bone)
			draw_circle(p + Vector2.from_angle(a) * 7.0, 2.4, bone)
		for i in 3:
			var c := Vector2((h(i, 9) - 0.5) * w * 0.5, -40.0 - h(i, 10) * 40.0)
			draw_circle(c, 9.0, bone)
			draw_circle(c + Vector2(-3, 0), 2.0, Color(0.1, 0.08, 0.08))
			draw_circle(c + Vector2(3, 0), 2.0, Color(0.1, 0.08, 0.08))
		# os qui dévalent la pente
		for i in 3:
			var k := fposmod(t * 0.3 + i / 3.0, 1.0)
			var p := Vector2(-w * 0.05 + k * w * 0.42, -112.0 + k * 92.0)
			var a := t * 6.0 + i
			draw_line(p - Vector2.from_angle(a) * 7.0, p + Vector2.from_angle(a) * 7.0, bone.lightened(0.1), 3.0)
			if k > 0.85:
				for d in 3:
					draw_circle(p + Vector2(d * 4 - 4, 2 - d), 1.2, Color(bone, 0.6))

	# ---- Jungle : rivière de forêt et cascade, rochers, écume
	func _forest_river() -> void:
		var rock := dim(Color(0.3, 0.32, 0.26), 0.25)
		bank(-26.0, dim(Color(0.18, 0.28, 0.14), 0.25))
		water_band(-24.0, -6.0, Color(0.35, 0.6, 0.65), Color(0.12, 0.3, 0.35), 40.0, Color(0.85, 1.0, 1.0, 0.7), 14)
		# falaise et cascade
		var cx := w * 0.3
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 30, -24), Vector2(cx - 26, -200), Vector2(cx + 60, -210), Vector2(cx + 70, -24)]), rock)
		var fw := 26.0
		DU.vgrad(self, Rect2(cx - 22, -204, fw, 180), Color(0.6, 0.85, 0.9, 0.85), Color(0.75, 0.95, 1.0, 0.9))
		for i in 6:
			var y := fposmod(t * 140.0 + i * 30.0, 180.0) - 204.0
			draw_line(Vector2(cx - 20 + h(i, 2) * fw, y), Vector2(cx - 20 + h(i, 2) * fw, y + 14), Color(1, 1, 1, 0.7), 1.5)
		for i in 5:
			var k := fposmod(t * 1.2 + i / 5.0, 1.0)
			draw_circle(Vector2(cx - 22 + h(i, 4) * fw, -26 - k * 10), 3.0 * (1.0 - k) + 1.0, Color(1, 1, 1, 0.7 * (1.0 - k)))
		for i in 4:
			var p := Vector2(-w * 0.4 + i * w * 0.18, -10.0 - h(i, 6) * 6.0)
			draw_colored_polygon(DU.ellipse(p, Vector2(10 + h(i, 7) * 8, 6), 12, PI, TAU), rock.lightened(0.1))
		for i in 4:
			var x := -w / 2.0 + h(i, 8) * w * 0.5
			draw_colored_polygon(PackedVector2Array([Vector2(x, -24), Vector2(x - 14, -60), Vector2(x + 2, -40), Vector2(x + 12, -66), Vector2(x + 8, -24)]), dim(Color(0.2, 0.42, 0.18), 0.25))

	# ---- Désert : sables mouvants en spirale, pilier à demi englouti
	func _quicksand() -> void:
		var sand := dim(pal["rock_hi"].lightened(0.1), 0.15)
		bank(-16.0, sand.darkened(0.1))
		var c := Vector2(0, -12)
		draw_colored_polygon(DU.ellipse(c, Vector2(w * 0.38, 13), 28), sand.darkened(0.4))
		draw_colored_polygon(DU.ellipse(c, Vector2(w * 0.36, 11), 28), sand.darkened(0.2))
		for i in 4:
			var k := fposmod(t * 0.25 + i / 4.0, 1.0)
			var rr := (1.0 - k) * w * 0.34
			draw_arc(c, rr, 0, TAU, 32, Color(sand.darkened(0.45), 0.6 * k), 1.5)
			# ellipse aplatie : on dessine des points sur l'ellipse qui tournent
			for d in 6:
				var a := d * TAU / 6.0 + t * 0.8 + i
				draw_circle(c + Vector2(cos(a) * rr, sin(a) * rr * 0.3), 1.4, sand.darkened(0.4))
		draw_colored_polygon(DU.ellipse(c, Vector2(16, 4), 12), sand.darkened(0.5))
		# pilier englouti, penché
		var px := w * 0.22
		draw_colored_polygon(PackedVector2Array([Vector2(px - 10, -14), Vector2(px + 10, -14), Vector2(px + 24, -84), Vector2(px + 6, -88)]), dim(Color(0.7, 0.55, 0.35), 0.2))
		draw_colored_polygon(PackedVector2Array([Vector2(px + 2, -88), Vector2(px + 28, -82), Vector2(px + 26, -94), Vector2(px + 2, -98)]), dim(Color(0.75, 0.6, 0.4), 0.2))

	# ---- Temple Antique : vieille fontaine romaine, tête de lion, colonnes
	func _roman_fountain() -> void:
		var marble := dim(Color(0.78, 0.76, 0.72), 0.3)
		bank(-12.0, dim(pal["rock_hi"], 0.3))
		var bw := minf(w * 0.55, 230.0)
		DU.vgrad(self, Rect2(-bw / 2.0, -36, bw, 24), marble, marble.darkened(0.3))
		draw_rect(Rect2(-bw / 2.0 - 6, -40, bw + 12, 6), marble.lightened(0.15))
		draw_rect(Rect2(-bw / 2.0 + 6, -36, bw - 12, 5), Color(0.4, 0.6, 0.65))
		# mur à niche et tête de lion
		DU.vgrad(self, Rect2(-50, -140, 100, 100), marble.darkened(0.1), marble.darkened(0.35))
		draw_arc(Vector2(0, -110), 26.0, PI, TAU, 14, marble.lightened(0.1), 4.0)
		draw_circle(Vector2(0, -92), 11.0, dim(Color(0.65, 0.55, 0.35), 0.25))
		draw_circle(Vector2(-4, -95), 1.5, Color(0.15, 0.12, 0.1))
		draw_circle(Vector2(4, -95), 1.5, Color(0.15, 0.12, 0.1))
		var pts := PackedVector2Array()
		for i in 10:
			var k := i / 9.0
			pts.append(Vector2(k * 30.0, -86.0 + k * k * 50.0))
		draw_polyline(pts, Color(0.7, 0.9, 1.0, 0.75), 3.0)
		for d in 3:
			var k := fposmod(t * 1.1 + d / 3.0, 1.0)
			draw_circle(Vector2(k * 30.0, -86.0 + k * k * 50.0), 1.8, Color(0.9, 0.97, 1.0))
		var rk := fposmod(t * 0.8, 1.0)
		draw_arc(Vector2(30, -34), 4.0 + rk * 18.0, PI, TAU, 12, Color(0.85, 0.95, 1.0, 0.6 * (1.0 - rk)), 1.0)
		# colonnes, l'une brisée
		for sdn in [-1.0, 1.0]:
			var cx: float = sdn * (bw / 2.0 + 30.0)
			var top := -150.0 if sdn < 0 else -96.0
			DU.vgrad(self, Rect2(cx - 9, top, 18, -12.0 - top), marble.lightened(0.05), marble.darkened(0.3))
			for f in 3:
				draw_line(Vector2(cx - 5 + f * 5, top + 4), Vector2(cx - 5 + f * 5, -16), marble.darkened(0.25), 1.0)
			draw_rect(Rect2(cx - 12, top - 6, 24, 6), marble.lightened(0.15))

const KINDS := {"profondeurs": "pond", "jardins": "swamp", "citadelle": "sacred", "cristal": "metal",
	"forge": "lava", "bibliotheque": "ink", "glace": "icefall", "ruche": "honey", "ossuaire": "bones",
	"jungle": "river", "desert": "quicksand", "antique": "roman"}

func _ready() -> void:
	z_index = -6
	biome = String(main.pal.get("id", ""))
	if not KINDS.has(biome) or int(Settings.gfx_quality) >= 2:
		return
	fog = (main.pal["bg"] as Color).lerp(main.pal["ambient"], 0.14)
	var T: int = main.TILE
	var W: int = main.map_size.x
	var rng := RandomNumberGenerator.new()
	rng.seed = int(main.level.get("seed", 0)) * 7 + 3
	var x := 30 + rng.randi_range(0, 12)
	while x < W - 24:
		var sw := rng.randf_range(260.0, 400.0)
		var spot = null
		# cherche, près de x, un sol dégagé : la scène prend la largeur du sol continu
		# (le bas de la berge reste caché derrière le sol où marche le héros)
		for dx in [0, 3, -3, 6, -6, 9, -9, 12, 15, 18, 21]:
			var y = _floor_at(x + dx)
			if y == null:
				continue
			var run := _run(x + dx, y)
			if run.y - run.x + 1 >= 8:
				spot = y
				x = (run.x + run.y) / 2
				sw = minf(sw, (run.y - run.x + 1) * T - 24.0)
				break
		if spot != null:
			var s := Scene.new()
			s.kind = KINDS[biome]
			s.w = sw
			s.sd = rng.randf() * 100.0
			s.fog = fog
			s.pal = main.pal
			var world := Vector2(x * T + T / 2.0, spot * T)
			s.position = world * (1.0 - FACTOR)
			add_child(s)
			scenes.append(s)
		x += rng.randi_range(48, 70)
	_no_lights(self)

var _lenient := false

# étendue (colonnes min, max) du sol continu à la hauteur y autour de x
func _run(x: int, y: int) -> Vector2i:
	var a := x
	var b := x
	while a > 1 and _covered(a - 1, y) and b - a < 30:
		a -= 1
	while b < main.map_size.x - 2 and _covered(b + 1, y) and b - a < 30:
		b += 1
	for cx in range(x - 3, x + 4):
		for k in range(1, 6):
			if main.solid.has(Vector2i(cx, y - k)):
				return Vector2i(x, x)
	return Vector2i(a, b)

# la colonne a une surface de sol (case pleine sous de l'air) à cette hauteur ou un peu au-dessus
func _covered(cx: int, y: int) -> bool:
	for k in range(0, 4):
		if main.solid.has(Vector2i(cx, y - k)) and not main.solid.has(Vector2i(cx, y - k - 1)):
			return true
	return false

func _flat_floor(x: int, half: int):
	var y = _floor_at(x)
	if y == null:
		return null
	for cx in range(x - half, x + half + 1):
		# le bas de la berge doit être caché : sol à cette hauteur (ou un peu plus haut) devant
		var covered := false
		for k in range(0, 9 if _lenient else 4):
			if main.solid.has(Vector2i(cx, y - k)) or (_lenient and main.solid.has(Vector2i(cx, y + k))):
				covered = true
				break
		if not covered:
			return null
		# et de l'air au-dessus du milieu de la scène, pour la voir
		if absi(cx - x) <= 3:
			for k in range(1, 6):
				if main.solid.has(Vector2i(cx, y - k)):
					return null
	return y

# hauteur du sol (case pleine sous de l'air sur 6 cases) dans la colonne x, ou null
func _floor_at(x: int):
	for y in range(4, main.map_size.y - 1):
		var c := Vector2i(x, y)
		if main.solid.has(c) and not main.solid.has(c + Vector2i(0, -1)):
			var free := true
			for k in range(1, 7):
				if main.solid.has(c + Vector2i(0, -k)):
					free = false
			if free:
				return y
	return null

func _process(_delta: float) -> void:
	var cam: Camera2D = main.camera
	if cam == null:
		return
	position = cam.get_screen_center_position() * FACTOR

func _no_lights(n: Node) -> void:
	if n is CanvasItem:
		n.light_mask = 2
	for k in n.get_children():
		_no_lights(k)

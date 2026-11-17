extends Node2D
const DU = preload("res://scripts/draw_util.gd")
# Pièges en hauteur (créés depuis la carte) :
#  dart       (Z) : totem qui tire des fléchettes à hauteur de tête — s'accroupir pour les esquiver (ou parer)
#  blade      (U) : lame-pendule suspendue au plafond, son point bas passe juste au-dessus d'un héros accroupi
#  stalactite (V) : se décroche quand on passe dessous ; une fois tombée, elle ne revient pas
#  Pièges au sol (posés à distance les uns des autres, selon le biome) :
#  spikes     (k) : herse de pics qui sort du sol puis rentre (les pointes dépassent juste avant)
#  gas        (q) : champignon qui gonfle puis libère un nuage de spores toxiques (Jardins, Ruche)
#  geyser     (v / y) : geyser de flammes (Forge) ou de glace (Abysses Gelés) qui jaillit du sol
# Le totem pivote pour suivre le héros (il se retourne, puis reprend son rythme de tir).
const Ch = preload("res://scripts/charms.gd")
var main
var kind := "dart"
var dir := 1.0           # sens de tir du totem
var floor_y := 0.0       # sol sous la lame
var t := 0.0
var period := 2.4
var hit_cd := 0.0
var turn_t := 0.0        # totem : en train de pivoter
var element := "fire"    # geyser : "fire" / "ice"
const CYCLE := {"spikes": [1.6, 0.55, 0.9], "gas": [1.8, 0.7, 1.5], "geyser": [1.9, 0.7, 1.0]}   # repos, alerte, actif
# pendule
var length := 120.0
var amp := 1.05
var phase := 0.0
# stalactite
var state := "idle"      # idle / shake / fall / gone
var st_t := 0.0
var home := Vector2.ZERO
var fall_v := 0.0
# Pas Léger : franchir le piège sans être touché rapporte des éclats
var pass_side := 0.0
var pass_hp := 0
var pass_rewarded := false

func _ready() -> void:
	add_to_group("sleepy")
	home = position
	phase = randf() * TAU
	t = randf() * period
	if kind in CYCLE:
		var c: Array = CYCLE[kind]
		period = c[0] + c[1] + c[2]
		t = randf() * period
	if kind == "blade":
		length = maxf(floor_y - position.y - 30.0, 60.0)   # point bas à hauteur de tête : passe au-dessus d'un héros accroupi
	z_index = 2

func _player_rect() -> Rect2:
	return main.player.get_rect()

func _hurt(from: Vector2) -> void:
	var p = main.player
	if p.dead or p.dash_t > 0.0 or hit_cd > 0.0:
		return
	hit_cd = 0.6
	p.receive_hit(from, self)

func parried(_d: Vector2) -> void:
	hit_cd = 0.8
	if kind == "stalactite" and state == "fall":
		_shatter()

func blade_pos() -> Vector2:
	var a := sin(t * 1.9 + phase) * amp
	return position + Vector2(sin(a), cos(a)) * length

func _physics_process(delta: float) -> void:
	t += delta
	hit_cd -= delta
	if main.player == null:
		return
	_check_pass()
	match kind:
		"dart":
			# tourelle : se retourne vers le héros quand il passe de l'autre côté
			var pp2: Vector2 = main.player.global_position
			var want := dir
			if absf(pp2.x - global_position.x) < 700.0 and absf(pp2.y - global_position.y) < 240.0 and absf(pp2.x - global_position.x) > 8.0:
				want = signf(pp2.x - global_position.x)
			if want != dir:
				turn_t += delta
				if turn_t >= 0.35:
					dir = want
					turn_t = 0.0
					t = minf(fmod(t, period), period - 0.7)   # laisse le temps de voir la gueule rougeoyer
				queue_redraw()
				return
			turn_t = 0.0
			if fmod(t, period) < fmod(t - delta, period):
				var on_screen: bool = absf(main.player.global_position.x - global_position.x) < 700.0
				# aucun tir pendant un combat de boss
				if on_screen and not (main.boss_started and not main.boss_dead):
					main.spawn_projectile(global_position + Vector2(dir * 14.0, -28.0), Vector2(dir * 300.0, 0),
						{"kind": "dart", "hostile": true, "radius": 5.0, "life": 2.6, "from_trap": true})
					Audio.sfx("spit", 0.15, -6.0)
		"spikes", "gas", "geyser":
			if _phase() == 2 and _danger_rect().intersects(_player_rect()):
				_hurt(global_position + Vector2(0, 8))
			if _phase() == 2 and fmod(t, period) - CYCLE[kind][0] - CYCLE[kind][1] < delta and absf(main.player.global_position.x - global_position.x) < 600.0:
				match kind:
					"spikes": Audio.sfx("slash", 0.2, -10.0)
					"gas": Audio.sfx("spit", 0.2, -8.0)
					"geyser": Audio.sfx("ult" if element == "fire" else "parry", 0.2, -14.0)
		"blade":
			var bp := blade_pos()
			if Rect2(bp - Vector2(16, 9), Vector2(32, 18)).intersects(_player_rect()):
				_hurt(bp)
		"stalactite":
			match state:
				"idle":
					var pp: Vector2 = main.player.global_position
					if absf(pp.x - position.x) < 44.0 and pp.y > position.y and pp.y - position.y < 520.0:
						state = "shake"
						st_t = 0.4
						Audio.sfx("door", 0.2, -10.0)
				"shake":
					st_t -= delta
					if st_t <= 0.0:
						state = "fall"
						fall_v = 0.0
				"fall":
					fall_v = minf(fall_v + 1800.0 * delta, 900.0)
					position.y += fall_v * delta
					if Rect2(position + Vector2(-9, 0), Vector2(18, 30)).intersects(_player_rect()):
						_hurt(position)
						_shatter()
					elif main.is_solid_at(position + Vector2(0, 30)):
						_shatter()
				"gone":
					pass    # une stalactite tombée le reste (elle ne se reforme plus)
	queue_redraw()

# 0 repos, 1 alerte, 2 actif (pièges au sol à cycle)
func _phase() -> int:
	var c: Array = CYCLE[kind]
	var m := fmod(t, period)
	return 0 if m < c[0] else (1 if m < c[0] + c[1] else 2)

func _phase_k() -> float:
	var c: Array = CYCLE[kind]
	var m := fmod(t, period)
	var ph := _phase()
	return (m / c[0]) if ph == 0 else (((m - c[0]) / c[1]) if ph == 1 else ((m - c[0] - c[1]) / c[2]))

func _danger_rect() -> Rect2:
	match kind:
		"spikes": return Rect2(global_position + Vector2(-30, -20), Vector2(60, 20))
		"gas": return Rect2(global_position + Vector2(-44, -96), Vector2(88, 84))
		"geyser": return Rect2(global_position + Vector2(-14, -150), Vector2(28, 150))
	return Rect2()

func _check_pass() -> void:
	var p = main.player
	var dx: float = p.global_position.x - global_position.x
	if pass_side == 0.0:
		if absf(dx) < 140.0 and absf(dx) > 90.0:
			pass_side = signf(dx)
			pass_hp = p.hp
	elif absf(dx) > 160.0:
		pass_side = 0.0
	elif signf(dx) == -pass_side and absf(dx) > 90.0:
		if p.hp >= pass_hp and not p.dead and p.eq(Ch.LIGHT_STEP) and not pass_rewarded:
			pass_rewarded = true
			p.geo += 5
			main.spawn_burst(p.global_position, Color(0.7, 1.0, 0.6), 10, 140.0)
			Audio.sfx("pickup", 0.1, -6.0)
		pass_side = 0.0

func _shatter() -> void:
	main.spawn_burst(position + Vector2(0, 24), Color(0.75, 0.7, 0.65), 12, 160.0, 400.0)
	state = "gone"
	st_t = 5.0

func _draw() -> void:
	match kind:
		"spikes":
			var ph := _phase()
			var k := _phase_k()
			var h := 0.0
			if ph == 1:
				h = 5.0 + sin(t * 50.0) * 1.0            # les pointes dépassent : alerte
			elif ph == 2:
				h = 20.0 * minf(k * 6.0, 1.0) * (1.0 if k < 0.8 else (1.0 - k) / 0.2)
			# socle : plaque de fer percée
			DU.box(self, Rect2(-30, -3, 60, 4), Color(0.25, 0.24, 0.27))
			for i in 7:
				draw_circle(Vector2(-24 + i * 8, -1.5), 1.6, Color(0.07, 0.06, 0.07))
			if h > 0.5:
				var steel := Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.72, 0.74, 0.8)
				for i in 7:
					var x := -24.0 + i * 8.0
					DU.flat(self, PackedVector2Array([Vector2(x - 3.2, -2), Vector2(x, -2 - h), Vector2(x + 3.2, -2)]), steel)
					draw_line(Vector2(x - 0.6, -3), Vector2(x - 0.2, -1.5 - h), Color(1, 1, 1, 0.6), 0.8)
		"gas":
			var ph := _phase()
			var k := _phase_k()
			var sw := 1.0 + (0.25 * k + sin(t * 40.0) * 0.04 if ph == 1 else 0.0)
			var cap := Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.55, 0.72, 0.3)
			# pied et chapeau tacheté, qui gonfle avant de cracher
			DU.box(self, Rect2(-5, -16, 10, 16), Color(0.82, 0.78, 0.66))
			DU.poly(self, DU.ellipse(Vector2(0, -18), Vector2(17, 11) * sw, 20, PI, TAU), cap)
			draw_line(Vector2(-16 * sw, -18), Vector2(16 * sw, -18), cap.darkened(0.4), 1.4)
			for i in 4:
				draw_circle(Vector2((-9 + i * 6) * sw, (-23 + absf(i - 1.5) * 2.0) * sw - 2), 2.0, Color(0.92, 0.95, 0.75))
			if ph == 1:
				DU.glow(self, Vector2(0, -22), 24.0, Color(0.7, 1.0, 0.4), 0.3 * k)
			if ph == 2:
				var a := 1.0 if k < 0.75 else (1.0 - k) / 0.25
				var gc := Color(0.6, 0.9, 0.35) if not Settings.colorblind else Color(1.0, 0.1, 0.85)
				for i in 9:
					var ang := i * 0.7 + t * 0.8
					var r := 14.0 + 24.0 * minf(k * 4.0, 1.0)
					var c := Vector2(cos(ang) * r * 1.2, -52.0 + sin(ang * 1.3) * r * 0.8)
					DU.glow(self, c, 26.0, gc, 0.35 * a)
					draw_circle(c, 9.0, Color(gc, 0.18 * a))
		"geyser":
			var ph := _phase()
			var k := _phase_k()
			var fire := element == "fire"
			var col := Color(1.0, 0.55, 0.2) if fire else Color(0.6, 0.85, 1.0)
			if Settings.colorblind:
				col = Color(1.0, 0.1, 0.85)
			# bouche du geyser : cratère de roche
			DU.poly(self, PackedVector2Array([Vector2(-18, 0), Vector2(-12, -6), Vector2(-5, -4), Vector2(5, -4), Vector2(12, -6), Vector2(18, 0)]), Color(0.3, 0.27, 0.27) if fire else Color(0.5, 0.58, 0.66))
			draw_line(Vector2(-6, -4), Vector2(6, -4), col.darkened(0.3 if ph == 0 else 0.0), 2.0)
			if ph == 1:
				# bouillonne : gouttes / éclats qui sautillent
				for i in 5:
					var y := -fposmod(t * 90.0 + i * 13.0, 26.0)
					draw_circle(Vector2(sin(i * 2.1 + t * 9.0) * 6.0, y - 4.0), 2.0, Color(col, 0.8))
				DU.glow(self, Vector2(0, -6), 20.0, col, 0.4 * k)
			elif ph == 2:
				var hh := 150.0 * minf(k * 6.0, 1.0) * (1.0 if k < 0.8 else (1.0 - k) / 0.2)
				DU.glow(self, Vector2(0, -hh * 0.5), hh * 0.5 + 10.0, col, 0.35)
				# colonne effilée qui ondule (tranches pour éviter les soucis de triangulation)
				var n := 14
				for layer in 2:
					var wk := 1.0 if layer == 0 else 0.45
					var cc := Color(col, 0.7) if layer == 0 else (Color(1, 0.95, 0.8, 0.85) if fire else Color(1, 1, 1, 0.85))
					for i in n:
						var y0 := -hh * i / float(n)
						var y1 := -hh * (i + 1) / float(n)
						var w0 := (13.0 - 7.0 * i / float(n) + sin(t * 25.0 + i * 1.3) * 2.5) * wk
						var w1 := (13.0 - 7.0 * (i + 1) / float(n) + sin(t * 25.0 + (i + 1) * 1.3) * 2.5) * wk
						var x0 := sin(t * 9.0 + i * 0.6) * 2.0
						var x1 := sin(t * 9.0 + (i + 1) * 0.6) * 2.0
						DU.flat(self, PackedVector2Array([Vector2(x0 - w0, y0), Vector2(x0 + w0, y0), Vector2(x1 + w1, y1), Vector2(x1 - w1, y1)]), cc)
				# langues / éclats au sommet
				for i in 3:
					var tip := Vector2(sin(t * 17.0 + i * 2.0) * 8.0, -hh - 6.0 - fposmod(t * 60.0 + i * 11.0, 18.0))
					draw_circle(tip, 3.0 - i * 0.6, Color(col.lightened(0.3), 0.7))
				if not fire:
					for i in 4:
						var y := -fposmod(t * 200.0 + i * 37.0, hh)
						DU.flat(self, DU.diamond(Vector2(sin(i * 3.0) * 10.0, y), Vector2(3, 4)), Color(0.9, 0.97, 1.0))
		"dart":
			# totem de pierre sculpté : visage grimaçant dont la bouche crache les fléchettes
			var stone := Color(0.44, 0.41, 0.38)
			var warm := fmod(t, period) > period - 0.5 and turn_t <= 0.0
			# pendant la rotation, le visage passe de l'autre côté à mi-course
			var fd := -dir if turn_t > 0.175 else dir
			if turn_t > 0.0:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(maxf(absf(cos(turn_t / 0.35 * PI)), 0.15), 1.0))
			DU.box(self, Rect2(-11, -40, 22, 40), stone)
			for k in 3:
				draw_line(Vector2(-11, -30 + k * 10), Vector2(11, -30 + k * 10), stone.darkened(0.45), 1.0)
			DU.box(self, Rect2(-14, -45, 28, 7), stone.lightened(0.1))
			DU.poly(self, PackedVector2Array([Vector2(-14, -45), Vector2(-9, -52), Vector2(9, -52), Vector2(14, -45)]), stone.darkened(0.1))
			# mousse et fissure
			draw_polyline(PackedVector2Array([Vector2(-6, -12), Vector2(-3, -6), Vector2(-7, 0)]), stone.darkened(0.55), 1.2)
			for k in 4:
				draw_circle(Vector2(-10 + k * 6, -44.5), 2.2, Color(0.35, 0.5, 0.35, 0.9))
			# yeux et sourcils sculptés
			var eye := Color(1.0, 0.55, 0.25) if warm else Color(0.35, 0.18, 0.12)
			draw_line(Vector2(fd * 1.0, -38), Vector2(fd * 9.0, -36), stone.darkened(0.6), 2.0)
			draw_circle(Vector2(fd * 5.0, -34.0), 2.4, Color(0.08, 0.06, 0.06))
			draw_circle(Vector2(fd * 5.0, -34.0), 1.4, eye)
			if warm:
				DU.glow(self, Vector2(fd * 5.0, -34.0), 8.0, eye, 0.5)
			# bouche : anneau de pierre, gueule qui rougeoit avant le tir
			var mouth := Vector2(fd * 9.0, -26.0)
			DU.ball(self, mouth, 6.0, stone.darkened(0.15))
			draw_circle(mouth, 4.0, Color(1.0, 0.45, 0.2) if warm else Color(0.07, 0.05, 0.05))
			if warm:
				DU.glow(self, mouth, 16.0, Color(1.0, 0.5, 0.2), 0.7)
				draw_circle(mouth, 2.0, Color(1.0, 0.85, 0.5))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"blade":
			# lame-pendule : pivot riveté, tige forgée, croissant d'acier à fil brillant
			var bp := blade_pos() - position
			var n := bp.normalized()
			var tan := Vector2(-n.y, n.x)
			draw_line(Vector2.ZERO, bp, Color(0.18, 0.18, 0.22), 4.5)
			draw_line(Vector2.ZERO, bp, Color(0.5, 0.5, 0.56), 2.2)
			for k in range(1, 5):
				var q := bp * (k / 5.0)
				draw_line(q - tan * 2.5, q + tan * 2.5, Color(0.3, 0.3, 0.35), 1.6)
			DU.box(self, Rect2(-10, -6, 20, 6), Color(0.32, 0.3, 0.32))
			DU.ball(self, Vector2.ZERO, 6.0, Color(0.42, 0.42, 0.48))
			draw_circle(Vector2.ZERO, 2.0, Color(0.15, 0.15, 0.18))
			var steel := Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.74, 0.77, 0.84)
			var crescent := PackedVector2Array()
			for k in 13:
				var a := lerpf(-1.25, 1.25, k / 12.0)
				crescent.append(bp + n * 4.0 + (n * cos(a) * 10.0 + tan * sin(a) * 22.0))
			for k in range(12, -1, -1):
				var a := lerpf(-1.1, 1.1, k / 12.0)
				crescent.append(bp - n * 2.0 + (n * cos(a) * 7.0 + tan * sin(a) * 17.0))
			DU.poly(self, crescent, steel)
			var edge := PackedVector2Array()
			for k in 11:
				var a := lerpf(-1.15, 1.15, k / 10.0)
				edge.append(bp + n * 4.0 + (n * cos(a) * 9.0 + tan * sin(a) * 21.0))
			draw_polyline(edge, Color(1, 1, 1, 0.75), 1.4)
			draw_circle(bp, 3.0, Color(0.3, 0.3, 0.35))
			# traînée de mouvement
			var sw := cos(t * 1.9 + phase)
			if absf(sw) > 0.5:
				draw_arc(Vector2.ZERO, bp.length() + 8.0, bp.angle() - 0.25 * signf(sw), bp.angle(), 8, Color(1, 1, 1, 0.18), 6.0)
		"stalactite":
			var base := Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.6, 0.56, 0.52)
			if state == "gone":
				var k := 1.0 - st_t / 5.0
				DU.flat(self, PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(0, 8 * k)]), Color(base, 0.6))
				return
			var off := Vector2(sin(t * 60.0) * 2.0, 0) if state == "shake" else Vector2.ZERO
			var pts := PackedVector2Array([off + Vector2(-11, 0), off + Vector2(-6, 6), off + Vector2(-5, 14), off + Vector2(-2, 24), off + Vector2(0, 33), off + Vector2(3, 22), off + Vector2(6, 10), off + Vector2(11, 0)])
			DU.poly(self, pts, base)
			draw_line(off + Vector2(-3, 2), off + Vector2(-0.5, 26), Color(1, 1, 1, 0.45), 1.6)
			for k in 3:
				draw_line(off + Vector2(-8 + k * 6, 3 + k * 2), off + Vector2(-6 + k * 6, 6 + k * 2), base.darkened(0.4), 1.0)
			# goutte qui perle à la pointe
			var dk := fposmod(t * 0.7, 1.0)
			draw_circle(off + Vector2(0, 33 + dk * 4.0), 1.4, Color(0.7, 0.85, 1.0, 0.8 * (1.0 - dk)))
			if state == "shake":
				for k in 4:
					var px := fposmod(t * 90.0 + k * 23.0, 22.0) - 11.0
					draw_rect(Rect2(Vector2(px, fposmod(t * 70.0 + k * 9.0, 18.0)), Vector2(2, 2)), base.darkened(0.3))

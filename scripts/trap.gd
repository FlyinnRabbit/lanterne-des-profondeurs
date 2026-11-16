extends Node2D
const DU = preload("res://scripts/draw_util.gd")
# Pièges en hauteur (créés depuis la carte) :
#  dart       (Z) : totem qui tire des fléchettes à hauteur de tête — s'accroupir pour les esquiver (ou parer)
#  blade      (U) : lame-pendule suspendue au plafond, son point bas passe juste au-dessus d'un héros accroupi
#  stalactite (V) : se décroche quand on passe dessous, se reforme ensuite
const Ch = preload("res://scripts/charms.gd")
var main
var kind := "dart"
var dir := 1.0           # sens de tir du totem
var floor_y := 0.0       # sol sous la lame
var t := 0.0
var period := 2.4
var hit_cd := 0.0
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
			if fmod(t, period) < fmod(t - delta, period):
				var on_screen: bool = absf(main.player.global_position.x - global_position.x) < 700.0
				# aucun tir pendant un combat de boss
				if on_screen and not (main.boss_started and not main.boss_dead):
					main.spawn_projectile(global_position + Vector2(dir * 14.0, -28.0), Vector2(dir * 300.0, 0),
						{"kind": "dart", "hostile": true, "radius": 5.0, "life": 2.6, "from_trap": true})
					Audio.sfx("spit", 0.15, -6.0)
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
					st_t -= delta
					if st_t <= 0.0:
						state = "idle"
						position = home
	queue_redraw()

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
		"dart":
			# totem de pierre sculpté : visage grimaçant dont la bouche crache les fléchettes
			var stone := Color(0.44, 0.41, 0.38)
			var warm := fmod(t, period) > period - 0.5
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
			draw_line(Vector2(dir * 1.0, -38), Vector2(dir * 9.0, -36), stone.darkened(0.6), 2.0)
			draw_circle(Vector2(dir * 5.0, -34.0), 2.4, Color(0.08, 0.06, 0.06))
			draw_circle(Vector2(dir * 5.0, -34.0), 1.4, eye)
			if warm:
				DU.glow(self, Vector2(dir * 5.0, -34.0), 8.0, eye, 0.5)
			# bouche : anneau de pierre, gueule qui rougeoit avant le tir
			var mouth := Vector2(dir * 9.0, -26.0)
			DU.ball(self, mouth, 6.0, stone.darkened(0.15))
			draw_circle(mouth, 4.0, Color(1.0, 0.45, 0.2) if warm else Color(0.07, 0.05, 0.05))
			if warm:
				DU.glow(self, mouth, 16.0, Color(1.0, 0.5, 0.2), 0.7)
				draw_circle(mouth, 2.0, Color(1.0, 0.85, 0.5))
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

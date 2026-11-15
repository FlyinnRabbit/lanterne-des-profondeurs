extends Node2D
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

func _ready() -> void:
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
				if on_screen:
					main.spawn_projectile(global_position + Vector2(dir * 14.0, -28.0), Vector2(dir * 300.0, 0),
						{"kind": "dart", "hostile": true, "radius": 5.0, "life": 2.6})
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
		if p.hp >= pass_hp and not p.dead and p.eq(Ch.LIGHT_STEP):
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
			# totem de pierre à la bouche sculptée, tourné vers dir
			var stone := Color(0.42, 0.4, 0.38)
			draw_rect(Rect2(-11, -40, 22, 40), stone)
			draw_rect(Rect2(-11, -40, 22, 40), stone.darkened(0.3), false, 2.0)
			draw_rect(Rect2(-13, -44, 26, 6), stone.lightened(0.1))
			var mouth := Vector2(dir * 9.0, -28.0)
			var warm := fmod(t, period) > period - 0.5
			draw_circle(mouth, 4.5, Color(1.0, 0.45, 0.2) if warm else Color(0.1, 0.08, 0.08))
			draw_circle(Vector2(dir * 3.0, -35.0), 2.0, Color(1.0, 0.6, 0.3, 0.8))
		"blade":
			var bp := blade_pos() - position
			draw_line(Vector2.ZERO, bp, Color(0.4, 0.4, 0.45), 2.0)
			draw_circle(Vector2.ZERO, 5.0, Color(0.35, 0.35, 0.4))
			var n := bp.normalized()
			var tan := Vector2(-n.y, n.x)
			draw_colored_polygon(PackedVector2Array([bp - tan * 20.0, bp + n * 10.0, bp + tan * 20.0, bp - n * 4.0]), Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.78, 0.8, 0.86))
			draw_line(bp - tan * 18.0 + n * 2.0, bp + tan * 18.0 + n * 2.0, Color(1, 1, 1, 0.6), 1.5)
		"stalactite":
			if state == "gone":
				var k := 1.0 - st_t / 5.0
				draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(0, 8 * k)]), Color(0.6, 0.56, 0.52, 0.6))
				return
			var off := Vector2(sin(t * 60.0) * 2.0, 0) if state == "shake" else Vector2.ZERO
			draw_colored_polygon(PackedVector2Array([off + Vector2(-10, 0), off + Vector2(10, 0), off + Vector2(0, 32)]), Color(1.0, 0.1, 0.85) if Settings.colorblind else Color(0.62, 0.58, 0.54))
			draw_line(off + Vector2(-3, 2), off + Vector2(0, 26), Color(0.8, 0.76, 0.7, 0.6), 2.0)

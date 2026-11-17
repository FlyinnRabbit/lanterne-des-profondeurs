extends "res://scripts/enemy.gd"
# Tisseuse : araignée embusquée au plafond, au bout de son fil.
#  • Suspendue, elle guette : quand le héros passe à portée en contrebas, elle se prépare puis
#    crache une boule de toile qui l'englue (course et saut ralentis ; la ruée arrache la toile).
#    La toile qui rate reste collée au sol un moment.
#  • Si le héros passe juste dessous, elle se laisse tomber sur lui.
#  • Au sol, elle bondit sur lui, puis, s'il s'éloigne, remonte le long de son fil pour se cacher.
#  Élite : crache trois boules en éventail et remonte plus vite.

var anchor := Vector2.ZERO
var hanging := true
var dir := -1.0
var state := "hang"        # hang, windup_web, drop, ground, windup_leap, leap, climb
var state_t := 0.0
var web_cd := 1.0
const HANG_Y := 30.0
var hp_seen := 0

func _ready() -> void:
	size = Vector2(28, 20)
	hp = 3
	geo_value = 4
	setup_body()
	if display:
		return
	# cherche le plafond au-dessus d'elle et s'y accroche
	var y := global_position.y
	for i in 12:
		if main.is_solid_at(Vector2(global_position.x, y - 32.0)):
			break
		y -= 32.0
	anchor = Vector2(global_position.x, floorf(y / 32.0) * 32.0)
	global_position.y = anchor.y + HANG_Y
	anim_t = randf() * 5.0
	hp_seen = hp
	web_cd = randf_range(0.6, 1.6)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _go(s: String, t: float) -> void:
	state = s
	state_t = t

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	web_cd -= delta
	var p = main.player
	var alive_p: bool = p != null and not p.dead
	hanging = state in ["hang", "windup_web", "climb"]
	if stun_t > 0.0 and hanging:
		_fall()
	match state:
		"hang", "windup_web":
			global_position = Vector2(anchor.x + sin(anim_t * 1.3) * 3.0, anchor.y + HANG_Y + sin(anim_t * 2.0) * 4.0)
			if knock.length() > 10.0 or hp < hp_seen:
				_fall()                         # touchée : elle lâche son fil
			elif state == "windup_web":
				if state_t <= 0.0:
					_spit(p)
					web_cd = (2.4 if not elite else 1.9) / aggro()
					_go("hang", 0.0)
			elif alive_p:
				var dx: float = absf(p.global_position.x - global_position.x)
				var below: bool = p.global_position.y > global_position.y + 20.0
				if below and dx < (60.0 if not elite else 90.0) * aggro():
					_fall()
				elif below and dx < 300.0 and web_cd <= 0.0 and p.global_position.y - global_position.y < 360.0 \
						and not main.wall_between(global_position, p.global_position):
					_go("windup_web", 0.45)
			queue_redraw()
			return
		"climb":
			# remonte le fil, à l'abri
			velocity = Vector2(0, -(150.0 if not elite else 220.0))
			move_and_slide()
			if global_position.y <= anchor.y + HANG_Y or is_on_ceiling():
				global_position.y = anchor.y + HANG_Y
				anchor.x = global_position.x
				web_cd = 0.8
				hp_seen = hp
				motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
				_go("hang", 0.0)
			queue_redraw()
			return
	# au sol (ou en l'air après une chute / un bond)
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
	elif state == "windup_leap":
		velocity.x = 0.0
		if state_t <= 0.0 and alive_p:
			var dx2: float = p.global_position.x - global_position.x
			velocity = Vector2(clampf(dx2 * 2.2, -380.0, 380.0) * spd(), -520.0)
			_go("leap", 0.6)
	elif state == "leap":
		if is_on_floor() and state_t < 0.45:
			_go("ground", 0.8)
	elif alive_p and is_on_floor():
		var dx3: float = p.global_position.x - global_position.x
		dir = signf(dx3) if dx3 != 0.0 else dir
		if absf(dx3) > 260.0 and state_t <= 0.0 and _thread_free():
			_go("climb", 0.0)             # la proie s'éloigne : retour au plafond
		elif absf(dx3) < 150.0 and absf(p.global_position.y - global_position.y) < 80.0 and state_t <= 0.0:
			_go("windup_leap", 0.4)       # bond sur le héros
		else:
			velocity.x = dir * 115.0 * spd()
			if is_on_wall():
				velocity.y = -420.0
	if state == "drop" and is_on_floor():
		_go("ground", 0.6)
	move_and_slide()
	queue_redraw()

func _fall() -> void:
	if state in ["drop", "ground", "leap", "windup_leap"]:
		return
	_go("drop", 0.0)
	motion_mode = CharacterBody2D.MOTION_MODE_GROUNDED
	velocity = Vector2.ZERO
	main.spawn_burst(global_position, Color(0.85, 0.85, 0.9), 6, 80.0)

# le fil est-il encore libre jusqu'au plafond (pas de mur entre elle et son ancre) ?
func _thread_free() -> bool:
	anchor.x = global_position.x
	var y := global_position.y
	for i in 14:
		y -= 32.0
		if main.is_solid_at(Vector2(global_position.x, y)):
			anchor.y = floorf(y / 32.0) * 32.0 + 32.0
			return y < global_position.y - 64.0
	return false

func _spit(p) -> void:
	if p == null:
		return
	var from := global_position + Vector2(0, 8)
	var to: Vector2 = p.global_position + Vector2(0, -10) + p.velocity * 0.15
	var sp := 300.0 * spd()
	# vise un peu plus haut pour compenser la retombée de la toile
	var tt := from.distance_to(to) / sp
	to.y -= 0.5 * 300.0 * tt * tt
	var d := (to - from).normalized()
	main.spawn_projectile(from, d * sp, {"kind": "web", "radius": 8.0, "gravity": 300.0, "life": 3.0})
	if elite:
		main.spawn_projectile(from, d.rotated(0.3) * sp, {"kind": "web", "radius": 8.0, "gravity": 300.0, "life": 3.0})
		main.spawn_projectile(from, d.rotated(-0.3) * sp, {"kind": "web", "radius": 8.0, "gravity": 300.0, "life": 3.0})
	Audio.sfx("spit", 0.15, -4.0)

func _draw() -> void:
	if hanging or display:
		draw_line(Vector2(0, -10), Vector2(0, -26) if display else anchor - global_position, Color(0.85, 0.85, 0.95, 0.6), 1.0)
	if state == "windup_web":
		var pulse := 0.5 + 0.5 * sin(anim_t * 30.0)
		DU.glow(self, Vector2(0, 6), 14.0, Color(0.95, 0.95, 1.0), 0.35 + 0.3 * pulse)
	var body := body_color(Color(0.24, 0.21, 0.3))
	var walk := sin(anim_t * (18.0 if absf(velocity.x) > 5.0 else 3.0)) * 3.0
	# huit pattes à trois segments, les plus lointaines plus sombres
	for k in [-1.0, 1.0]:
		for i in 4:
			var bx: float = k * (3 + i * 2.5)
			var kx: float = k * (13 + i * 4)
			var ky := -8.0 + i * 3.0 + (walk if i % 2 == 0 else -walk)
			var col := body.darkened(0.25 if i % 2 == 0 else 0.0)
			draw_line(Vector2(bx, -2), Vector2(kx, ky - 6), col, 2.2)
			draw_line(Vector2(kx, ky - 6), Vector2(kx + k * 4, ky + 4), col, 1.8)
			draw_line(Vector2(kx + k * 4, ky + 4), Vector2(kx + k * 5, ky + 10), col, 1.2)
			draw_circle(Vector2(kx, ky - 6), 1.3, col.lightened(0.15))
	# abdomen à motif en sablier
	DU.poly(self, DU.ellipse(Vector2(0, 2), Vector2(11, 10), 22), body)
	DU.flat(self, PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(0, 2), Vector2(3, 6), Vector2(-3, 6), Vector2(0, 2)]), Color(0.85, 0.2, 0.25))
	for i in 6:
		var a := i * TAU / 6.0
		draw_line(Vector2(cos(a) * 9.0, 2 + sin(a) * 8.0), Vector2(cos(a) * 11.5, 2 + sin(a) * 10.0), body.lightened(0.2), 0.8)
	# céphalothorax, crochets, grappe d'yeux
	DU.poly(self, DU.ellipse(Vector2(0, -10), Vector2(7, 6), 18), body.lightened(0.05))
	for k in [-1.0, 1.0]:
		draw_line(Vector2(k * 2, -6), Vector2(k * 3, -2), Color(0.75, 0.7, 0.6), 1.6)
	for i in 4:
		draw_circle(Vector2(-4.5 + i * 3, -12 + (i % 2)), 1.4, Color(1.0, 0.3, 0.3))
	draw_circle(Vector2(-1.5, -14.5), 1.0, Color(1.0, 0.45, 0.4))
	draw_circle(Vector2(1.5, -14.5), 1.0, Color(1.0, 0.45, 0.4))
	DU.glow(self, Vector2(0, -12), 9.0, Color(1, 0.3, 0.3), 0.3)

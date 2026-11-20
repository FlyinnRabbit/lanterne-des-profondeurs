extends "res://scripts/enemy.gd"
# Diablotin de braise (Forge Ardente) : petit démon de cendre qui sautille à distance et lance
# des boules de braise en cloche. Élite : deux braises par lancer.

var face := -1.0
var hop_t := 1.0
var throw_t := 1.5
var windup := 0.0

func _ready() -> void:
	size = Vector2(22, 24)
	hp = 2
	geo_value = 3
	setup_body()
	hop_t = randf_range(0.4, 1.2)
	throw_t = randf_range(1.0, 2.0)

func telegraph() -> int:
	return 1 if windup > 0.0 and stun_t <= 0.0 else 0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	var near: bool = p and not p.dead and p.global_position.distance_to(global_position) < 380.0 * aggro() and not main.wall_between(global_position, p.global_position)
	if near:
		face = -1.0 if p.global_position.x < global_position.x else 1.0
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
		windup = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		if windup <= 0.0 and p:
			var dx: float = p.global_position.x - global_position.x
			for k in (2 if elite else 1):
				var t := 0.75 + k * 0.15
				var vx := dx / t
				var vy: float = (p.global_position.y - global_position.y - 0.5 * 900.0 * t * t) / t
				main.spawn_projectile(global_position + Vector2(0, -10), Vector2(vx, vy).limit_length(620.0),
					{"kind": "drop", "hostile": true, "radius": 6.0, "gravity": 900.0, "life": 2.5, "goo_color": Color(1.0, 0.5, 0.15)})
			Audio.sfx("spit", 0.2, -6.0)
	elif is_on_floor():
		knock = Vector2.ZERO
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		hop_t -= delta
		throw_t -= delta
		if near and throw_t <= 0.0:
			windup = 0.45
			throw_t = randf_range(1.8, 2.6) / aggro()
		elif hop_t <= 0.0:
			# sautille en gardant ses distances (recule si le héros est trop près)
			var away := -face if near and absf(p.global_position.x - global_position.x) < 150.0 else face * (1.0 if randf() < 0.5 else -1.0)
			if not main.is_solid_at(global_position + Vector2(away * 40.0, 30.0)):
				away = -away
			velocity = Vector2(away * 150.0 * spd(), -420.0)
			hop_t = randf_range(0.6, 1.1)
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(1.0, 0.45, 0.15)

func _draw() -> void:
	var f := face
	var body := body_color(Color(0.3, 0.12, 0.08))
	var glow := Color(1.0, 0.55, 0.15)
	DU.glow(self, Vector2(0, 0), 20.0, glow, 0.25)
	var sq := 1.0 + (0.15 if windup > 0.0 else 0.0)
	DU.flat(self, DU.ellipse(Vector2(0, 2), Vector2(10, 11 / sq)), body)
	# fissures de braise
	draw_line(Vector2(-4, -2), Vector2(-1, 4), glow, 1.4)
	draw_line(Vector2(3, -4), Vector2(1, 2), glow, 1.2)
	# cornes et yeux
	for sd in [-1.0, 1.0]:
		DU.flat(self, PackedVector2Array([Vector2(sd * 5, -7), Vector2(sd * 9, -15), Vector2(sd * 3, -9)]), body.darkened(0.3))
	draw_circle(Vector2(f * 3, -2), 2.2, Color(1.0, 0.85, 0.3))
	draw_circle(Vector2(f * -2, -2), 1.8, Color(1.0, 0.85, 0.3))
	# braise dans la main pendant la préparation
	if windup > 0.0:
		DU.glow(self, Vector2(f * 10, -10), 14.0, glow, 0.6)
		draw_circle(Vector2(f * 10, -10), 4.0, Color(1.0, 0.7, 0.3))
	# petites pattes
	draw_line(Vector2(-4, 11), Vector2(-5, 13), body, 2.4)
	draw_line(Vector2(4, 11), Vector2(5, 13), body, 2.4)
	draw_stun(-20.0)

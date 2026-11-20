extends "res://scripts/enemy.gd"
# Grimoire volant (Bibliothèque Silencieuse) : un livre maudit qui flotte à distance, s'ouvre
# en grand puis lâche une volée de pages tranchantes (parables). Élite : deux volées.

var home := Vector2.ZERO
var cast_t := 2.0
var windup := 0.0
var volleys := 0
var face := -1.0

func _ready() -> void:
	size = Vector2(30, 24)
	hp = 3
	geo_value = 3
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = global_position
	anim_t = randf() * 10.0
	cast_t = randf_range(1.0, 2.5)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	var target := home + Vector2(sin(anim_t * 0.6) * 30.0, sin(anim_t * 1.3) * 12.0)
	var near: bool = p and not p.dead and p.global_position.distance_to(global_position) < 360.0 * aggro() \
		and not main.wall_between(global_position, p.global_position)
	if near:
		face = -1.0 if p.global_position.x < global_position.x else 1.0
		# garde ses distances : se place à ~190 px du héros, un peu au-dessus
		var want: Vector2 = p.global_position + Vector2(-face * 190.0, -70.0)
		target = target.lerp(want, 0.8)
	if absf(knock.x) > 10.0 or absf(knock.y) > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1500.0 * delta)
	elif stun_t > 0.0:
		velocity = Vector2.ZERO
		windup = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		if windup <= 0.0 and p:
			var d0: Vector2 = (p.global_position + Vector2(0, -8) - global_position).normalized()
			for k in 3:
				main.spawn_projectile(global_position, d0.rotated((k - 1) * 0.3) * 250.0 * spd(),
					{"kind": "page", "hostile": true, "radius": 6.0, "life": 2.2})
			Audio.sfx("whip", 0.2, -6.0)
			if volleys > 0:
				volleys -= 1
				windup = 0.35
	else:
		velocity = velocity.move_toward((target - global_position).limit_length(120.0) * 2.0, 400.0 * delta)
		if near:
			cast_t -= delta
			if cast_t <= 0.0:
				windup = 0.6
				volleys = 1 if elite else 0
				cast_t = randf_range(2.2, 3.0) / aggro()
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(0.9, 0.85, 0.7)

func die() -> void:
	main.spawn_burst(global_position, Color(0.95, 0.9, 0.75), 16, 200.0, 120.0)
	super.die()

func _draw() -> void:
	var open := 0.25 + 0.1 * sin(anim_t * 3.0)
	if windup > 0.0:
		open = 1.0
	var cov := body_color(Color(0.42, 0.14, 0.18) if not elite else Color(0.3, 0.1, 0.35))
	var pg := body_color(Color(0.93, 0.88, 0.72))
	var bob := sin(anim_t * 2.5) * 2.0
	var c := Vector2(0, bob)
	# deux plats de couverture qui s'ouvrent autour du dos
	var a := open * 1.2
	for sd in [-1.0, 1.0]:
		var tip := c + Vector2(sd * 16.0 * cos(a * 0.6), -16.0 * sin(a * 0.6) - 2.0)
		DU.flat(self, PackedVector2Array([c + Vector2(0, 8), c + Vector2(0, -8), tip + Vector2(0, -8), tip + Vector2(0, 8)]), cov)
		# pages
		DU.flat(self, PackedVector2Array([c + Vector2(0, 7), c + Vector2(0, -7), tip * 0.9 + Vector2(0, -6), tip * 0.9 + Vector2(0, 6)]), pg)
		for i in 3:
			var y := -4.0 + i * 4.0
			draw_line(c + Vector2(sd * 3, y), (tip * 0.85) + Vector2(-sd * 2, y), Color(0.4, 0.35, 0.3, 0.6), 1.0)
	# dos, fermoir et œil
	draw_rect(Rect2(c + Vector2(-2.5, -9), Vector2(5, 18)), cov.darkened(0.3))
	draw_circle(c + Vector2(0, 0), 3.4, Color(1.0, 0.8, 0.3))
	draw_circle(c + Vector2(0, 0), 1.5, Color(0.25, 0.05, 0.05))
	if windup > 0.0:
		DU.glow(self, c, 26.0, Color(1.0, 0.6, 0.3), 0.4)
	draw_stun(-22.0)

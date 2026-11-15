extends "res://scripts/enemy.gd"
# Volant : moucheron épineux qui flotte et fonce sur le joueur quand il le repère.

const ACCEL := 520.0
const CHASE_SPEED := 175.0
var home := Vector2.ZERO
var dive_cd := 2.0     # élite : piqué sur le joueur
var dive_t := 0.0
var dive_windup := 0.0
var dive_dir := Vector2.ZERO

func _ready() -> void:
	size = Vector2(26, 24)
	hp = 2
	geo_value = 2
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = global_position
	anim_t = randf() * 10.0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	var target := home + Vector2(sin(anim_t * 0.8) * 40.0, sin(anim_t * 1.7) * 16.0)
	var speed := 60.0
	if p and not p.dead and p.global_position.distance_to(global_position) < 330.0 * aggro():
		target = p.global_position + Vector2(0, -6)
		speed = CHASE_SPEED * spd()
		if elite:
			dive_cd -= delta
			if dive_cd <= 0.0 and dive_windup <= 0.0 and dive_t <= 0.0:
				dive_windup = 0.4
				dive_cd = 2.5 / aggro()
	if dive_windup > 0.0:
		dive_windup -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		flash_t = 0.05 if fmod(anim_t, 0.1) < 0.05 else 0.0
		if dive_windup <= 0.0 and p:
			dive_dir = (p.global_position - global_position).normalized()
			dive_t = 0.35
		move_and_slide()
		queue_redraw()
		return
	if dive_t > 0.0:
		dive_t -= delta
		velocity = dive_dir * 480.0 * spd()
		move_and_slide()
		queue_redraw()
		return
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity = velocity.move_toward(Vector2(0, 40), ACCEL * delta)
	else:
		knock = Vector2.ZERO
		velocity = velocity.move_toward((target - global_position).normalized() * speed, ACCEL * spd() * delta)
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var f := -1.0 if velocity.x < 0.0 else 1.0
	var flap := absf(sin(anim_t * 30.0))
	# Ailes translucides
	draw_colored_polygon(DU.ellipse(Vector2(-4, -12), Vector2(7, 3 + 6 * flap), 14), Color(0.75, 0.9, 1.0, 0.35))
	draw_colored_polygon(DU.ellipse(Vector2(5, -12), Vector2(7, 3 + 6 * flap), 14), Color(0.75, 0.9, 1.0, 0.35))
	# Corps
	draw_colored_polygon(DU.ellipse(Vector2.ZERO, Vector2(12, 10), 20), body_color(Color(0.42, 0.3, 0.38)))
	# Épines
	for i in 4:
		var a := PI * 0.6 + i * 0.35
		var base := Vector2(cos(a) * -f * 10.0, sin(a) * 8.0)
		draw_line(base, base * 1.6, body_color(Color(0.25, 0.18, 0.22)), 2.0)
	# Dard
	draw_colored_polygon(PackedVector2Array([Vector2(-f * 10, 3), Vector2(-f * 20, 6), Vector2(-f * 10, 7)]), body_color(Color(0.85, 0.8, 0.7)))
	# Œil
	draw_circle(Vector2(f * 5, -2), 4.0, Color(0.05, 0.03, 0.05))
	draw_circle(Vector2(f * 6, -2), 2.0, Color(1.0, 0.45, 0.3))

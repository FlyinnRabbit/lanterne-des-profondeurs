extends "res://scripts/enemy.gd"
# Baudroie des profondeurs : poisson des grottes qui nage dans l'air humide, un leurre lumineux
# au bout de sa tige. Il dérive, se fige en ouvrant la gueule, puis fonce sur le héros.
# Élite : deux charges.

var home := Vector2.ZERO
var face := -1.0
var windup := 0.0
var dash_t := 0.0
var dash_v := Vector2.ZERO
var dash_cd := 2.0
var charges := 0
var lure: PointLight2D

func _ready() -> void:
	size = Vector2(32, 24)
	hp = 3
	geo_value = 4
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = global_position
	anim_t = randf() * 10.0
	if main and not display:
		lure = main.make_light(Color(0.55, 0.9, 1.0), 0.5, 0.7)
		add_child(lure)

func telegraph() -> int:
	return 1 if windup > 0.0 and stun_t <= 0.0 else 0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	var near: bool = p and not p.dead and p.global_position.distance_to(global_position) < 300.0 * aggro() and not main.wall_between(global_position, p.global_position)
	if lure:
		lure.position = Vector2(face * 22.0, -18.0 + sin(anim_t * 3.0) * 2.0)
	if absf(knock.x) > 10.0 or absf(knock.y) > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1500.0 * delta)
		dash_t = 0.0
	elif stun_t > 0.0:
		velocity = Vector2.ZERO
		windup = 0.0
		dash_t = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		if windup <= 0.0 and p:
			dash_v = (p.global_position - global_position).normalized() * 420.0 * spd()
			dash_t = 0.45
			Audio.sfx("dash", 0.2, -8.0)
	elif dash_t > 0.0:
		dash_t -= delta
		velocity = dash_v
		if dash_t <= 0.0 and charges > 0:
			charges -= 1
			windup = 0.3
	else:
		knock = Vector2.ZERO
		var target := home + Vector2(sin(anim_t * 0.5) * 50.0, sin(anim_t * 1.1) * 14.0)
		if near:
			face = -1.0 if p.global_position.x < global_position.x else 1.0
			target = p.global_position + Vector2(-face * 150.0, -30.0)
			dash_cd -= delta
			if dash_cd <= 0.0:
				windup = 0.55
				charges = 1 if elite else 0
				dash_cd = randf_range(2.2, 3.0) / aggro()
		else:
			face = signf(target.x - global_position.x) if absf(target.x - global_position.x) > 4.0 else face
		velocity = velocity.move_toward((target - global_position).limit_length(90.0) * 1.6, 300.0 * delta)
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(0.35, 0.45, 0.6)

func _draw() -> void:
	var f := face
	var body := body_color(Color(0.2, 0.26, 0.36) if not elite else Color(0.3, 0.18, 0.32))
	var belly := body.lightened(0.25)
	var gape := 1.0 if windup > 0.0 or dash_t > 0.0 else 0.25 + 0.1 * sin(anim_t * 2.0)
	# queue
	var tail := Vector2(-f * 18, 0)
	DU.flat(self, PackedVector2Array([tail, tail + Vector2(-f * 10, -9 + sin(anim_t * 8.0) * 2), tail + Vector2(-f * 10, 9 + sin(anim_t * 8.0) * 2)]), body.darkened(0.2))
	# corps
	DU.flat(self, DU.ellipse(Vector2(0, 0), Vector2(18, 12)), body)
	DU.flat(self, DU.ellipse(Vector2(f * 2, 5), Vector2(12, 5)), belly)
	# gueule et dents
	var m0 := Vector2(f * 12, 2)
	DU.flat(self, PackedVector2Array([m0 + Vector2(-f * 4, -3 * gape), m0 + Vector2(f * 8, -6 * gape), m0 + Vector2(f * 8, 6 * gape), m0 + Vector2(-f * 4, 3 * gape)]), Color(0.08, 0.05, 0.08))
	for i in 3:
		var tx := m0.x + f * (1 + i * 2.5)
		draw_line(Vector2(tx, m0.y - 5 * gape), Vector2(tx, m0.y - 2 * gape), Color(0.95, 0.95, 0.9), 1.2)
		draw_line(Vector2(tx, m0.y + 5 * gape), Vector2(tx, m0.y + 2 * gape), Color(0.95, 0.95, 0.9), 1.2)
	# œil
	draw_circle(Vector2(f * 5, -5), 3.0, Color(0.9, 0.95, 0.7))
	draw_circle(Vector2(f * 5.6, -5), 1.4, Color(0.05, 0.05, 0.05))
	# tige et leurre
	var tip := Vector2(f * 22, -18 + sin(anim_t * 3.0) * 2.0)
	draw_polyline(PackedVector2Array([Vector2(f * 2, -11), Vector2(f * 10, -20), tip]), body.lightened(0.15), 1.4)
	DU.glow(self, tip, 14.0, Color(0.55, 0.9, 1.0), 0.6)
	draw_circle(tip, 3.0, Color(0.8, 1.0, 1.0))
	draw_stun(-22.0)

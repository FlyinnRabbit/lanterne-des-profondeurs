extends "res://scripts/enemy.gd"
# Squelette (Ossuaire) : soldat d'os qui marche vers le héros et frappe de son glaive. Abattu, il
# s'effondre en tas d'os… et se relève au bout de quelques secondes, sauf si on frappe le tas.
# Élite : se relève deux fois.

const SPEED := 60.0
var dir := -1
var windup := 0.0
var swing_t := 0.0
var swing_cd := 0.0
var pile_t := 0.0      # effondré (tas d'os inoffensif)
var rises := 1

func _ready() -> void:
	size = Vector2(22, 40)
	hp = 3
	geo_value = 4
	setup_body()
	rises = 2 if elite else 1

func is_harmful() -> bool:
	return super.is_harmful() and pile_t <= 0.0

func telegraph() -> int:
	return 1 if windup > 0.0 and stun_t <= 0.0 else 0

func take_hit(dmg: int, d: Vector2) -> void:
	if pile_t > 0.0:
		# le tas est frappé : il ne se relèvera plus
		rises = 0
		hp = 0
		super.take_hit(1, d)
		return
	hp -= dmg
	if hp <= 0 and rises > 0:
		rises -= 1
		pile_t = 3.0
		hp = maxi(2, hp_max / 2)
		main.spawn_burst(global_position + Vector2(0, 10), Color(0.85, 0.8, 0.68), 12, 160.0)
		Audio.sfx("kill", 0.2, -6.0)
		flash_t = 0.12
		windup = 0.0
		swing_t = 0.0
		return
	hp += dmg
	super.take_hit(dmg, d)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if pile_t > 0.0:
		pile_t -= delta
		velocity.x = 0.0
		if pile_t <= 0.0:
			flash_t = 0.15
			Audio.sfx("door", 0.2, -10.0)
	elif absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
		windup = 0.0
	elif windup > 0.0:
		windup -= delta
		velocity.x = 0.0
		if windup <= 0.0:
			swing_t = 0.25
			Audio.sfx("slash", 0.2, -8.0)
	elif swing_t > 0.0:
		swing_t -= delta
		velocity.x = dir * 90.0
		if p and Rect2(global_position + Vector2(dir * 10.0 * reach - (34.0 * reach if dir < 0 else 0.0), -22 * reach), Vector2(34, 34) * reach).intersects(p.get_rect()):
			p.receive_hit(global_position, self)
	else:
		knock = Vector2.ZERO
		swing_cd -= delta
		var near: bool = p and not p.dead and absf(p.global_position.y - global_position.y) < 60.0 * reach and absf(p.global_position.x - global_position.x) < 320.0 * aggro()
		if near:
			dir = -1 if p.global_position.x < global_position.x else 1
			if absf(p.global_position.x - global_position.x) < 56.0 * reach and swing_cd <= 0.0:
				windup = 0.45 if not elite else 0.32
				swing_cd = 1.4 / aggro()
		velocity.x = dir * SPEED * spd() * (1.0 if near else 0.6)
		if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 16.0, size.y / 2.0 + 8.0)):
			dir = -dir
			velocity.x = 0.0
	move_and_slide()
	if is_on_wall() and pile_t <= 0.0:
		dir = -dir
	queue_redraw()

func fx_color() -> Color:
	return Color(0.85, 0.8, 0.68)

func _draw() -> void:
	var bone := body_color(Color(0.86, 0.82, 0.7))
	var dark := Color(0.2, 0.17, 0.14)
	var f := float(dir)
	if pile_t > 0.0:
		# tas d'os qui tremble avant de se relever
		var sh := sin(anim_t * 40.0) * (1.5 if pile_t < 0.8 else 0.0)
		for i in 5:
			var a := i * 0.9
			draw_line(Vector2(-12 + i * 6 + sh, 18), Vector2(-6 + i * 5 + sh, 14 - (i % 2) * 3), bone, 2.6)
		draw_circle(Vector2(4 + sh, 13), 6.0, bone)
		draw_circle(Vector2(2 + sh, 12), 1.6, dark)
		return
	var walk := sin(anim_t * 9.0) * (3.0 if absf(velocity.x) > 5.0 else 0.0)
	# jambes
	draw_line(Vector2(-3, 6), Vector2(-4 + walk, 20), bone, 2.4)
	draw_line(Vector2(3, 6), Vector2(4 - walk, 20), bone, 2.4)
	# bassin, colonne et côtes
	draw_line(Vector2(-5, 6), Vector2(5, 6), bone, 2.6)
	draw_line(Vector2(0, 6), Vector2(0, -10), bone, 2.2)
	for i in 3:
		var y := -8.0 + i * 4.0
		draw_arc(Vector2(0, y + 2), 6.0 - i, PI * 1.1, PI * 1.9, 6, bone, 1.6)
	# crâne
	draw_circle(Vector2(f * 1, -16), 6.5, bone)
	draw_rect(Rect2(Vector2(f * 1 - 4, -12), Vector2(8, 4)), bone)
	draw_circle(Vector2(f * 3.5, -17), 1.8, Color(1.0, 0.35, 0.2) if elite else dark)
	draw_circle(Vector2(f * -1, -17), 1.8, Color(1.0, 0.35, 0.2) if elite else dark)
	# bras et glaive
	var ang := -0.6
	if windup > 0.0:
		ang = -2.2
	elif swing_t > 0.0:
		ang = 0.9
	var sh2 := Vector2(f * 4, -6)
	var hand := sh2 + Vector2(f * cos(ang), sin(ang)) * 10.0
	draw_line(sh2, hand, bone, 2.2)
	var blade := hand + Vector2(f * cos(ang), sin(ang)) * 20.0
	draw_line(hand, blade, Color(0.65, 0.62, 0.58), 3.0)
	draw_line(hand - Vector2(-sin(ang) * f, cos(ang)) * 4.0, hand + Vector2(-sin(ang) * f, cos(ang)) * 4.0, Color(0.45, 0.35, 0.2), 2.0)
	if swing_t > 0.0:
		draw_arc(sh2, 28.0, -1.0 if f > 0 else PI - 0.2, 1.0 if f > 0 else PI + 1.2, 10, Color(1, 1, 1, 0.5), 2.0)
	draw_stun(-30.0)

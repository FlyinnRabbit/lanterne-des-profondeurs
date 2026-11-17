extends "res://scripts/enemy.gd"
# Mite-éteignoir : papillon de nuit attiré par la lanterne du héros. Tant qu'elle tourne autour
# de lui, la lumière se resserre et tout s'assombrit. Fragile, mais son vol est erratique ;
# de temps en temps, elle fonce sur lui. Arrive par deux ou trois.
# Élite : plus résistante, assombrit davantage.

var home := Vector2.ZERO
var orbit_a := 0.0
var orbit_r := 60.0
var dart_t := 0.0
var dart_cd := 2.0
var windup_t := 0.0
var dart_dir := Vector2.ZERO

func _ready() -> void:
	size = Vector2(20, 16)
	hp = 1
	geo_value = 2
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = global_position
	anim_t = randf() * 10.0
	orbit_a = randf() * TAU
	orbit_r = randf_range(50.0, 80.0)
	dart_cd = randf_range(1.5, 3.0)

# assombrissement apporté par cette mite (0 : aucun)
func dim() -> float:
	if dead or display or main.player == null:
		return 0.0
	var d: float = main.player.global_position.distance_to(global_position)
	return clampf(1.0 - (d - 90.0) / 160.0, 0.0, 1.0) * (0.55 if not elite else 0.75)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	dart_cd -= delta
	var p = main.player
	var near: bool = p != null and not p.dead and p.global_position.distance_to(global_position) < 360.0 * aggro()
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1300.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity = velocity.move_toward(Vector2(0, 50), 500.0 * delta)
	elif windup_t > 0.0:
		windup_t -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		if windup_t <= 0.0 and p:
			dart_dir = (p.global_position + Vector2(0, -8) - global_position).normalized()
			dart_t = 0.3
	elif dart_t > 0.0:
		dart_t -= delta
		velocity = dart_dir * 380.0 * spd()
	else:
		knock = Vector2.ZERO
		var target := home + Vector2(sin(anim_t * 0.9) * 50.0, sin(anim_t * 1.6) * 20.0)
		var sp := 70.0
		if near:
			# vol en cercle autour de la lanterne, avec des écarts brusques
			orbit_a += delta * (2.2 + sin(anim_t * 3.1) * 1.2)
			var r := orbit_r + sin(anim_t * 5.3) * 18.0
			target = p.global_position + Vector2(0, -16) + Vector2(cos(orbit_a), sin(orbit_a) * 0.7) * r
			sp = 230.0 * spd()
			if dart_cd <= 0.0 and not main.wall_between(global_position, p.global_position):
				windup_t = 0.35
				dart_cd = randf_range(2.2, 3.6) / aggro()
		var jitter := Vector2(sin(anim_t * 23.0), cos(anim_t * 19.0)) * 60.0
		velocity = velocity.move_toward((target - global_position).normalized() * sp + jitter, 900.0 * delta)
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(0.7, 0.65, 0.55)

func _draw() -> void:
	var flap := sin(anim_t * 32.0)
	var wing := body_color(Color(0.62, 0.56, 0.46))
	var dark := body_color(Color(0.3, 0.26, 0.22))
	# poussière d'écailles qui tombe
	for i in 3:
		var u := fposmod(anim_t * 0.8 + i * 0.33, 1.0)
		draw_circle(Vector2(sin(i * 2.0 + anim_t) * 6.0, 4.0 + u * 22.0), 1.0, Color(0.85, 0.8, 0.65, 0.5 * (1.0 - u)))
	# ailes : avant (grandes, ocelles) et arrière, qui battent
	for s in [-1.0, 1.0]:
		var spread := 0.55 + 0.45 * flap
		var fw := PackedVector2Array([Vector2(0, -2), Vector2(s * 14.0 * spread, -11.0), Vector2(s * 17.0 * spread, -3.0), Vector2(s * 10.0 * spread, 2.0)])
		DU.flat(self, fw, wing)
		var hw := PackedVector2Array([Vector2(0, 1), Vector2(s * 11.0 * spread, 3.0), Vector2(s * 8.0 * spread, 9.0), Vector2(s * 2.0, 6.0)])
		DU.flat(self, hw, wing.darkened(0.2))
		var oc := Vector2(s * 11.0 * spread, -5.0)
		draw_circle(oc, 2.6 * spread + 0.4, dark)
		draw_circle(oc, 1.2 * spread + 0.2, Color(0.95, 0.75, 0.4) if windup_t <= 0.0 else Color(1.0, 0.4, 0.3))
	# corps velu et antennes plumeuses
	DU.poly(self, DU.ellipse(Vector2(0, 1), Vector2(3.5, 8)), dark.lightened(0.15))
	for i in 3:
		draw_line(Vector2(-3, -2 + i * 3), Vector2(3, -2 + i * 3), dark, 0.8)
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 1.0, -6), Vector2(s * 6.0, -13), dark, 1.0)
		for k in 3:
			var q := Vector2(s * (2.0 + k * 1.5), -8.0 - k * 2.0)
			draw_line(q, q + Vector2(s * 2.0, 1.0), dark, 0.7)
	draw_circle(Vector2(-1.5, -5), 1.0, Color(0.95, 0.6, 0.3))
	draw_circle(Vector2(1.5, -5), 1.0, Color(0.95, 0.6, 0.3))
	draw_stun(-18.0)

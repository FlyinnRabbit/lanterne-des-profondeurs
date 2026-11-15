extends "res://scripts/enemy.gd"
# Rampant : petit scarabée à carapace pâle qui patrouille et fait demi-tour au bord du vide.

const SPEED := 70.0
var dir := -1
var lunge_t := 0.0     # élite : ruée vers le joueur
var lunge_cd := 0.0
var windup_t := 0.0

func _ready() -> void:
	size = Vector2(30, 22)
	hp = 3
	geo_value = 3
	setup_body()
	floor_snap_length = 6.0

func _physics_process(delta: float) -> void:
	flash_t -= delta
	stun_t -= delta
	if stun_t <= 0.0:
		anim_t += delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity.x = 0.0
	elif windup_t > 0.0:
		windup_t -= delta
		velocity.x = 0.0
		if windup_t <= 0.0:
			lunge_t = 0.45
	elif lunge_t > 0.0:
		lunge_t -= delta
		velocity.x = dir * SPEED * 4.5 * spd()
	else:
		knock = Vector2.ZERO
		lunge_cd -= delta
		var p = main.player
		if elite and lunge_cd <= 0.0 and p and not p.dead and absf(p.global_position.y - global_position.y) < 50.0 and absf(p.global_position.x - global_position.x) < 230.0 * aggro():
			dir = -1 if p.global_position.x < global_position.x else 1
			windup_t = 0.35
			lunge_cd = 2.2 / aggro()
			flash_t = 0.1
		velocity.x = dir * SPEED * spd()
		if is_on_floor():
			var ahead := global_position + Vector2(dir * (size.x / 2.0 + 4.0), size.y / 2.0 + 8.0)
			if not main.is_solid_at(ahead):
				dir = -dir
	move_and_slide()
	if is_on_wall() and knock == Vector2.ZERO:
		dir = -dir
	queue_redraw()

func _draw() -> void:
	var f := float(dir)
	var leg := sin(anim_t * 14.0) * 2.5
	var dark := Color(0.12, 0.1, 0.14)
	for i in 3:
		var lx := -8.0 + i * 8.0
		draw_line(Vector2(lx, 6), Vector2(lx + (leg if i % 2 == 0 else -leg), 11), dark, 2.0)
	# Carapace en dôme
	var shell := DU.ellipse(Vector2(0, 6), Vector2(16, 15), 20, PI, TAU)
	draw_colored_polygon(shell, body_color(Color(0.62, 0.58, 0.7)))
	draw_line(Vector2(-16, 6), Vector2(16, 6), body_color(Color(0.35, 0.32, 0.42)), 2.0)
	for i in 3:
		draw_arc(Vector2(0, 6), 6.0 + i * 4.0, PI + 0.3, TAU - 0.3, 10, body_color(Color(0.45, 0.42, 0.55)), 1.2)
	# Tête et œil
	draw_circle(Vector2(f * 15, 3), 5.0, body_color(dark))
	draw_circle(Vector2(f * 17, 2), 1.8, Color(1.0, 0.55, 0.3) if stun_t <= 0.0 else Color(0.4, 0.4, 0.4))
	if stun_t > 0.0:
		for i in 3:
			var a := Time.get_ticks_msec() / 250.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -16.0 + sin(a) * 3.0), 2.0, Color(1, 1, 0.7))

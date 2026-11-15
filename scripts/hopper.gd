extends "res://scripts/enemy.gd"
# Sauteur : petite sauterelle des profondeurs. Attend, puis bondit vers le joueur.
# Élite : enchaîne deux bonds.

var wait_t := 1.0
var facing := -1.0
var hops_left := 0

func _ready() -> void:
	size = Vector2(26, 22)
	hp = 2
	geo_value = 3
	setup_body()
	wait_t = randf_range(0.5, 1.5)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif is_on_floor():
		knock = Vector2.ZERO
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		if stun_t <= 0.0:
			wait_t -= delta
			var near: bool = p and not p.dead and p.global_position.distance_to(global_position) < 380.0 * aggro()
			if near:
				facing = -1.0 if p.global_position.x < global_position.x else 1.0
			if wait_t <= 0.0 or hops_left > 0:
				var dx: float = clampf((p.global_position.x - global_position.x) if near else facing * 120.0, -260.0, 260.0)
				velocity.y = -560.0 * sqrt(spd())
				velocity.x = dx * 1.1 * spd()
				if hops_left > 0:
					hops_left -= 1
				elif elite:
					hops_left = 1
				wait_t = randf_range(0.9, 1.6) / aggro()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var f := facing
	var air := not is_on_floor()
	var crouch := 0.0 if air else clampf(1.0 - wait_t, 0.0, 0.5) * 6.0
	var body := body_color(Color(0.45, 0.55, 0.32))
	var dark := Color(0.12, 0.14, 0.08)
	# pattes arrière
	var leg := Vector2(-f * 10, 4 + crouch)
	draw_line(Vector2(-f * 4, 2), leg + Vector2(0, -8 if air else 0), dark, 3.0)
	draw_line(leg + Vector2(0, -8 if air else 0), Vector2(-f * 14, 11), dark, 2.5)
	# corps
	draw_colored_polygon(DU.ellipse(Vector2(0, crouch * 0.5), Vector2(13, 8)), body)
	draw_colored_polygon(DU.ellipse(Vector2(f * 9, -3 + crouch * 0.5), Vector2(7, 6)), body)
	draw_circle(Vector2(f * 12, -4 + crouch * 0.5), 2.2, Color(1.0, 0.85, 0.3))
	# antennes
	draw_line(Vector2(f * 12, -8), Vector2(f * 20, -16 - sin(anim_t * 6.0) * 2.0), dark, 1.5)
	if stun_t > 0.0:
		for i in 3:
			var a := anim_t * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -18.0 + sin(a) * 3.0), 2.0, Color(1, 1, 0.7))

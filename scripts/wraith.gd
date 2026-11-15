extends "res://scripts/enemy.gd"
# Spectre : fantôme qui disparaît (intouchable), réapparaît près du joueur en scintillant,
# lance une orbe lente puis reste un moment vulnérable. Élite : deux orbes.

var state := "visible"
var state_t := 2.0
var alpha := 1.0

func _ready() -> void:
	size = Vector2(26, 34)
	hp = 3
	geo_value = 4
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_mask = 0
	state_t = randf_range(1.0, 2.5)

func is_harmful() -> bool:
	return super.is_harmful() and alpha > 0.8

func take_hit(dmg: int, d: Vector2) -> void:
	if alpha < 0.6:
		return    # intouchable quand il est estompé
	super.take_hit(dmg, d)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	var p = main.player
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2(0, sin(anim_t * 2.0) * 20.0), 400.0 * delta)
	if stun_t <= 0.0 and p and not p.dead:
		match state:
			"visible":
				alpha = move_toward(alpha, 1.0, delta * 3.0)
				if state_t <= 0.0:
					state = "fade"
					state_t = 0.5
			"fade":
				alpha = clampf(state_t / 0.5, 0.0, 1.0)
				if state_t <= 0.0:
					if p.global_position.distance_to(global_position) < 520.0 * aggro():
						var a := randf() * TAU
						var target: Vector2 = p.global_position + Vector2(cos(a) * 170.0, -absf(sin(a)) * 110.0 - 40.0)
						if not main.is_solid_at(target):
							global_position = target
					state = "appear"
					state_t = 0.45
			"appear":
				alpha = 0.3 + 0.5 * absf(sin(anim_t * 20.0))
				if state_t <= 0.0:
					alpha = 1.0
					var dirv: Vector2 = (p.global_position - global_position).normalized()
					main.spawn_projectile(global_position, dirv * 170.0 * spd(), {"kind": "ember", "radius": 9.0, "life": 4.0})
					if elite:
						main.spawn_projectile(global_position, dirv.rotated(0.35) * 170.0 * spd(), {"kind": "ember", "radius": 9.0, "life": 4.0})
					state = "visible"
					state_t = randf_range(1.4, 2.2) / aggro()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var c := body_color(Color(0.75, 0.8, 0.95))
	c.a = 0.75 * alpha
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + i * PI / 12.0
		pts.append(Vector2(cos(a) * 13.0, -4 + sin(a) * 14.0))
	for i in 5:
		var x := 13.0 - i * 6.5
		pts.append(Vector2(x, 14 + sin(anim_t * 6.0 + i) * 4.0 + (4.0 if i % 2 == 0 else 0.0)))
	draw_colored_polygon(pts, c)
	var eye := Color(0.3, 0.9, 1.0, alpha)
	draw_circle(Vector2(-4, -6), 2.5, eye)
	draw_circle(Vector2(4, -6), 2.5, eye)
	draw_circle(Vector2.ZERO, 22.0, Color(0.5, 0.7, 1.0, 0.08 * alpha))

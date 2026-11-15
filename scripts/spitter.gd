extends "res://scripts/enemy.gd"
# Cracheur : champignon-bulbe immobile qui gonfle puis crache une spore vers le joueur.
# Astuce : une parade renvoie la spore.

const RANGE := 460.0
const SHOT_SPEED := 270.0
var cooldown := 0.0
var windup := 0.0
var facing := 1.0

func _ready() -> void:
	size = Vector2(30, 28)
	hp = 3
	geo_value = 4
	setup_body()
	cooldown = randf_range(0.8, 2.0)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	velocity.x = knock.x
	knock = knock.move_toward(Vector2.ZERO, 2000.0 * delta)
	var p = main.player
	if p and not p.dead and stun_t <= 0.0:
		var to: Vector2 = p.global_position - global_position
		facing = -1.0 if to.x < 0.0 else 1.0
		if to.length() < RANGE * minf(aggro(), 1.4):
			if windup > 0.0:
				windup -= delta
				if windup <= 0.0:
					_shoot(p.global_position + Vector2(0, -6))
			else:
				cooldown -= delta
				if cooldown <= 0.0:
					windup = 0.45 / sqrt(aggro())
					cooldown = randf_range(1.8, 2.6) / aggro()
	else:
		windup = 0.0
	move_and_slide()
	queue_redraw()

func _shoot(target: Vector2) -> void:
	var from := global_position + Vector2(facing * 10.0, -12.0)
	var dir := (target - from).normalized()
	main.spawn_projectile(from, dir * SHOT_SPEED * spd())
	if elite:   # élite : salve de 3 spores
		main.spawn_projectile(from, dir.rotated(0.28) * SHOT_SPEED * spd())
		main.spawn_projectile(from, dir.rotated(-0.28) * SHOT_SPEED * spd())
	Audio.sfx("spit", 0.1, -4.0)

func _draw() -> void:
	var swell := 1.0 + (0.45 - windup) * 0.5 if windup > 0.0 else 1.0 + sin(anim_t * 3.0) * 0.04
	var base := Color(0.3, 0.42, 0.36)
	if windup > 0.0 and fmod(anim_t, 0.1) < 0.05:
		base = Color(0.75, 0.45, 0.8)
	if stun_t > 0.0:
		base = base.darkened(0.4)
	# pied
	draw_rect(Rect2(-6, 4, 12, 10), body_color(Color(0.2, 0.25, 0.22)))
	# bulbe
	draw_colored_polygon(DU.ellipse(Vector2(0, -2), Vector2(15, 13) * swell), body_color(base))
	for i in 3:
		draw_circle(Vector2(-7 + i * 7, -8 + (i % 2) * 5) * swell, 2.5, body_color(Color(0.7, 0.85, 0.6)))
	# bouche
	draw_colored_polygon(DU.ellipse(Vector2(facing * 9.0, -6.0) * swell, Vector2(4, 4 + (3 if windup > 0.0 else 0))), Color(0.08, 0.03, 0.08))
	if stun_t > 0.0:
		for i in 3:
			var a := anim_t * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -22.0 + sin(a) * 3.0), 2.0, Color(1, 1, 0.7))

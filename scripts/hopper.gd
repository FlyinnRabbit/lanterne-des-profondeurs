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

func telegraph() -> int:
	var p = main.player
	return 1 if is_on_floor() and stun_t <= 0.0 and wait_t < 0.3 and p and p.global_position.distance_to(global_position) < 380.0 * aggro() else 0

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
	var body := body_color(Color(0.45, 0.58, 0.3))
	var dark := body_color(Color(0.14, 0.17, 0.09))
	var cy := crouch * 0.5
	# grande patte arrière repliée (cuisse épaisse puis tibia)
	var hip := Vector2(-f * 5, 0 + cy)
	var knee := Vector2(-f * 3, -9 + cy) if not air else Vector2(-f * 14, -2)
	var foot := Vector2(-f * 15, 11) if not air else Vector2(-f * 20, 8)
	draw_line(hip, knee, body.darkened(0.35), 6.0)
	draw_line(hip + Vector2(0, -1), knee + Vector2(0, -1), body.darkened(0.1), 3.0)
	draw_circle(knee, 2.6, body.darkened(0.3))
	draw_line(knee, foot, dark, 2.2)
	for k in 3:
		draw_line(knee.lerp(foot, 0.3 + k * 0.2), knee.lerp(foot, 0.3 + k * 0.2) + Vector2(-f * 2, -2), dark, 1.0)
	# pattes avant
	leg(Vector2(f * 6, 4 + cy), Vector2(f * 9, 7 + cy), Vector2(f * 8, 11), dark, 1.6)
	leg(Vector2(f * 2, 5 + cy), Vector2(f * 4, 8 + cy), Vector2(f * 2, 11), dark.darkened(0.3), 1.6)
	# abdomen segmenté
	DU.poly(self, DU.ellipse(Vector2(-f * 3, 1 + cy), Vector2(13, 7.5)), body)
	for i in 4:
		var sx := -f * (3 + i * 3.5)
		draw_line(Vector2(sx, -4 + cy), Vector2(sx, 6 + cy), body.darkened(0.35), 1.0)
	# élytre (aile repliée)
	DU.poly(self, PackedVector2Array([Vector2(f * 4, -5 + cy), Vector2(-f * 15, -3 + cy), Vector2(-f * 12, 1 + cy), Vector2(f * 3, -1 + cy)]), body.lerp(Color(0.8, 0.75, 0.4), 0.3))
	# tête et gros œil
	var hd := Vector2(f * 10, -3 + cy)
	DU.poly(self, DU.ellipse(hd, Vector2(7, 6)), body.lightened(0.05))
	draw_circle(hd + Vector2(f * 2, -1), 3.4, Color(0.08, 0.06, 0.03))
	draw_circle(hd + Vector2(f * 2.5, -1.5), 2.2, Color(1.0, 0.85, 0.3))
	draw_circle(hd + Vector2(f * 2, -2.3), 0.8, Color(1, 1, 0.9))
	draw_line(hd + Vector2(f * 5, 3), hd + Vector2(f * 7, 4), dark, 1.2)
	# antennes
	draw_line(hd + Vector2(f * 2, -5), hd + Vector2(f * 12, -15 - sin(anim_t * 6.0) * 2.0), dark, 1.2)
	draw_line(hd + Vector2(0, -5), hd + Vector2(f * 7, -16 + sin(anim_t * 5.0) * 2.0), dark, 1.0)
	draw_stun(-20.0)

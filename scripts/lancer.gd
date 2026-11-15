extends "res://scripts/enemy.gd"
# Lancier : soldat-insecte armé d'une lance. Il s'approche, se met en garde (annonce)
# puis porte un estoc long qui touche loin devant lui. Parer l'estoc l'étourdit.

var dir := -1.0
var state := "walk"
var state_t := 0.0
var cd := 1.0

func _ready() -> void:
	size = Vector2(28, 40)
	hp = 4
	geo_value = 5
	setup_body()
	floor_snap_length = 6.0

# Pendant l'estoc, la lance prolonge la zone dangereuse
func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if state == "thrust":
		r = r.merge(Rect2(global_position + Vector2(dir * 14.0 - (76.0 if dir < 0 else 0.0), -14), Vector2(76, 12)))   # coup haut : on l'esquive accroupi
	return r

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	cd -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
		state = "walk"
	elif stun_t > 0.0:
		velocity.x = 0.0
		state = "walk"
	else:
		match state:
			"walk":
				velocity.x = 0.0
				if p and not p.dead:
					var d: Vector2 = p.global_position - global_position
					if absf(d.x) < 420.0 * aggro() and absf(d.y) < 120.0:
						dir = signf(d.x) if d.x != 0.0 else dir
						if absf(d.x) < 120.0 and cd <= 0.0:
							state = "windup"
							state_t = (0.4 if elite else 0.55) / sqrt(aggro())
						elif absf(d.x) > 70.0:
							velocity.x = dir * 75.0 * spd()
					if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 20.0, size.y / 2.0 + 8.0)):
						velocity.x = 0.0
			"windup":
				velocity.x = -dir * 15.0
				if state_t <= 0.0:
					state = "thrust"
					state_t = 0.25
					Audio.sfx("slash", 0.1, -2.0)
			"thrust":
				velocity.x = dir * 160.0 * spd()
				if state_t <= 0.0:
					state = "walk"
					cd = 1.3 / aggro()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var f := dir
	var tele := state == "windup"
	var shell := Color(0.35, 0.42, 0.38)
	if tele and fmod(anim_t, 0.12) < 0.06:
		shell = Color(1.0, 0.75, 0.5)
	var dark := Color(0.12, 0.14, 0.12)
	var step := sin(anim_t * 10.0) * 3.0 if absf(velocity.x) > 5.0 else 0.0
	draw_line(Vector2(-5, 10), Vector2(-5 + step, 20), dark, 3.0)
	draw_line(Vector2(5, 10), Vector2(5 - step, 20), dark, 3.0)
	draw_colored_polygon(DU.ellipse(Vector2(0, 0), Vector2(12, 14)), body_color(shell))
	draw_arc(Vector2(0, 0), 8.0, PI + 0.4, TAU - 0.4, 10, body_color(shell.lightened(0.2)), 2.0)
	var hd := Vector2(f * 3, -17)
	draw_colored_polygon(DU.ellipse(hd, Vector2(8, 7)), body_color(shell.darkened(0.2)))
	draw_line(hd + Vector2(f * 2, -3), hd + Vector2(f * 9, -3), Color(1.0, 0.6, 0.3) if not tele else Color(1, 1, 0.7), 2.0)
	# lance : en arrière pendant l'annonce, tendue pendant l'estoc
	var hand := Vector2(f * 10, -8)
	var back := -16.0 if tele else 0.0
	var reach := 76.0 if state == "thrust" else 34.0
	var a := hand + Vector2(f * back, 0)
	var b := a + Vector2(f * reach, 0)
	draw_line(a - Vector2(f * 16, 0), b, Color(0.55, 0.42, 0.3), 3.0)
	draw_colored_polygon(PackedVector2Array([b, b + Vector2(-f * 8, -5), b + Vector2(f * 8, 0), b + Vector2(-f * 8, 5)]), Color(0.85, 0.87, 0.92))
	if state == "thrust":
		draw_line(b, b - Vector2(f * 40, 0), Color(1, 1, 1, 0.5), 6.0)
	if stun_t > 0.0:
		for i in 3:
			var aa := anim_t * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(aa) * 12.0, -32.0 + sin(aa) * 3.0), 2.0, Color(1, 1, 0.7))

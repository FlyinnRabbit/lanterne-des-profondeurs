extends "res://scripts/enemy.gd"
# Slime : boule de gelée qui avance par bonds écrasés. Quand on le tue, il se divise en deux
# petits slimes plus rapides (qui, eux, ne se divisent plus). Rebondir dessus (coup vers le bas)
# l'écrase net.
# Élite : laisse une flaque collante en atterrissant.

var dir := -1.0
var hop_cd := 0.8
var small := false      # petit slime issu d'une division
var squish := 0.0       # écrasement à l'atterrissage (dessin)
var was_air := false
var tint := Color(0.45, 0.85, 0.4)

func _ready() -> void:
	size = Vector2(18, 14) if small else Vector2(30, 22)
	hp = 1 if small else 4
	geo_value = 1 if small else 4
	setup_body()
	floor_snap_length = 6.0
	anim_t = randf() * 3.0
	hop_cd = randf_range(0.3, 1.0)
	if not display:
		var bid := String(main.pal.get("id", ""))
		tint = {"desert": Color(0.95, 0.7, 0.3), "antique": Color(0.55, 0.75, 0.95), "forge": Color(1.0, 0.5, 0.3),
			"glace": Color(0.6, 0.85, 1.0), "ossuaire": Color(0.8, 0.85, 0.7)}.get(bid, Color(0.45, 0.85, 0.4))

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	hop_cd -= delta
	squish = maxf(squish - delta * 3.0, 0.0)
	velocity.y = minf(velocity.y + 1700.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1600.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity.x = 0.0
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		if hop_cd <= 0.0:
			if p and not p.dead and absf(p.global_position.x - global_position.x) < 380.0 * aggro() and absf(p.global_position.y - global_position.y) < 160.0:
				dir = signf(p.global_position.x - global_position.x) if p.global_position.x != global_position.x else dir
			elif not main.is_solid_at(global_position + Vector2(dir * 20.0, size.y / 2.0 + 8.0)) or is_on_wall():
				dir = -dir
			var sp := (190.0 if small else 150.0) * spd()
			velocity = Vector2(dir * sp, -(330.0 if small else 420.0))
			hop_cd = randf_range(0.6, 1.0) / aggro() * (0.7 if small else 1.0)
	move_and_slide()
	if is_on_floor() and was_air:
		squish = 1.0
		if elite and not small:
			main.spawn_projectile(Vector2(global_position.x, global_position.y + size.y / 2.0), Vector2.ZERO, {"kind": "webpatch", "life": 2.5, "radius": 18.0})
	was_air = not is_on_floor()
	queue_redraw()

func die() -> void:
	if not small and not display:
		# division en deux petits slimes
		for s in [-1.0, 1.0]:
			var e := CharacterBody2D.new()
			e.set_script(get_script())
			e.main = main
			e.small = true
			e.elite = false
			e.position = global_position + Vector2(s * 8.0, -4.0)
			main.add_child.call_deferred(e)
			e.set_deferred("velocity", Vector2(s * 160.0, -300.0))
			e.set_deferred("dir", s)
	super.die()

func fx_color() -> Color:
	return tint

func _draw() -> void:
	var r := size.x * 0.5
	var air := not is_on_floor() if not display else false
	var sx := 1.0 + 0.35 * squish - (0.12 if air else 0.0) + sin(anim_t * 4.0) * 0.04
	var sy := 1.0 - 0.3 * squish + (0.15 if air else 0.0) - sin(anim_t * 4.0) * 0.04
	var c := body_color(tint)
	var gy := size.y * 0.5
	# corps en goutte : base plate, dôme
	var pts := PackedVector2Array()
	for i in 18:
		var a := PI + i * PI / 17.0
		pts.append(Vector2(cos(a) * r * sx, gy + sin(a) * size.y * 1.05 * sy))
	pts.append(Vector2(r * sx, gy))
	pts.append(Vector2(-r * sx, gy))
	DU.flat(self, pts, Color(c, 0.85))
	DU.glow(self, Vector2(0, gy - size.y * 0.5 * sy), r * 1.4, c, 0.18)
	# noyau et bulles à l'intérieur
	draw_circle(Vector2(sin(anim_t) * 2.0, gy - size.y * 0.4 * sy), r * 0.28, Color(c.darkened(0.35), 0.6))
	for i in 3:
		var u := fposmod(anim_t * 0.4 + i * 0.33, 1.0)
		draw_circle(Vector2((i - 1) * r * 0.35, gy - u * size.y * 0.8 * sy), 1.4, Color(1, 1, 1, 0.35 * (1.0 - u)))
	# reflet
	draw_circle(Vector2(-r * 0.4 * sx, gy - size.y * 0.75 * sy), r * 0.18, Color(1, 1, 1, 0.7))
	# yeux
	var ey := gy - size.y * 0.55 * sy
	for s in [-1.0, 1.0]:
		var ep := Vector2(dir * r * 0.15 + s * r * 0.28, ey)
		draw_circle(ep, r * 0.16, Color(1, 1, 1))
		draw_circle(ep + Vector2(dir * 1.0, 0.5), r * 0.08 + 0.4, Color(0.05, 0.08, 0.05))
	draw_stun(gy - size.y * 1.2)

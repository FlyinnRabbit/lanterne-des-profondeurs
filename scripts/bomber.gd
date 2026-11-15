extends "res://scripts/enemy.gd"
# Bulbe explosif : roule vers le joueur, s'allume puis explose (dégâts autour, ennemis compris).
# Tué avant d'exploser, il éclate sans danger. Élite : mèche plus courte, explosion plus large.

const SPEED := 85.0
var fuse := -1.0
var dir := -1.0

func _ready() -> void:
	size = Vector2(26, 24)
	hp = 2
	geo_value = 3
	setup_body()
	floor_snap_length = 6.0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif fuse >= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		fuse -= delta
		if fuse <= 0.0:
			_explode()
			return
	elif stun_t <= 0.0 and p and not p.dead:
		var d: Vector2 = p.global_position - global_position
		if d.length() < 380.0 * aggro():
			dir = signf(d.x) if d.x != 0.0 else dir
			velocity.x = dir * SPEED * spd()
			if d.length() < 64.0:
				fuse = 0.6 if elite else 0.85
		else:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()
	queue_redraw()

func is_harmful() -> bool:
	return false   # c'est l'explosion qui fait mal, pas le contact

func _explode() -> void:
	var radius := 105.0 if elite else 85.0
	main.spawn_burst(global_position, Color(1.0, 0.55, 0.2), 36, 360.0, 0.0)
	main.shake(10)
	Audio.sfx("kill", 0.0, 3.0)
	var p = main.player
	if not p.dead and p.global_position.distance_to(global_position) < radius:
		p.receive_hit(global_position, self)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and is_instance_valid(e) and e.global_position.distance_to(global_position) < radius:
			e.take_hit(3, (e.global_position - global_position).normalized())
	dead = true
	remove_from_group("enemies")
	queue_free()

func _draw() -> void:
	var lit := fuse >= 0.0 and fmod(anim_t, 0.16 if fuse > 0.35 else 0.08) < 0.05
	var base := Color(0.75, 0.3, 0.25) if not lit else Color(1.0, 0.85, 0.5)
	var roll := anim_t * velocity.x * 0.05
	draw_colored_polygon(DU.ellipse(Vector2(0, 2), Vector2(13, 11)), body_color(base))
	for i in 3:
		var a := roll + i * TAU / 3.0
		draw_line(Vector2(cos(a), sin(a)) * 4.0 + Vector2(0, 2), Vector2(cos(a), sin(a)) * 12.0 + Vector2(0, 2), body_color(base.darkened(0.35)), 2.0)
	draw_line(Vector2(2, -8), Vector2(6, -16), Color(0.3, 0.25, 0.2), 2.0)
	draw_circle(Vector2(6, -17), 2.5 + (2.0 if fuse >= 0.0 else 0.0) * absf(sin(anim_t * 25.0)), Color(1.0, 0.8, 0.3))
	if fuse >= 0.0:
		draw_arc(Vector2.ZERO, 85.0, 0.0, TAU, 40, Color(1.0, 0.4, 0.2, 0.25), 2.0)

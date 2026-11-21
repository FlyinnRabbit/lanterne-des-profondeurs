extends "res://scripts/enemy.gd"
# Vesse-de-loup (Jardins Fongiques) : champignon boursouflé qui se dandine vers le héros. Tout
# près, il gonfle puis éclate en nuage de spores (il meurt dans l'explosion). Le tuer avant
# qu'il n'éclate évite le nuage. Élite : nuage plus large.

var dir := -1.0
var swell := 0.0       # 0..1 : gonfle avant d'éclater
var cloud_t := 0.0

func _ready() -> void:
	size = Vector2(26, 24)
	hp = 2
	geo_value = 3
	setup_body()

func telegraph() -> int:
	return 1 if swell > 0.0 and stun_t <= 0.0 else 0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		velocity.x = 0.0
		swell = maxf(swell - delta, 0.0)
	elif swell > 0.0:
		swell += delta / 0.8
		velocity.x = 0.0
		if swell >= 1.0:
			_burst()
			return
	else:
		knock = Vector2.ZERO
		var near: bool = p and not p.dead and absf(p.global_position.y - global_position.y) < 60.0 * reach and absf(p.global_position.x - global_position.x) < 260.0 * aggro()
		if near:
			dir = -1.0 if p.global_position.x < global_position.x else 1.0
			if absf(p.global_position.x - global_position.x) < 54.0 * reach:
				swell = 0.01
		velocity.x = dir * 45.0 * spd() * (1.4 if near else 0.6)
		if is_on_floor() and not main.is_solid_at(global_position + Vector2(dir * 16.0, size.y / 2.0 + 8.0)):
			dir = -dir
	move_and_slide()
	if is_on_wall():
		dir = -dir
	queue_redraw()

func _burst() -> void:
	var r := (70.0 if elite else 54.0) * reach
	var p = main.player
	if p and not p.dead and p.global_position.distance_to(global_position) < r:
		p.receive_hit(global_position, self)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and is_instance_valid(e) and not e.dead and not e.is_boss and e.global_position.distance_to(global_position) < r:
			e.hurt_by_trap(1, (e.global_position - global_position).normalized())
	main.spawn_burst(global_position + Vector2(0, -8), Color(0.65, 0.9, 0.45), 30, r * 3.0, -40.0)
	Audio.sfx("spit", 0.1, -2.0)
	main.shake(5)
	if champion != "":
		# la Vesse-Mère ne meurt pas en éclatant : elle se dégonfle, souffle, et recommence
		swell = 0.0
		stun_t = 1.6
		return
	geo_value = 0
	die()

func fx_color() -> Color:
	return Color(0.7, 0.85, 0.5)

func _draw() -> void:
	var s := 1.0 + swell * 0.55 + sin(anim_t * (40.0 if swell > 0.0 else 4.0)) * (0.06 if swell > 0.0 else 0.02)
	var cap := body_color(Color(0.78, 0.72, 0.52) if not elite else Color(0.7, 0.55, 0.6))
	if swell > 0.0:
		DU.glow(self, Vector2(0, -2), 26.0 * s, Color(0.7, 1.0, 0.45), 0.3 * swell)
	DU.flat(self, DU.ellipse(Vector2(0, 2 - 3 * swell), Vector2(13, 11) * s), cap)
	# verrues et pores
	for i in 5:
		var a := i * 1.3 + 0.4
		draw_circle(Vector2(cos(a) * 7 * s, -1 + sin(a) * 5 * s), 1.6, cap.darkened(0.3))
	# petite bouche/fente et yeux plissés
	draw_arc(Vector2(dir * 3, 3), 3.0, 0.2, PI - 0.2, 6, cap.darkened(0.55), 1.2)
	draw_line(Vector2(dir * 1 - 2, -2), Vector2(dir * 1, -1), cap.darkened(0.6), 1.4)
	draw_line(Vector2(dir * 5, -1), Vector2(dir * 5 + 2, -2), cap.darkened(0.6), 1.4)
	# pied
	draw_rect(Rect2(Vector2(-5, 9), Vector2(10, 3)), cap.darkened(0.2))
	draw_stun(-18.0)

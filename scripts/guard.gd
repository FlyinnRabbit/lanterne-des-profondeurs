extends "res://scripts/enemy.gd"
# Garde à bouclier : insecte cuirassé qui avance vers le joueur, bouclier levé.
# Les coups de face sont bloqués : frappe-le par-dessus (coup vers le bas), dans le dos,
# ou utilise l'ultime. Élite : charge au bouclier.

const SPEED := 60.0
var facing := -1.0
var block_flash := 0.0
var bash_t := 0.0
var bash_cd := 2.0

func _ready() -> void:
	size = Vector2(32, 30)
	hp = 4
	geo_value = 5
	setup_body()
	floor_snap_length = 6.0

func take_hit(dmg: int, dir: Vector2) -> void:
	# bloque les coups horizontaux qui arrivent face au bouclier (sauf l'ultime)
	if dmg < 5 and absf(dir.y) < 0.5 and signf(dir.x) == -facing and stun_t <= 0.0:
		block_flash = 0.15
		main.spawn_burst(global_position + Vector2(facing * 18, -4), Color(1.0, 0.95, 0.6), 8, 200.0, 0.0)
		Audio.sfx("parry", 0.1, -6.0)
		return
	super.take_hit(dmg, dir)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	block_flash -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity.x = 0.0
	else:
		knock = Vector2.ZERO
		var near: bool = p and not p.dead and p.global_position.distance_to(global_position) < 320.0 * aggro()
		if near and bash_t <= 0.0:
			facing = -1.0 if p.global_position.x < global_position.x else 1.0
		var sp := SPEED * spd() * (1.4 if near else 0.7)
		if elite:
			bash_cd -= delta
			if near and bash_cd <= 0.0:
				bash_t = 0.4
				bash_cd = 2.5 / aggro()
		if bash_t > 0.0:
			bash_t -= delta
			sp = SPEED * 5.0 * spd()
		velocity.x = facing * sp
		if is_on_floor():
			var ahead := global_position + Vector2(facing * (size.x / 2.0 + 4.0), size.y / 2.0 + 8.0)
			if not main.is_solid_at(ahead):
				velocity.x = 0.0
				if not near:
					facing = -facing
	move_and_slide()
	if is_on_wall() and knock == Vector2.ZERO and bash_t <= 0.0:
		facing = -facing
	queue_redraw()

func _draw() -> void:
	var f := facing
	var dark := Color(0.1, 0.1, 0.13)
	var step := sin(anim_t * 10.0) * 3.0 if absf(velocity.x) > 5.0 else 0.0
	for i in 3:
		var lx := -10.0 + i * 9.0
		draw_line(Vector2(lx, 8), Vector2(lx + (step if i % 2 == 0 else -step), 15), dark, 3.0)
	# carapace
	draw_colored_polygon(DU.ellipse(Vector2(-f * 2, 2), Vector2(15, 13)), body_color(Color(0.4, 0.38, 0.32)))
	draw_arc(Vector2(-f * 2, 2), 9.0, PI + 0.3, TAU - 0.3, 10, body_color(Color(0.55, 0.52, 0.44)), 2.0)
	draw_circle(Vector2(f * 8, -6), 3.0, Color(1.0, 0.5, 0.3) if stun_t <= 0.0 else Color(0.4, 0.4, 0.4))
	# bouclier
	var sh := Color(0.75, 0.72, 0.6) if block_flash <= 0.0 else Color(1, 1, 0.85)
	var sx := f * 17.0
	draw_colored_polygon(PackedVector2Array([Vector2(sx, -15), Vector2(sx + f * 5, -8), Vector2(sx + f * 5, 8), Vector2(sx, 15), Vector2(sx - f * 3, 0)]), body_color(sh))
	draw_line(Vector2(sx + f * 2, -10), Vector2(sx + f * 2, 10), Color(0.45, 0.42, 0.35), 2.0)
	if stun_t > 0.0:
		for i in 3:
			var a := anim_t * 4.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -24.0 + sin(a) * 3.0), 2.0, Color(1, 1, 0.7))

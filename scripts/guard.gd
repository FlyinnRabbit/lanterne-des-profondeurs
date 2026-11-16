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
	var dark := body_color(Color(0.1, 0.1, 0.13))
	var step := sin(anim_t * 10.0) * 3.0 if absf(velocity.x) > 5.0 else 0.0
	for i in 3:
		var lx := -10.0 + i * 9.0
		var sw := step if i % 2 == 0 else -step
		leg(Vector2(lx, 7), Vector2(lx - f * 2 + sw * 0.4, 11), Vector2(lx + sw, 15), dark, 2.6)
	# carapace en bandes d'armure
	var arm := body_color(Color(0.42, 0.4, 0.34))
	DU.poly(self, DU.ellipse(Vector2(-f * 2, 2), Vector2(15, 13), 24), arm)
	for i in 3:
		var bx := -f * (8 - i * 5)
		draw_arc(Vector2(bx, 3), 11.0 - i, PI + 0.5, TAU - 0.5, 10, arm.darkened(0.45), 1.4)
	for i in 4:
		draw_circle(Vector2(-f * (11 - i * 5), -7 + absf(i - 1.5) * 2.0), 1.1, arm.lightened(0.4))
	# casque et visière
	var hd := Vector2(f * 7, -6)
	DU.poly(self, PackedVector2Array([hd + Vector2(-f * 6, 4), hd + Vector2(-f * 6, -4), hd + Vector2(-f * 2, -8), hd + Vector2(f * 5, -6), hd + Vector2(f * 6, 3)]), body_color(Color(0.55, 0.52, 0.44)))
	draw_line(hd + Vector2(-f * 3, -9), hd + Vector2(-f * 10, -14), Color(0.7, 0.2, 0.18), 2.0)
	draw_line(hd + Vector2(-f * 1, -1), hd + Vector2(f * 5, -1), Color(0.05, 0.04, 0.05), 2.4)
	var eye := Color(1.0, 0.5, 0.3) if stun_t <= 0.0 else Color(0.4, 0.4, 0.4)
	draw_circle(hd + Vector2(f * 3, -1), 1.4, eye)
	DU.glow(self, hd + Vector2(f * 3, -1), 6.0, eye, 0.4)
	# bouclier : bord, umbo, rivets
	var sh := Color(0.75, 0.7, 0.55) if block_flash <= 0.0 else Color(1, 1, 0.85)
	var sx := f * 17.0
	var shield := PackedVector2Array([Vector2(sx, -15), Vector2(sx + f * 5, -8), Vector2(sx + f * 5, 8), Vector2(sx, 15), Vector2(sx - f * 3, 0)])
	DU.poly(self, shield, body_color(sh.darkened(0.25)))
	var inner := PackedVector2Array([Vector2(sx + f * 0.5, -11), Vector2(sx + f * 3.5, -6), Vector2(sx + f * 3.5, 6), Vector2(sx + f * 0.5, 11), Vector2(sx - f * 1.5, 0)])
	DU.poly(self, inner, body_color(sh), false)
	draw_circle(Vector2(sx + f * 1.5, 0), 2.6, body_color(sh.darkened(0.4)))
	draw_circle(Vector2(sx + f * 1.0, -0.8), 1.0, Color(1, 1, 0.9, 0.8))
	for yy in [-9.0, 9.0]:
		draw_circle(Vector2(sx + f * 1.5, yy), 0.9, sh.darkened(0.5))
	if block_flash > 0.0:
		DU.glow(self, Vector2(sx, 0), 22.0, Color(1, 1, 0.8), 0.6)
	draw_stun(-26.0)

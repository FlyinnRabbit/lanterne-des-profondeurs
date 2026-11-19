extends "res://scripts/enemy.gd"
# Volant : moucheron épineux qui flotte et fonce sur le joueur quand il le repère.

const ACCEL := 520.0
const CHASE_SPEED := 175.0
var home := Vector2.ZERO
var bee := false        # ouvrière de la Reine Essaim (même comportement, dessinée en abeille)
var dive_cd := 2.0     # élite : piqué sur le joueur
var dive_t := 0.0
var dive_windup := 0.0
var dive_dir := Vector2.ZERO
var path_t := 0.0        # recalcul du chemin quand un mur le sépare du joueur
var waypoint := Vector2.INF

func _ready() -> void:
	size = Vector2(26, 24)
	hp = 2
	geo_value = 2
	setup_body()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	home = global_position
	anim_t = randf() * 10.0

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	var p = main.player
	if stun_t > 0.0:
		dive_windup = 0.0     # étourdi : le piqué est annulé
		dive_t = 0.0
	var target := home + Vector2(sin(anim_t * 0.8) * 40.0, sin(anim_t * 1.7) * 16.0)
	var speed := 60.0
	if p and not p.dead and p.global_position.distance_to(global_position) < 330.0 * aggro():
		target = p.global_position + Vector2(0, -6)
		speed = CHASE_SPEED * spd()
		# un mur entre lui et le héros : il fait le tour au lieu de foncer dans la roche
		var blocked: bool = main.wall_between_wide(global_position, target, 10.0)
		if blocked:
			path_t -= delta
			if path_t <= 0.0 or waypoint == Vector2.INF or global_position.distance_to(waypoint) < 12.0:
				path_t = 0.3
				waypoint = main.fly_waypoint(global_position, target)
			if waypoint != Vector2.INF:
				target = waypoint
			else:
				target = home + Vector2(sin(anim_t * 0.8) * 40.0, sin(anim_t * 1.7) * 16.0)
				speed = 60.0
		else:
			waypoint = Vector2.INF
		if elite and not blocked:
			dive_cd -= delta
			if dive_cd <= 0.0 and dive_windup <= 0.0 and dive_t <= 0.0:
				dive_windup = 0.4
				dive_cd = 2.5 / aggro()
	if dive_windup > 0.0:
		dive_windup -= delta
		velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		flash_t = 0.05 if fmod(anim_t, 0.1) < 0.05 else 0.0
		if dive_windup <= 0.0 and p:
			dive_dir = (p.global_position - global_position).normalized()
			dive_t = 0.35
		move_and_slide()
		queue_redraw()
		return
	if dive_t > 0.0:
		dive_t -= delta
		velocity = dive_dir * 480.0 * spd()
		move_and_slide()
		queue_redraw()
		return
	if knock.length() > 10.0:
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 1400.0 * delta)
	elif stun_t > 0.0:
		knock = Vector2.ZERO
		velocity = velocity.move_toward(Vector2(0, 40), ACCEL * delta)
	else:
		knock = Vector2.ZERO
		velocity = velocity.move_toward((target - global_position).normalized() * speed, ACCEL * spd() * delta)
	move_and_slide()
	queue_redraw()

func fx_color() -> Color:
	return Color(1.0, 0.8, 0.25) if bee else super.fx_color()

func _draw() -> void:
	if bee:
		_draw_bee()
		return
	var f := -1.0 if velocity.x < 0.0 else 1.0
	var flap := sin(anim_t * 32.0)
	var metal := body_color(Color(0.16, 0.32, 0.3))
	var dark := body_color(Color(0.06, 0.08, 0.09))
	DU.glow(self, Vector2(0, -2), 22.0, Color(0.4, 0.9, 0.7), 0.15)
	# aile du fond (floue, battement)
	_wing(Vector2(-f * 2, -8), f, -0.9 + flap * 0.7, 0.18)
	# pattes velues pendantes
	for i in 3:
		var lx := f * (2.0 - i * 4.0)
		var sw := sin(anim_t * 7.0 + i) * 1.5
		leg(Vector2(lx, 6), Vector2(lx + f * 2 + sw * 0.3, 11), Vector2(lx - f * 1 + sw, 16), dark, 1.4)
	# abdomen métallique segmenté, reflet
	var ab := Vector2(-f * 8, 3)
	DU.poly(self, DU.ellipse(ab, Vector2(9, 7), 20), metal)
	for i in 3:
		var sx := ab.x + f * (3.0 - i * 3.5)
		draw_line(Vector2(sx, ab.y - 6), Vector2(sx - f * 1.5, ab.y + 6), metal.darkened(0.5), 1.2)
	draw_arc(ab + Vector2(0, -1), 6.0, PI * 1.15, PI * 1.6, 8, Color(0.7, 1.0, 0.9, 0.55), 1.6)
	# dard
	DU.poly(self, PackedVector2Array([ab + Vector2(-f * 8, -1), ab + Vector2(-f * 16, 2), ab + Vector2(-f * 8, 3)]), body_color(Color(0.8, 0.75, 0.6)))
	# thorax poilu
	var th := Vector2(f * 2, -1)
	DU.poly(self, DU.ellipse(th, Vector2(8, 7.5), 20), body_color(Color(0.12, 0.2, 0.2)))
	for i in 7:
		var a := -PI * 0.95 + i * 0.3
		var bp := th + Vector2(cos(a) * 7.5, sin(a) * 7.0)
		draw_line(bp, bp + Vector2(cos(a), sin(a)) * 2.5, dark, 1.0)
	# tête : deux gros yeux composés rouges, trompe
	var hd := th + Vector2(f * 8, 1)
	DU.ball(self, hd, 4.5, dark.lightened(0.05))
	for k in [0, 1]:
		var ec := hd + Vector2(f * (1.5 - k * 1.0), -2.5 + k * 3.5)
		DU.ball(self, ec, 3.6 - k * 0.6, body_color(Color(0.75, 0.12, 0.1)))
		for j in 3:
			draw_circle(ec + Vector2(-0.8 + j * 0.9, -0.6 + (j % 2) * 1.0), 0.45, Color(1, 0.6, 0.5, 0.8))
	draw_line(hd + Vector2(f * 3, 3), hd + Vector2(f * 6, 7 + sin(anim_t * 5.0)), dark, 1.3)
	# aile de devant
	_wing(Vector2(f * 1, -9), f, -1.2 - flap * 0.7, 0.32)

# Ouvrière de la Reine Essaim : abdomen rayé jaune et noir, thorax duveteux, dard, ailes vibrantes
func _draw_bee() -> void:
	var f := -1.0 if velocity.x < 0.0 else 1.0
	var flap := sin(anim_t * 46.0)
	var yel := body_color(Color(1.0, 0.76, 0.16))
	var blk := body_color(Color(0.1, 0.07, 0.05))
	var fur := body_color(Color(0.86, 0.6, 0.22))
	DU.glow(self, Vector2(0, -2), 20.0, Color(1.0, 0.8, 0.3), 0.12)
	# aile du fond
	_wing(Vector2(-f * 1, -8), f, -0.9 + flap * 0.8, 0.2)
	# pattes repliées
	for i in 3:
		var lx := f * (3.0 - i * 3.5)
		leg(Vector2(lx, 5), Vector2(lx + f * 1.5, 9), Vector2(lx - f * 1.0, 12 + sin(anim_t * 8.0 + i)), blk, 1.3)
	# abdomen rayé (légèrement recourbé vers le bas), reflet
	var ab := Vector2(-f * 8, 3)
	DU.poly(self, DU.ellipse(ab, Vector2(10, 7.5), 22), yel)
	for i in 3:
		var sx := ab.x + f * (4.0 - i * 4.0)
		DU.poly(self, PackedVector2Array([Vector2(sx - 1.4, ab.y - 7.0 + absf(i - 1.0)), Vector2(sx + 1.4, ab.y - 7.2 + absf(i - 1.0)),
			Vector2(sx + 1.0 - f * 0.8, ab.y + 7.0 - absf(i - 1.0)), Vector2(sx - 1.8 - f * 0.8, ab.y + 6.8 - absf(i - 1.0))]), blk)
	draw_arc(ab + Vector2(0, -1.5), 6.5, PI * 1.15, PI * 1.6, 8, Color(1, 1, 0.85, 0.55), 1.5)
	# dard
	DU.poly(self, PackedVector2Array([ab + Vector2(-f * 9, -1), ab + Vector2(-f * 16, 3), ab + Vector2(-f * 9, 3)]), blk)
	# thorax duveteux
	var th := Vector2(f * 3, -1)
	DU.poly(self, DU.ellipse(th, Vector2(7, 6.5), 18), fur)
	for i in 8:
		var a := -PI + i * 0.42
		var bp := th + Vector2(cos(a) * 6.5, sin(a) * 6.0)
		draw_line(bp, bp + Vector2(cos(a), sin(a)) * 2.0, fur.lightened(0.25), 1.0)
	# tête noire, gros yeux, antennes coudées
	var hd := th + Vector2(f * 7.5, 1)
	DU.ball(self, hd, 4.4, blk)
	DU.ball(self, hd + Vector2(f * 1.2, -1.2), 2.4, body_color(Color(0.22, 0.16, 0.12)))
	draw_circle(hd + Vector2(f * 1.8, -2.0), 0.7, Color(1, 1, 1, 0.7))
	for k in [0, 1]:
		var base := hd + Vector2(f * (1.0 + k * 1.5), -3.5)
		var knee := base + Vector2(f * 2.0, -4.0 - k)
		draw_line(base, knee, blk, 1.0)
		draw_line(knee, knee + Vector2(f * 3.0, -1.0 + sin(anim_t * 6.0 + k) * 0.8), blk, 1.0)
	# aile de devant
	_wing(Vector2(f * 2, -9), f, -1.25 - flap * 0.8, 0.34)

func _wing(root: Vector2, f: float, ang: float, a: float) -> void:
	var dir := Vector2.from_angle(ang if f > 0 else PI - ang)
	var side := dir.orthogonal() * 4.0
	var pts := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		pts.append(root + dir * 15.0 * t + side * sin(t * PI) * (1.0 + 0.4 * t))
	pts.append(root)
	DU.flat(self, pts, Color(0.75, 0.92, 1.0, a))
	draw_polyline(pts, Color(0.85, 0.95, 1.0, a + 0.25), 0.9)
	draw_line(root, root + dir * 13.0 + side * 0.6, Color(0.2, 0.3, 0.35, a + 0.3), 0.8)
	draw_line(root + dir * 4.0, root + dir * 9.0 + side * 1.4, Color(0.2, 0.3, 0.35, a + 0.2), 0.7)

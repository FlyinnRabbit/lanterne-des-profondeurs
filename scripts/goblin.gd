extends "res://scripts/enemy.gd"
# Gobelin pillard : petit, vif et rusé. De loin, il lance des dagues (une parade les renvoie) ;
# de près, il frappe en deux coups rapides avec son coutelas puis fait un bond en arrière.
# Quand il est presque à bout, il prend la fuite en te jetant une petite bombe.
# Élite : lance deux dagues à la suite.

var dir := -1.0
var state := "walk"      # walk / windup_throw / windup_slash / slash / hop_back / flee
var state_t := 0.0
var cd := 1.0
var slashes := 0
var fled := false

func _ready() -> void:
	size = Vector2(22, 30)
	hp = 4
	geo_value = 6
	setup_body()
	floor_snap_length = 6.0
	anim_t = randf() * 3.0

func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if state == "slash":
		r = r.merge(Rect2(global_position + Vector2(dir * 8.0 - (30.0 if dir < 0 else 0.0), -14), Vector2(30, 22)))
	return r

func _go(s: String, t: float) -> void:
	state = s
	state_t = t

func take_hit(dmg: int, d: Vector2) -> void:
	super.take_hit(dmg, d)
	if not dead and not fled and hp <= maxi(1, hp_max / 3):
		fled = true
		_go("flee", 2.2)
		# bombe lâchée en fuyant
		main.spawn_projectile(global_position + Vector2(0, -10), Vector2(-dir * 60.0, -260.0), {"kind": "rock", "radius": 7.0, "gravity": 900.0, "life": 2.0})

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	state_t -= delta
	cd -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	var p = main.player
	var alive_p: bool = p != null and not p.dead
	if absf(knock.x) > 10.0:
		velocity.x = knock.x
		knock = knock.move_toward(Vector2.ZERO, 1800.0 * delta)
		if state != "flee":
			_go("walk", 0.0)
	elif stun_t > 0.0:
		velocity.x = 0.0
		if state != "flee":
			_go("walk", 0.0)
	else:
		match state:
			"walk":
				velocity.x = 0.0
				if alive_p:
					var d: Vector2 = p.global_position - global_position
					if absf(d.x) < 460.0 * aggro() and absf(d.y) < 140.0:
						dir = signf(d.x) if d.x != 0.0 else dir
						if absf(d.x) < 50.0 and cd <= 0.0:
							slashes = 2
							_go("windup_slash", (0.35 if not elite else 0.28) / sqrt(aggro()))
						elif absf(d.x) > 170.0 and cd <= 0.0 and not main.wall_between(global_position + Vector2(0, -8), p.global_position):
							_go("windup_throw", 0.45)
						elif is_on_floor() and main.is_solid_at(global_position + Vector2(dir * 16.0, size.y / 2.0 + 8.0)):
							velocity.x = dir * 135.0 * spd()
							if is_on_wall():
								velocity.y = -460.0
			"windup_throw":
				velocity.x = 0.0
				if state_t <= 0.0 and alive_p:
					_throw(p)
					cd = 2.2 / aggro()
					_go("walk", 0.0)
					if elite:
						_second_throw(p)
			"windup_slash":
				velocity.x = 0.0
				if state_t <= 0.0:
					_go("slash", 0.16)
					Audio.sfx("slash", 0.15, -4.0)
			"slash":
				velocity.x = dir * 120.0
				if alive_p and p.dash_t <= 0.0 and get_rect().intersects(p.get_rect()):
					p.receive_hit(global_position, self)
				if state_t <= 0.0:
					slashes -= 1
					if slashes > 0:
						_go("windup_slash", 0.14)
					else:
						velocity = Vector2(-dir * 260.0, -360.0)
						_go("hop_back", 0.5)
			"hop_back":
				if state_t <= 0.0 and is_on_floor():
					cd = 1.1 / aggro()
					_go("walk", 0.0)
			"flee":
				if alive_p:
					dir = signf(global_position.x - p.global_position.x) if global_position.x != p.global_position.x else dir
				if is_on_floor():
					velocity.x = dir * 200.0 * spd()
					if is_on_wall() or not main.is_solid_at(global_position + Vector2(dir * 16.0, size.y / 2.0 + 8.0)):
						velocity = Vector2(-dir * 120.0, -420.0)
						dir = -dir
				if state_t <= 0.0:
					_go("walk", 0.0)
					cd = 0.5
	move_and_slide()
	queue_redraw()

func _second_throw(p) -> void:
	await get_tree().create_timer(0.25, false).timeout
	if is_instance_valid(self) and not dead and is_instance_valid(p) and not p.dead:
		_throw(p)

func _throw(p) -> void:
	var from := global_position + Vector2(dir * 10.0, -12.0)
	var d: Vector2 = (p.global_position + Vector2(0, -8) - from).normalized()
	main.spawn_projectile(from, d * 380.0 * spd(), {"kind": "dart", "radius": 5.0, "life": 2.0})
	Audio.sfx("whip", 0.2, -6.0)

func telegraph() -> int:
	if stun_t > 0.0:
		return 0
	return 1 if state.begins_with("windup") else 0

func fx_color() -> Color:
	return Color(0.45, 0.6, 0.3)

func _draw() -> void:
	var f := dir
	var skin := body_color(Color(0.45, 0.62, 0.3))
	var cloth := body_color(Color(0.42, 0.28, 0.2))
	var run := absf(velocity.x) > 10.0 and (is_on_floor() if not display else true)
	var sw := sin(anim_t * 16.0) * 3.0 if run else 0.0
	var gy := size.y * 0.5
	# jambes maigres
	draw_line(Vector2(-3, 4), Vector2(-4 + sw, gy), skin.darkened(0.25), 2.4)
	draw_line(Vector2(3, 4), Vector2(4 - sw, gy), skin.darkened(0.25), 2.4)
	# sac de butin dans le dos
	DU.ball(self, Vector2(-f * 8.0, -2.0), 6.0, Color(0.6, 0.5, 0.36))
	draw_line(Vector2(-f * 8.0, -8.0), Vector2(f * 2.0, -6.0), Color(0.35, 0.25, 0.18), 1.2)
	# corps : tunique en haillons
	DU.poly(self, PackedVector2Array([Vector2(-6, -6), Vector2(6, -6), Vector2(8, 6), Vector2(3, 5), Vector2(0, 7), Vector2(-4, 5), Vector2(-8, 6)]), cloth)
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.25, 0.16, 0.1), 1.6)
	# bras armé : coutelas (levé en préparation, tendu pendant le coup)
	var hand := Vector2(f * 8.0, -2.0)
	var blade_dir := Vector2(f, -0.2).normalized()
	match state:
		"windup_slash":
			hand = Vector2(-f * 2.0, -14.0)
			blade_dir = Vector2(-f * 0.3, -1.0).normalized()
		"slash":
			hand = Vector2(f * 12.0, -4.0)
			blade_dir = Vector2(f, 0.1).normalized()
		"windup_throw":
			hand = Vector2(-f * 6.0, -14.0)
			blade_dir = Vector2(f * 0.4, -1.0).normalized()
	draw_line(Vector2(f * 4.0, -4.0), hand, skin, 2.2)
	var bl := 12.0 if state != "windup_throw" else 7.0
	DU.flat(self, PackedVector2Array([hand + blade_dir.orthogonal() * 1.6, hand + blade_dir * bl, hand - blade_dir.orthogonal() * 1.6]), Color(0.82, 0.84, 0.88))
	draw_line(hand - blade_dir.orthogonal() * 2.5, hand + blade_dir.orthogonal() * 2.5, Color(0.5, 0.35, 0.2), 1.6)
	if state == "slash":
		draw_arc(Vector2(f * 6.0, -6.0), 18.0, -0.9 if f > 0 else PI - 0.6, 0.6 if f > 0 else PI + 0.9, 10, Color(1, 1, 1, 0.5), 3.0)
	# tête : grandes oreilles pointues, nez crochu, yeux jaunes, sourire à dents
	var hd := Vector2(f * 1.0, -13.0)
	for s in [-1.0, 1.0]:
		DU.flat(self, PackedVector2Array([hd + Vector2(s * 5.0, -2.0), hd + Vector2(s * 15.0, -7.0), hd + Vector2(s * 6.0, 2.0)]), skin.darkened(0.08))
	DU.ball(self, hd, 7.0, skin)
	DU.flat(self, PackedVector2Array([hd + Vector2(f * 3.0, -1.0), hd + Vector2(f * 10.0, 2.5), hd + Vector2(f * 3.0, 2.0)]), skin.darkened(0.15))
	var eye := Color(1.0, 0.85, 0.2) if not elite else Color(1.0, 0.35, 0.25)
	draw_circle(hd + Vector2(f * 2.0, -2.5), 1.7, eye)
	draw_circle(hd + Vector2(f * 2.5, -2.5), 0.7, Color(0.1, 0.05, 0.02))
	draw_line(hd + Vector2(-f * 1.0, 3.5), hd + Vector2(f * 4.0, 3.0), Color(0.2, 0.1, 0.05), 1.2)
	for k in 2:
		DU.flat(self, PackedVector2Array([hd + Vector2(f * (0.5 + k * 2.0), 3.3), hd + Vector2(f * (1.5 + k * 2.0), 3.2), hd + Vector2(f * (1.0 + k * 2.0), 4.8)]), Color(0.95, 0.92, 0.8))
	# capuche / bonnet
	DU.flat(self, PackedVector2Array([hd + Vector2(-6, -4), hd + Vector2(6, -4), hd + Vector2(-f * 4.0, -12.0)]), Color(0.55, 0.2, 0.18))
	draw_stun(-30.0)

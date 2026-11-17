extends "res://scripts/boss_base.gd"
# La Reine Essaim : guêpe géante qui vole.
# Attaques : piqué sur le joueur, salve de dards (3 tirs visés), anneau de spores,
# invocation de volants. Phase 2 : piqués doublés, anneaux en spirale, plus de sbires.

const FlyerScript = preload("res://scripts/flyer.gd")
var hover_target := Vector2.ZERO
var shots_left := 0
var dive_dir := Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	boss_setup(Vector2(86, 62), 42, "La Reine Essaim")
	home.y -= 120.0
	global_position = home

func reset() -> void:
	super.reset()
	global_position = home

func _choose() -> void:
	face_player()
	var a := pick({"dive": 3, "barrage": 3, "ring": 2, "summon": 1.0})
	match a:
		"dive":
			go("windup_dive", tele(0.55))
		"barrage":
			shots_left = 3 if phase == 1 else 5
			go("windup_barrage", tele(0.45))
		"ring":
			go("windup_ring", tele(0.6))
		"summon":
			go("windup_summon", 0.7)

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	match state:
		"idle", "recover":
			# plane au-dessus du joueur en dessinant des huit
			hover_target = Vector2(pp.x + sin(anim_t * 0.9) * 140.0, floor_y - 230.0 + sin(anim_t * 1.8) * 30.0)
			velocity = velocity.move_toward((hover_target - global_position).limit_length(1.0) * 210.0 * rage(), 900.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.6 / rage())
		"windup_dive":
			velocity = velocity.move_toward(Vector2(0, -60), 900.0 * delta)
			if state_t <= 0.0:
				dive_dir = (pp - global_position).normalized()
				go("dive", 0.7)
		"dive":
			velocity = dive_dir * 640.0 * rage()
			if global_position.y > floor_y - size.y / 2.0 - 4.0 or state_t <= 0.0:
				main.shake(8)
				if phase == 2 and last_attack == "dive" and randf() < 0.6:
					go("windup_dive", 0.35)    # second piqué enchaîné
				else:
					go("recover", 0.8 / rage())
		"windup_barrage":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				main.spawn_projectile(global_position + Vector2(0, 26), (pp - global_position).normalized() * 330.0 * spd(), {"kind": "spore", "radius": 8.0})
				Audio.sfx("spit", 0.1, -4.0)
				shots_left -= 1
				go("windup_barrage" if shots_left > 0 else "recover", 0.22 if shots_left > 0 else 0.7)
		"windup_ring":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				var n := 10 if phase == 1 else 14
				var off := anim_t
				for i in n:
					main.spawn_projectile(global_position, Vector2.from_angle(off + i * TAU / n) * 200.0 * spd(), {"kind": "spore"})
				if phase == 2:
					for i in n:   # spirale : second anneau décalé, un peu plus tard
						main.spawn_projectile(global_position, Vector2.from_angle(off + (i + 0.5) * TAU / n) * 150.0 * spd(), {"kind": "spore"})
				Audio.sfx("spit", 0.0, -2.0)
				go("recover", 0.9)
		"windup_summon":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				for i in (2 if phase == 1 else 3):
					main.spawn_minion(FlyerScript, global_position + Vector2(-60 + i * 60, -30))
				go("recover", 1.0)
	move_and_slide()

func _draw() -> void:
	var f := float(dir)
	var flap := sin(anim_t * 32.0)
	var tele := telegraphing()
	var body := Color(0.95, 0.72, 0.18) if not tele or fmod(anim_t, 0.12) > 0.06 else Color(1, 0.4, 0.3)
	if stun_t > 0.0:
		body = body.darkened(0.4)
	body = body_color(body)
	var dark := body_color(Color(0.12, 0.09, 0.05))
	var fur := body_color(Color(0.45, 0.3, 0.12))
	DU.glow(self, Vector2(0, -10), 70.0, Color(1.0, 0.8, 0.3), 0.18)
	# ailes du fond
	_wing(Vector2(-f * 6, -20), f, -2.0 + flap * 0.5, 0.2)
	# pattes pendantes à trois segments
	for i in 3:
		var lx := f * (2 + i * 9)
		var sw := sin(anim_t * 8.0 + i) * 3.0
		leg(Vector2(lx, 8), Vector2(lx + f * 4, 16 + sw * 0.3), Vector2(lx - f * 4 + sw, 26), dark, 2.6)
		draw_line(Vector2(lx - f * 4 + sw, 26), Vector2(lx - f * 7 + sw, 28), dark, 1.6)
	# abdomen : anneaux rayés, duvet, dard
	var ab := Vector2(-f * 26, 6)
	DU.poly(self, DU.ellipse(ab, Vector2(30, 20), 30), body)
	for i in 4:
		var sx := ab.x + f * (12.0 - i * 9.0)
		var band := PackedVector2Array()
		for k in 9:
			var t := k / 8.0
			var yy := lerpf(-19.0, 19.0, t)
			var bulge := sqrt(maxf(0.0, 1.0 - pow(yy / 20.0, 2.0))) * 3.0
			band.append(Vector2(sx - f * bulge, ab.y + yy * (1.0 - absf(sx - ab.x) / 40.0)))
		draw_polyline(band, dark, 5.0)
	draw_arc(ab + Vector2(f * 4, -4), 16.0, PI * 1.1, PI * 1.5, 10, Color(1, 0.95, 0.7, 0.6), 2.4)
	DU.poly(self, PackedVector2Array([ab + Vector2(-f * 27, -5), ab + Vector2(-f * 50, 3), ab + Vector2(-f * 27, 8)]), body_color(Color(0.92, 0.9, 0.84)))
	if tele:
		draw_circle(ab + Vector2(-f * 50, 3), 3.0, Color(1, 0.9, 0.6))
	# thorax velu
	var th := Vector2(f * 8, -2)
	DU.poly(self, DU.ellipse(th, Vector2(18, 15), 26), fur)
	for i in 12:
		var a := i * TAU / 12.0
		var bp := th + Vector2(cos(a) * 17.0, sin(a) * 14.0)
		draw_line(bp, bp + Vector2(cos(a), sin(a)) * 3.5, fur.lightened(0.15), 1.4)
	# collerette royale
	for i in 5:
		var a := -PI * 0.9 + i * 0.4
		DU.poly(self, PackedVector2Array([th + Vector2(f * 14, -2), th + Vector2(f * 14, -2) + Vector2(cos(a) * 9.0 * f, sin(a) * 9.0), th + Vector2(f * 14, -2) + Vector2(cos(a + 0.3) * 9.0 * f, sin(a + 0.3) * 9.0)]), body_color(Color(0.95, 0.92, 0.85)))
	# tête : gros yeux composés, mandibules, antennes
	var hd := Vector2(f * 30, -8)
	DU.poly(self, DU.ellipse(hd, Vector2(15, 13), 22), body)
	var eye := Color(1.0, 0.3, 0.2) if not tele else Color(1, 1, 0.6)
	DU.poly(self, DU.ellipse(hd + Vector2(f * 6, -3), Vector2(6.5, 8), 16), Color(0.12, 0.02, 0.06))
	for k in 6:
		draw_circle(hd + Vector2(f * (4.0 + (k % 2) * 3.0), -8 + k * 2.2), 1.2, Color(eye, 0.75))
	DU.glow(self, hd + Vector2(f * 6, -3), 12.0, eye, 0.35)
	DU.poly(self, PackedVector2Array([hd + Vector2(f * 11, 7), hd + Vector2(f * 19, 10), hd + Vector2(f * 12, 12)]), dark)
	for k in [0.0, 1.0]:
		draw_polyline(PackedVector2Array([hd + Vector2(f * (2 + k * 4), -12), hd + Vector2(f * (6 + k * 6), -24), hd + Vector2(f * (14 + k * 6), -28 + sin(anim_t * 4.0 + k) * 2.0)]), dark, 1.6)
	# couronne d'or à gemmes
	var crown := PackedVector2Array([Vector2(hd.x - 11, hd.y - 10)])
	for i in 5:
		crown.append(Vector2(hd.x - 11 + i * 5.5, hd.y - (24.0 if i % 2 == 0 else 15.0) - (5.0 if i == 2 else 0.0)))
	crown.append(Vector2(hd.x + 11, hd.y - 10))
	DU.poly(self, crown, body_color(Color(1.0, 0.86, 0.45)))
	DU.ball(self, Vector2(hd.x, hd.y - 15), 2.4, Color(0.9, 0.2, 0.3))
	# aile de devant
	_wing(Vector2(-f * 2, -18), f, -1.6 - flap * 0.5, 0.32)
	draw_stun(-50.0)

func _wing(root: Vector2, f: float, ang: float, a: float) -> void:
	var dir_v := Vector2.from_angle(ang if f > 0 else PI - ang)
	var side := dir_v.orthogonal() * 12.0
	var pts := PackedVector2Array()
	for i in 15:
		var t := i / 14.0
		pts.append(root + dir_v * 46.0 * t + side * sin(t * PI) * (1.0 + 0.3 * t))
	pts.append(root)
	DU.flat(self, pts, Color(0.8, 0.92, 1.0, a))
	draw_polyline(pts, Color(0.9, 0.97, 1.0, a + 0.3), 1.2)
	for k in 3:
		draw_line(root, root + dir_v * (20.0 + k * 12.0) + side * (0.9 - k * 0.3), Color(0.35, 0.4, 0.45, a + 0.2), 0.9)
	draw_line(root + dir_v * 18.0 + side * 0.9, root + dir_v * 34.0 + side * 0.2, Color(0.35, 0.4, 0.45, a + 0.2), 0.8)

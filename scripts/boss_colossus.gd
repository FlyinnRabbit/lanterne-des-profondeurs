extends "res://scripts/boss_base.gd"
# Le Colosse d'Os : géant d'ossements, lent mais dévastateur.
# Attaques : poing frappé au sol (ondes de choc des deux côtés + rochers qui tombent du plafond),
# balayage du bras (longue portée devant lui), et en phase 2 un bond écrasant
# suivi d'une rangée de piliers d'os.

var sweep_t := 0.0

func _ready() -> void:
	boss_setup(Vector2(100, 112), 62, "Le Colosse d'Os")
	floor_snap_length = 8.0

# Pendant le balayage, la zone dangereuse s'étend devant lui
func telegraph() -> int:
	if state == "windup_sweep":
		return 2
	return super.telegraph()

func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if sweep_t > 0.0:
		r = r.merge(Rect2(global_position + Vector2(dir * 40.0 - (110.0 if dir < 0 else 0.0), 10), Vector2(110, 24)))   # balayage à hauteur de tête : s'accroupir ou sauter
	return r

func _choose() -> void:
	face_player()
	var dist: float = absf(p().global_position.x - global_position.x)
	var w := {"slam": 3, "walk": 1.5}
	if dist < 220.0:
		w["sweep"] = 3
	if phase == 2:
		w["stomp"] = 3
	match pick(w):
		"slam":
			go("windup_slam", tele(0.75))
		"sweep":
			go("windup_sweep", tele(0.5))
		"stomp":
			go("windup_stomp", tele(0.6))
		"walk":
			go("walk", 1.2)

func _tick(delta: float) -> void:
	var pp: Vector2 = p().global_position
	velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
	sweep_t -= delta
	match state:
		"idle", "recover":
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.5 / rage())
		"walk":
			face_player()
			velocity.x = dir * 70.0 * rage()
			if state_t <= 0.0:
				go("idle", 0.2)
		"windup_slam":
			velocity.x = 0.0
			if state_t <= 0.0:
				_slam()
				go("recover", 1.0 / rage())
		"windup_sweep":
			velocity.x = 0.0
			if state_t <= 0.0:
				sweep_t = 0.35
				velocity.x = dir * 160.0
				Audio.sfx("slash", 0.0, 2.0)
				go("recover", 0.8 / rage())
		"windup_stomp":
			velocity.x = 0.0
			if state_t <= 0.0:
				velocity.y = -760.0
				velocity.x = clampf((pp.x - global_position.x) * 1.2, -420.0, 420.0)
				go("stomp", 0.3)
		"stomp":
			if is_on_floor() and state_t <= 0.0:
				_slam(false)
				for i in 5:
					main.spawn_pillar(global_position.x + dir * (90.0 + i * 75.0), floor_y, i * 0.15, {"color": Color(0.9, 0.88, 0.75), "warn": 0.6})
				go("recover", 0.9 / rage())
	move_and_slide()

func _slam(rocks := true) -> void:
	main.shake(16)
	Controls.rumble(0.6, 0.9, 0.3)
	main.spawn_burst(global_position + Vector2(dir * 40, size.y / 2.0), Color(0.75, 0.72, 0.65), 30, 280.0)
	var y := floor_y - 4.0
	for d in [-1.0, 1.0]:
		main.spawn_projectile(Vector2(global_position.x + d * 60.0, y), Vector2(d * 300.0 * spd(), 0), {"kind": "wave"})
	if rocks:
		var n := 4 if phase == 1 else 6
		for i in n:
			var x: float = p().global_position.x + randf_range(-260.0, 260.0)
			main.spawn_projectile(Vector2(x, floor_y - 330.0 - randf() * 30.0), Vector2(0, 40), {"kind": "rock", "gravity": 700.0, "radius": 11.0, "life": 4.0})

# os peint : trait épais sombre puis clair, reflet fin
func _bone(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	draw_line(a, b, c.darkened(0.45), w + 2.0)
	draw_line(a, b, c, w)
	var n := (b - a).orthogonal().normalized() * w * 0.25
	draw_line(a - n, b - n, DU.lit(c, 1.25, 0.06), w * 0.3)
	DU.ball(self, a, w * 0.62, c)
	DU.ball(self, b, w * 0.62, c)

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var bone := Color(0.86, 0.83, 0.74)
	if tele and fmod(anim_t, 0.14) < 0.07:
		bone = Color(1.0, 0.7, 0.6)
	if stun_t > 0.0:
		bone = bone.darkened(0.35)
	bone = body_color(bone)
	var dark := Color(0.12, 0.1, 0.1)
	var breathe := sin(anim_t * 2.0) * 2.0
	var ember := Color(1.0, 0.45, 0.15)
	DU.glow(self, Vector2(0, -8 + breathe), 60.0, ember, 0.25 + 0.1 * sin(anim_t * 4.0))
	# jambes : fémur, genou, tibia, pied
	for k in [-1.0, 1.0]:
		var hip := Vector2(k * 20, 20)
		var knee := Vector2(k * 27, 38)
		var foot := Vector2(k * 26, 56)
		_bone(hip, knee, 8.0, bone.darkened(0.08 if k < 0 else 0.0))
		_bone(knee, foot, 7.0, bone.darkened(0.08 if k < 0 else 0.0))
		DU.poly(self, PackedVector2Array([foot + Vector2(-10, 4), foot + Vector2(-8, -4), foot + Vector2(10 * f, -4), foot + Vector2(14 * f, 4)]) if f > 0 else PackedVector2Array([foot + Vector2(-14, 4), foot + Vector2(-10, -4), foot + Vector2(8, -4), foot + Vector2(10, 4)]), bone)
	# bassin
	DU.poly(self, PackedVector2Array([Vector2(-34, 14), Vector2(-20, 8), Vector2(0, 12), Vector2(20, 8), Vector2(34, 14), Vector2(24, 26), Vector2(0, 22), Vector2(-24, 26)]), bone.darkened(0.12))
	draw_circle(Vector2(-14, 17), 4.0, dark)
	draw_circle(Vector2(14, 17), 4.0, dark)
	# colonne vertébrale en vertèbres
	for i in 7:
		var y := 14.0 - i * 7.0 + breathe * (i / 7.0)
		DU.poly(self, DU.ellipse(Vector2(0, y), Vector2(6, 3.4), 12), bone)
		draw_line(Vector2(-7, y), Vector2(7, y), bone.darkened(0.4), 1.0)
	# cœur de braise derrière les côtes
	DU.ball(self, Vector2(0, -8 + breathe), 8.0, Color(0.95, 0.45, 0.2))
	draw_circle(Vector2(0, -8 + breathe), 4.0, Color(1.0, 0.85, 0.5, 0.6 + 0.3 * sin(anim_t * 4.0)))
	# cage thoracique : côtes courbes en deux tons
	for i in 4:
		var y := -24.0 + i * 10.0 + breathe
		var r := 30.0 - i * 3.0
		for side in [0.15, 1.15]:
			draw_arc(Vector2(0, y), r, PI * side, PI * (side + 0.7), 14, bone.darkened(0.45), 7.0)
			draw_arc(Vector2(0, y), r, PI * side, PI * (side + 0.7), 14, bone, 4.6)
			draw_arc(Vector2(0, y - 1), r, PI * (side + 0.2), PI * (side + 0.45), 8, DU.lit(bone, 1.2, 0.06), 1.4)
	DU.poly(self, PackedVector2Array([Vector2(-5, -32 + breathe), Vector2(5, -32 + breathe), Vector2(4, 4 + breathe), Vector2(-4, 4 + breathe)]), bone.darkened(0.05))
	# braises qui s'échappent
	for k in 3:
		var t := fposmod(anim_t * 0.8 + k * 0.33, 1.0)
		draw_circle(Vector2(sin(anim_t * 2.0 + k * 2.0) * 10.0, -8 - t * 50.0), 1.6 * (1.0 - t), Color(1.0, 0.6, 0.2, 1.0 - t))
	# bras : levés pendant l'annonce du coup de poing
	var arm_up := state == "windup_slam" or state == "windup_stomp"
	for k in [-1.0, 1.0]:
		var sh := Vector2(k * 38, -34 + breathe)
		var hand := sh + (Vector2(k * 20, -60) if arm_up else Vector2(k * 18, 40))
		if sweep_t > 0.0 and k == f:
			hand = sh + Vector2(k * 110, 56)
		var elbow := sh.lerp(hand, 0.5) + Vector2(k * 10, 4)
		_bone(sh, elbow, 9.0, bone)
		_bone(elbow, hand, 8.0, bone)
		# poing de phalanges
		DU.ball(self, hand, 14.0, bone.darkened(0.08))
		for j in 4:
			var a := -PI * 0.5 + (j - 1.5) * 0.45 + (PI if (hand - elbow).y < 0 else 0.0)
			DU.ball(self, hand + Vector2.from_angle(a + PI * 0.5) * 11.0, 4.5, bone)
		DU.poly(self, DU.ellipse(sh, Vector2(13, 9), 14), bone.darkened(0.1))
		draw_line(sh + Vector2(-8, -4), sh + Vector2(8, -4), bone.darkened(0.45), 1.0)
	# crâne : voûte, orbites, mâchoire, fêlure
	var sk := Vector2(f * 4, -58 + breathe)
	DU.poly(self, DU.ellipse(sk, Vector2(22, 20), 26), bone)
	DU.poly(self, PackedVector2Array([sk + Vector2(-13, 8), sk + Vector2(13, 8), sk + Vector2(11, 21), sk + Vector2(-11, 21)]), bone.darkened(0.12))
	draw_polyline(PackedVector2Array([sk + Vector2(-4, -19), sk + Vector2(-1, -12), sk + Vector2(-6, -7)]), bone.darkened(0.55), 1.4)
	var eye := Color(1.0, 0.5, 0.2) if state != "sleep" else Color(0.3, 0.15, 0.1)
	if tele:
		eye = Color(1.0, 0.9, 0.5)
	for k in [-1.0, 1.0]:
		var ep := sk + Vector2(k * 8 + f * 2, -2)
		DU.poly(self, DU.ellipse(ep, Vector2(6.5, 7), 14), dark)
		draw_circle(ep + Vector2(f * 1, 0.5), 2.6, eye)
		if state != "sleep":
			DU.glow(self, ep, 12.0, eye, 0.5)
	DU.poly(self, PackedVector2Array([sk + Vector2(f * 2 - 3, 9), sk + Vector2(f * 2 + 3, 9), sk + Vector2(f * 2, 4)]), dark)
	for i in 5:
		var tx := -10.0 + i * 5.0
		draw_rect(Rect2(sk + Vector2(tx, 12), Vector2(3.6, 5)), Color(0.95, 0.92, 0.82))
	draw_line(sk + Vector2(-12, 17.5), sk + Vector2(12, 17.5), dark, 1.6)
	draw_stun(-90.0)

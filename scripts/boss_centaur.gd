extends "res://scripts/boss_base.gd"
# Le Centaure Archer (boss final possible) : rapide et à distance.
# Attaques : galop à travers l'arène, salve de flèches visées, pluie de flèches annoncée au sol,
# coup de lance à hauteur de tête (s'accroupir !). Phase 2 : saute par-dessus le joueur,
# galop qui laisse des ondes, pluies plus denses.

var gallop_dir := 1
var arrows_left := 0
var marks := []        # [x, délai] : flèches qui vont tomber
var lance_t := 0.0

func _ready() -> void:
	boss_setup(Vector2(70, 96), 76, "Le Centaure Archer")
	floor_snap_length = 8.0

func telegraph() -> int:
	if state == "windup_lance":
		return 2
	return super.telegraph()

func lance_rect() -> Rect2:
	return Rect2(Vector2(global_position.x + dir * 30.0 - (110.0 if dir < 0 else 0.0), floor_y - 54.0), Vector2(110, 18))

func _choose() -> void:
	face_player()
	var dist: float = absf(p().global_position.x - global_position.x)
	var w := {"gallop": 2.5, "volley": 3, "rain": 2}
	if dist < 220.0:
		w["lance"] = 3.5
	if phase == 2:
		w["leap"] = 1.5
	match pick(w):
		"gallop":
			go("windup_gallop", 0.6 / rage())
		"volley":
			arrows_left = 3 if phase == 1 else 5
			go("windup_volley", 0.5 / rage())
		"rain":
			go("windup_rain", 0.5 / rage())
		"lance":
			go("windup_lance", 0.5 / rage())
		"leap":
			go("windup_leap", 0.35 / rage())

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	velocity.y = minf(velocity.y + 1800.0 * delta, 1100.0)
	lance_t -= delta
	if lance_t > 0.0 and lance_rect().intersects(pl.get_rect()) and pl.dash_t <= 0.0:
		pl.receive_hit(global_position, self)
	for m in marks:
		m[1] -= delta
		if m[1] <= 0.0:
			main.spawn_projectile(Vector2(m[0], floor_y - 480.0), Vector2(0, 520.0), {"kind": "dart", "radius": 7.0, "life": 2.0})
	marks = marks.filter(func(m): return m[1] > 0.0)
	match state:
		"idle", "recover":
			face_player()
			# garde ses distances : recule si le joueur est trop près
			var dx: float = pp.x - global_position.x
			var want := 0.0
			if absf(dx) < 180.0:
				want = -signf(dx) * 200.0 * rage()
			elif absf(dx) > 420.0:
				want = signf(dx) * 160.0 * rage()
			velocity.x = move_toward(velocity.x, want, 1400.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.35 / rage())
		"windup_gallop":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			if state_t <= 0.0:
				gallop_dir = 1 if pp.x > global_position.x else -1
				dir = gallop_dir
				Audio.sfx("dash", 0.0, 1.0)
				go("gallop", 1.3)
		"gallop":
			velocity.x = gallop_dir * 560.0 * rage()
			if phase == 2 and int(anim_t * 10) % 4 == 0 and is_on_floor():
				main.spawn_projectile(Vector2(global_position.x, floor_y - 4.0), Vector2(-gallop_dir * 120.0, 0), {"kind": "wave", "life": 0.6})
			if is_on_wall() or global_position.x < home.x - 840.0 or global_position.x > home.x + 190.0 or state_t <= 0.0:
				main.shake(6)
				velocity.x = 0.0
				go("recover", 0.7 / rage())
		"windup_volley":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			face_player()
			if state_t <= 0.0:
				var from := global_position + Vector2(dir * 26.0, -30.0)
				var lead: Vector2 = pp + pl.velocity * 0.25
				main.spawn_projectile(from, (lead - from).normalized() * 460.0 * spd(), {"kind": "dart", "radius": 6.0})
				Audio.sfx("whip", 0.1, -6.0)
				arrows_left -= 1
				go("windup_volley" if arrows_left > 0 else "recover", 0.22 if arrows_left > 0 else 0.8)
		"windup_rain":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			if state_t <= 0.0:
				var n := 6 if phase == 1 else 10
				for i in n:
					marks.append([clampf(pp.x + (i - n / 2.0) * 64.0 + randf_range(-14, 14), home.x - 840.0, home.x + 190.0), 0.8 + i * 0.05])
				Audio.sfx("whip", 0.0, -2.0)
				go("recover", 1.2)
		"windup_lance":
			face_player()
			velocity.x = -dir * 40.0
			if state_t <= 0.0:
				lance_t = 0.25
				velocity.x = dir * 380.0
				Audio.sfx("dash", 0.1, 2.0)
				go("lance", 0.35)
		"lance":
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			if state_t <= 0.0:
				go("recover", 0.6 / rage())
		"windup_leap":
			velocity.x = 0.0
			if state_t <= 0.0:
				var tx: float = clampf(pp.x + signf(pp.x - global_position.x) * 200.0, home.x - 820.0, home.x + 170.0)
				velocity = Vector2((tx - global_position.x) * 1.5, -760.0)
				go("leap", 1.4)
		"leap":
			if is_on_floor() and velocity.y >= 0.0:
				velocity.x = 0.0
				face_player()
				arrows_left = 3
				go("windup_volley", 0.15)
	move_and_slide()

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var hide := body_color(Color(0.42, 0.29, 0.2))
	var skin := body_color(Color(0.55, 0.5, 0.62))
	if tele and fmod(anim_t, 0.12) < 0.06:
		hide = Color(1, 0.95, 0.85)
		skin = hide
	if stun_t > 0.0:
		hide = hide.darkened(0.3)
	var mane := body_color(Color(0.16, 0.12, 0.1))
	var steel := body_color(Color(0.42, 0.45, 0.55))
	var gal := absf(velocity.x) > 50.0
	var ph := anim_t * (16.0 if gal else 3.0)
	# jambes du fond
	for i in [1, 3]:
		_hleg(i, ph, gal, hide.darkened(0.35), f)
	# queue en mèches
	for k in 3:
		var tail := PackedVector2Array()
		for j in 6:
			var t := j / 5.0
			tail.append(Vector2(-f * (46 + t * 18), -2 + t * 26 + sin(ph + t * 2.0 + k) * 3.0 * t + k * 2.0))
		draw_polyline(tail, mane.lightened(k * 0.06), 3.0 - k * 0.5)
	# corps de cheval : croupe, ventre, caparaçon
	var bx := -f * 10
	DU.poly(self, DU.ellipse(Vector2(bx, 8), Vector2(40, 18), 30), hide)
	DU.poly(self, DU.ellipse(Vector2(bx - f * 20, 2), Vector2(18, 15), 18), hide.lightened(0.04))
	var cap := PackedVector2Array([Vector2(bx - f * 14, -6), Vector2(bx + f * 22, -8), Vector2(bx + f * 24, 16), Vector2(bx + f * 4, 22), Vector2(bx - f * 16, 18)])
	DU.poly(self, cap, body_color(Color(0.45, 0.15, 0.18)))
	draw_polyline(PackedVector2Array([Vector2(bx + f * 24, 16), Vector2(bx + f * 4, 22), Vector2(bx - f * 16, 18)]), Color(0.9, 0.75, 0.35), 2.0)
	for k in 3:
		DU.ball(self, Vector2(bx + f * (-8 + k * 10), 19 - absf(k - 1) * 1.5), 2.0, Color(0.9, 0.75, 0.35))
	# jambes de devant
	for i in [0, 2]:
		_hleg(i, ph, gal, hide, f)
	# buste en cuirasse
	var torso := PackedVector2Array([Vector2(f * 14, 0), Vector2(f * 34, 0), Vector2(f * 33, -30), Vector2(f * 30, -38), Vector2(f * 17, -38), Vector2(f * 14, -30)])
	DU.poly(self, torso, steel)
	draw_line(Vector2(f * 24, -36), Vector2(f * 24, -2), steel.darkened(0.45), 1.2)
	for yy in [-22.0, -12.0]:
		draw_line(Vector2(f * 15, yy), Vector2(f * 33, yy), steel.darkened(0.4), 1.0)
	DU.poly(self, DU.ellipse(Vector2(f * 16, -34), Vector2(7, 5), 12), steel.lightened(0.1))
	# carquois dans le dos
	DU.poly(self, PackedVector2Array([Vector2(f * 8, -40), Vector2(f * 14, -42), Vector2(f * 18, -10), Vector2(f * 12, -8)]), body_color(Color(0.35, 0.22, 0.14)))
	for k in 3:
		draw_line(Vector2(f * (10 + k * 2), -40), Vector2(f * (7 + k * 2), -52), Color(0.85, 0.8, 0.7), 1.2)
		DU.flat(self, PackedVector2Array([Vector2(f * (7 + k * 2), -52), Vector2(f * (5 + k * 2), -56), Vector2(f * (9 + k * 2), -55)]), Color(0.85, 0.3, 0.25))
	# tête : visage dans l'ombre du heaume à cimier
	DU.ball(self, Vector2(f * 24, -46), 10.0, skin)
	var helm := PackedVector2Array([Vector2(f * 12, -44), Vector2(f * 13, -54), Vector2(f * 24, -62), Vector2(f * 35, -54), Vector2(f * 36, -46), Vector2(f * 30, -48), Vector2(f * 18, -48)])
	DU.poly(self, helm, steel.darkened(0.1))
	var crest := PackedVector2Array()
	for k in 8:
		var t := k / 7.0
		crest.append(Vector2(f * (24 - t * 26), -62 + t * 10 - sin(t * PI) * 6.0 + sin(ph * 0.5 + t * 3.0) * 2.0 * t))
	draw_polyline(crest, Color(0.75, 0.2, 0.2), 4.0)
	draw_line(Vector2(f * 26, -46), Vector2(f * 34, -46), Color(0.05, 0.04, 0.05), 2.4)
	var eye := Color(1.0, 0.8, 0.4) if not tele else Color(1, 1, 0.8)
	draw_circle(Vector2(f * 30, -46), 1.6, eye)
	DU.glow(self, Vector2(f * 30, -46), 8.0, eye, 0.5)
	# arc ou lance
	if state in ["windup_lance", "lance"] or lance_t > 0.0:
		var lx2 := f * 30.0 + (f * 40.0 if lance_t > 0.0 else -f * 10.0)
		draw_line(Vector2(f * 20, -24), Vector2(lx2 + f * 70, -24), Color(0.3, 0.2, 0.12), 4.0)
		draw_line(Vector2(f * 20, -25), Vector2(lx2 + f * 70, -25), Color(0.65, 0.5, 0.32), 1.4)
		DU.poly(self, PackedVector2Array([Vector2(lx2 + f * 70, -31), Vector2(lx2 + f * 90, -24), Vector2(lx2 + f * 70, -17)]), Color(0.85, 0.87, 0.92))
		draw_line(Vector2(lx2 + f * 66, -24), Vector2(lx2 + f * 62, -12 + sin(anim_t * 8.0) * 2.0), Color(0.8, 0.2, 0.2), 2.4)
		DU.ball(self, Vector2(f * 36, -24), 3.6, skin)
	else:
		var a0 := -PI / 2 if f > 0 else PI / 2
		var a1 := PI / 2 if f > 0 else 3 * PI / 2
		var draw_k := 6.0 if state == "windup_volley" or state == "windup_rain" else 0.0
		draw_arc(Vector2(f * 36, -26), 23.0, a0, a1, 20, Color(0.3, 0.2, 0.12), 5.0)
		draw_arc(Vector2(f * 36, -26), 23.0, a0, a1, 20, Color(0.65, 0.48, 0.28), 2.6)
		draw_polyline(PackedVector2Array([Vector2(f * 36, -49), Vector2(f * (36 - draw_k), -26), Vector2(f * 36, -3)]), Color(0.92, 0.92, 0.85, 0.8), 1.0)
		DU.ball(self, Vector2(f * 36, -26), 3.6, skin)
		if draw_k > 0.0:
			draw_line(Vector2(f * (36 - draw_k), -26), Vector2(f * 62, -26), Color(0.85, 0.8, 0.7), 1.6)
			DU.glow(self, Vector2(f * 62, -26), 10.0, Color(1, 0.8, 0.4), 0.5)
	# flèches annoncées : marques au sol
	for m in marks:
		var mp := Vector2(m[0], floor_y) - global_position
		var a := 0.4 + 0.4 * absf(sin(anim_t * 14.0))
		DU.glow(self, mp + Vector2(0, -4), 16.0, Color(1.0, 0.4, 0.3), a * 0.6)
		draw_line(mp + Vector2(-8, -2), mp + Vector2(8, -2), Color(1.0, 0.4, 0.3, a), 3.0)
		draw_line(mp + Vector2(0, -10), mp + Vector2(0, -2), Color(1.0, 0.4, 0.3, a), 2.0)
	draw_stun(-74.0)

func _hleg(i: int, ph: float, gal: bool, c: Color, f: float) -> void:
	var lx := -f * 10 + (-30 + i * 20)
	var sw := sin(ph + i * 1.6) * (10.0 if gal else 2.0)
	var top := Vector2(lx, 16)
	var knee := Vector2(lx + sw * 0.5 + f * 3, 32)
	var hoof := Vector2(lx + sw, 47)
	draw_line(top, knee, c, 8.0)
	draw_line(knee, hoof, c, 5.0)
	draw_circle(knee, 3.6, c)
	draw_line(hoof + Vector2(0, -6), hoof + Vector2(0, -3), Color(0.15, 0.12, 0.1, 0.6), 6.0)
	DU.poly(self, PackedVector2Array([hoof + Vector2(-4, -2), hoof + Vector2(4, -2), hoof + Vector2(5, 3), hoof + Vector2(-5, 3)]), Color(0.18, 0.14, 0.12))

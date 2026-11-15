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
	var hide := body_color(Color(0.42, 0.3, 0.22))
	var skin := body_color(Color(0.55, 0.5, 0.6))
	if tele and fmod(anim_t, 0.12) < 0.06:
		hide = Color(1, 0.95, 0.85)
		skin = hide
	if stun_t > 0.0:
		hide = hide.darkened(0.3)
	var gal := absf(velocity.x) > 50.0
	var ph := anim_t * (16.0 if gal else 3.0)
	# corps de cheval
	draw_colored_polygon(DU.ellipse(Vector2(-f * 10, 8), Vector2(40, 18)), hide)
	for i in 4:
		var lx := -f * 10 + (-30 + i * 20)
		var sw := sin(ph + i * 1.6) * (10.0 if gal else 2.0)
		draw_line(Vector2(lx, 18), Vector2(lx + sw, 48), hide.darkened(0.15), 6.0)
		draw_circle(Vector2(lx + sw, 48), 4.0, Color(0.15, 0.12, 0.1))
	# queue
	draw_line(Vector2(-f * 48, 0), Vector2(-f * 62, 20 + sin(ph) * 4.0), Color(0.2, 0.15, 0.12), 5.0)
	# buste humain
	draw_colored_polygon(PackedVector2Array([Vector2(f * 14, 0), Vector2(f * 34, 0), Vector2(f * 30, -36), Vector2(f * 16, -36)]), skin)
	draw_circle(Vector2(f * 24, -46), 11.0, skin)
	draw_colored_polygon(PackedVector2Array([Vector2(f * 12, -50), Vector2(f * 36, -50), Vector2(f * 24, -66)]), Color(0.3, 0.32, 0.4))   # heaume
	draw_circle(Vector2(f * 28, -46), 2.5, Color(1.0, 0.8, 0.4))
	# arc ou lance
	if state in ["windup_lance", "lance"] or lance_t > 0.0:
		var lx2 := f * 30.0 + (f * 40.0 if lance_t > 0.0 else -f * 10.0)
		draw_line(Vector2(f * 20, -24), Vector2(lx2 + f * 70, -24), Color(0.5, 0.4, 0.3), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(lx2 + f * 70, -30), Vector2(lx2 + f * 86, -24), Vector2(lx2 + f * 70, -18)]), Color(0.85, 0.87, 0.92))
	else:
		draw_arc(Vector2(f * 36, -26), 22.0, -PI / 2 if f > 0 else PI / 2, PI / 2 if f > 0 else 3 * PI / 2, 16, Color(0.55, 0.4, 0.25), 3.0)
		draw_line(Vector2(f * 36, -48), Vector2(f * 36, -4), Color(0.9, 0.9, 0.85, 0.7), 1.0)
	# flèches annoncées : marques au sol
	for m in marks:
		var mp := Vector2(m[0], floor_y) - global_position
		var a := 0.4 + 0.4 * absf(sin(anim_t * 14.0))
		draw_line(mp + Vector2(-8, -2), mp + Vector2(8, -2), Color(1.0, 0.4, 0.3, a), 3.0)
		draw_line(mp + Vector2(0, -10), mp + Vector2(0, -2), Color(1.0, 0.4, 0.3, a), 2.0)
	draw_stun(-74.0)

extends "res://scripts/boss_base.gd"
# Le Ver des Profondeurs : il s'enfouit, file sous le sol (un sillon de poussière l'annonce)
# puis jaillit sous le joueur en crachant de l'acide en cloche. Il peut aussi charger en surface.
# Phase 2 : trois jaillissements d'affilée, plus d'acide, ondes de choc à l'atterrissage.

var trail: Array[Vector2] = []
var under := false
var emerges_left := 0
var dust_t := 0.0

func _ready() -> void:
	boss_setup(Vector2(54, 54), 48, "Le Ver des Profondeurs")
	floor_snap_length = 6.0
	for i in 9:
		trail.append(global_position)

func is_harmful() -> bool:
	return super.is_harmful() and not under

func reset() -> void:
	super.reset()
	under = false
	collision_mask = 1

func _choose() -> void:
	face_player()
	match pick({"burrow": 4, "charge": 2, "spit": 2}):
		"burrow":
			emerges_left = 1 if phase == 1 else 3
			go("windup_burrow", 0.4 / rage())
		"charge":
			go("windup_charge", 0.5 / rage())
		"spit":
			go("windup_spit", 0.45 / rage())

func _tick(delta: float) -> void:
	var pp: Vector2 = p().global_position
	if not under:
		velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
	match state:
		"idle", "recover":
			velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.4 / rage())
		"windup_burrow":
			velocity.x = 0.0
			if state_t <= 0.0:
				_dig(true)
				go("tunnel", 1.1 / sqrt(rage()))
		"tunnel":
			# file sous le sol vers le joueur ; la poussière trahit sa position
			var tx := pp.x
			global_position.x = move_toward(global_position.x, tx, 360.0 * rage() * delta)
			dust_t -= delta
			if dust_t <= 0.0:
				dust_t = 0.06
				main.spawn_burst(Vector2(global_position.x, floor_y - 2), Color(0.6, 0.5, 0.4), 3, 90.0, 200.0)
			if state_t <= 0.0:
				go("emerge_warn", 0.45)
		"emerge_warn":
			dust_t -= delta
			if dust_t <= 0.0:
				dust_t = 0.04
				main.spawn_burst(Vector2(global_position.x + randf_range(-20, 20), floor_y - 2), Color(0.8, 0.6, 0.45), 4, 160.0, 250.0)
			if state_t <= 0.0:
				_dig(false)
				global_position.y = floor_y - size.y / 2.0 - 2.0
				velocity = Vector2(0, -980.0)
				main.shake(10)
				main.spawn_burst(Vector2(global_position.x, floor_y), Color(0.6, 0.5, 0.4), 24, 300.0)
				_acid(3 if phase == 1 else 5)
				go("airborne", 0.3)
		"airborne":
			if is_on_floor() and state_t <= 0.0:
				if phase == 2:
					for d in [-1.0, 1.0]:
						main.spawn_projectile(Vector2(global_position.x + d * 30.0, floor_y - 4.0), Vector2(d * 280.0 * spd(), 0), {"kind": "wave"})
				emerges_left -= 1
				if emerges_left > 0:
					go("windup_burrow", 0.25)
				else:
					go("recover", 0.9 / rage())
		"windup_charge":
			velocity.x = -dir * 30.0
			if state_t <= 0.0:
				go("charge", 0.9)
		"charge":
			velocity.x = dir * 520.0 * rage()
			if is_on_wall() or state_t <= 0.0:
				if is_on_wall():
					main.shake(10)
				go("recover", 0.7 / rage())
		"windup_spit":
			velocity.x = 0.0
			if state_t <= 0.0:
				_acid(4 if phase == 1 else 6)
				go("recover", 0.8)
	if under:
		velocity = Vector2.ZERO
	else:
		move_and_slide()
	# le corps suit la tête
	trail.push_front(global_position)
	if trail.size() > 9:
		trail.pop_back()

func _dig(down: bool) -> void:
	under = down
	visible = not down
	collision_mask = 0 if down else 1
	if down:
		main.spawn_burst(Vector2(global_position.x, floor_y), Color(0.6, 0.5, 0.4), 20, 240.0)
		global_position.y = floor_y + 80.0

func _acid(n: int) -> void:
	Audio.sfx("spit", 0.0, -2.0)
	for i in n:
		var a := -PI / 2.0 + (i - (n - 1) / 2.0) * 0.32
		main.spawn_projectile(global_position + Vector2(0, -20), Vector2.from_angle(a) * 380.0 * spd(), {"kind": "acid", "gravity": 650.0, "radius": 7.0})

func _draw() -> void:
	var tele := telegraphing()
	var skin := Color(0.55, 0.36, 0.44)
	if tele and fmod(anim_t, 0.12) < 0.06:
		skin = Color(1.0, 0.5, 0.4)
	if stun_t > 0.0:
		skin = skin.darkened(0.35)
	skin = body_color(skin)
	var plate := body_color(Color(0.36, 0.28, 0.3))
	# anneaux du corps (du plus loin au plus proche) : chair, plaque dorsale, soies
	for i in range(trail.size() - 1, 0, -1):
		var lp: Vector2 = trail[i] - global_position + Vector2(0, 4)
		var r := 24.0 - i * 1.6
		var sk := skin.darkened(0.12 + i * 0.03)
		DU.ball(self, lp, r, sk)
		draw_arc(lp, r * 0.92, PI * 1.08, PI * 1.92, 12, plate.darkened(i * 0.03), r * 0.35)
		draw_arc(lp, r * 0.92, PI * 1.25, PI * 1.6, 8, DU.lit(plate, 1.6, 0.06), 1.4)
		draw_arc(lp, r, PI * 0.15, PI * 0.85, 10, sk.darkened(0.4), 1.6)
		for k in 3:
			var a := PI * (0.3 + k * 0.2)
			draw_line(lp + Vector2.from_angle(a) * r, lp + Vector2.from_angle(a) * (r + 5.0), sk.darkened(0.5), 1.2)
	# tête : collerette de plaques, gueule circulaire à dents en spirale
	var f := float(dir)
	for k in 6:
		var a := PI * 1.05 + k * 0.17
		DU.poly(self, PackedVector2Array([Vector2.from_angle(a) * 20.0, Vector2.from_angle(a - 0.12) * 34.0, Vector2.from_angle(a + 0.12) * 32.0]), plate)
	DU.ball(self, Vector2.ZERO, 28.0, skin)
	draw_arc(Vector2.ZERO, 22.0, PI * 1.15, PI * 1.55, 10, Color(1, 0.9, 0.9, 0.35), 2.4)
	var mouth := Vector2(f * 12, -6)
	DU.ball(self, mouth, 14.5, skin.darkened(0.35))
	draw_circle(mouth, 12.5, Color(0.12, 0.02, 0.05))
	draw_circle(mouth, 6.0, Color(0.35, 0.05, 0.12) if not tele else Color(1.0, 0.5, 0.3))
	if tele:
		DU.glow(self, mouth, 22.0, Color(1.0, 0.5, 0.3), 0.6)
	for ring in 2:
		for i in 9:
			var a := i * TAU / 9.0 + anim_t * (0.5 if ring == 0 else -0.8) + ring * 0.35
			var rr := 12.0 - ring * 5.0
			var tp := mouth + Vector2(cos(a), sin(a)) * rr
			DU.poly(self, PackedVector2Array([tp, tp + Vector2(cos(a + 0.6), sin(a + 0.6)) * (4.5 - ring), mouth + Vector2(cos(a), sin(a)) * (rr - 6.0)]), Color(0.95, 0.92, 0.82), false)
	# yeux multiples
	var ec := Color(1.0, 0.85, 0.3) if not tele else Color(1, 1, 0.8)
	for k in 3:
		var ep := Vector2(-f * (4 + k * 7), -18 + k * 3)
		draw_circle(ep, 3.6 - k * 0.6, Color(0.08, 0.04, 0.04))
		draw_circle(ep, 2.4 - k * 0.4, ec)
	DU.glow(self, Vector2(-f * 10, -16), 14.0, ec, 0.4)
	draw_stun(-44.0)

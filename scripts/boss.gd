extends "res://scripts/enemy.gd"
# Boss paramétrable.
#  variant 1 : le Gardien du Puits (charge + bond écrasant)
#  variant 2 : l'Abbesse Engloutie (boss final : + salves de spores, plus rapide)
# Une parade sur un contact l'étourdit un instant : c'est le moment de frapper.

var variant := 1
var max_hp := 32
var boss_name := "Gardien du Puits"
var home := Vector2.ZERO
var state := "sleep"
var state_t := 0.0
var dir := -1

func _ready() -> void:
	size = Vector2(70, 64)
	is_boss = true
	if variant == 2:
		max_hp = 50
		boss_name = "L'Abbesse Engloutie"
	max_hp = roundi(max_hp * float(GameState.scaled("boss_hp")))
	hp = max_hp
	geo_value = 0
	knock_resist = 0.0
	setup_body()
	floor_snap_length = 8.0

func wake() -> void:
	state = "idle"
	state_t = 1.2

func reset() -> void:
	hp = max_hp
	state = "sleep"
	stun_t = 0.0
	global_position = home
	velocity = Vector2.ZERO

func is_harmful() -> bool:
	return not dead and state != "sleep" and stun_t <= 0.0

func rage() -> float:
	var r := 1.3 if hp <= max_hp / 2 else 1.0
	# la difficulté accélère le boss et raccourcit ses pauses
	return r * (1.15 if variant == 2 else 1.0) * sqrt(float(GameState.scaled("speed")) * float(GameState.scaled("aggro")))

func take_hit(dmg: int, dir_hit: Vector2) -> void:
	if state == "sleep":
		return
	super.take_hit(dmg, dir_hit)

func parried(_d: Vector2) -> void:
	flash_t = 0.1
	if not try_stun(1.0 * stun_mult()):
		return
	state = "recover"
	state_t = 1.0
	velocity.x = 0.0

func die() -> void:
	dead = true
	remove_from_group("enemies")
	main.on_boss_killed()
	queue_free()

func _choose() -> void:
	var p = main.player
	dir = -1 if p.global_position.x < global_position.x else 1
	var r := randf()
	if variant == 2 and r < 0.3:
		state = "windup_volley"
		state_t = 0.6 / rage()
	elif variant == 2 and r < 0.45:
		state = "windup_ring"           # anneau de spores autour d'elle
		state_t = 0.7 / rage()
	elif variant == 1 and hp <= max_hp / 2 and r < 0.25:
		state = "windup_quake"          # Gardien enragé : frappe le sol, ondes de choc
		state_t = 0.6 / rage()
	elif r < 0.55:
		state = "windup_charge"
		state_t = 0.55 / rage()
	elif r < 0.85:
		state = "windup_leap"
		state_t = 0.45 / rage()
	else:
		state = "walk"
		state_t = 0.9

func _volley() -> void:
	var p = main.player
	var origin := global_position + Vector2(dir * 30.0, -20.0)
	var aim: float = (p.global_position - origin).angle()
	var n := 7 if hp <= max_hp / 2 else 5
	for i in n:
		var a := aim + (i - (n - 1) / 2.0) * 0.22
		main.spawn_projectile(origin, Vector2.from_angle(a) * 260.0 * spd())

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	state_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
	var p = main.player
	if stun_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	match state:
		"sleep":
			velocity.x = 0.0
		"idle":
			velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
			if state_t <= 0.0:
				_choose()
		"walk":
			dir = -1 if p.global_position.x < global_position.x else 1
			velocity.x = dir * 120.0 * rage()
			if state_t <= 0.0:
				_choose()
		"windup_charge":
			velocity.x = -dir * 20.0
			if state_t <= 0.0:
				state = "charge"
				state_t = 1.1
		"charge":
			velocity.x = dir * 500.0 * rage()
			if is_on_wall() or state_t <= 0.0:
				if is_on_wall():
					main.shake(12)
					main.spawn_burst(global_position + Vector2(dir * 36, 0), Color(0.6, 0.6, 0.7), 20, 220.0)
				state = "recover"
				state_t = 0.8 / rage()
		"windup_leap":
			velocity.x = 0.0
			if state_t <= 0.0:
				state = "leap"
				state_t = 0.25
				velocity.y = -820.0
				velocity.x = clampf((p.global_position.x - global_position.x) * 1.15, -440.0, 440.0)
		"leap":
			if is_on_floor() and state_t <= 0.0:
				main.shake(14)
				main.spawn_burst(global_position + Vector2(0, 30), Color(0.6, 0.6, 0.7), 26, 260.0)
				if variant == 1 and hp <= max_hp / 2:   # atterrissage enragé : ondes de choc
					for d in [-1.0, 1.0]:
						main.spawn_projectile(global_position + Vector2(d * 40.0, 30.0), Vector2(d * 300.0 * spd(), 0), {"kind": "wave"})
				velocity.x = 0.0
				state = "recover"
				state_t = 0.6 / rage()
		"windup_ring":
			velocity.x = 0.0
			if state_t <= 0.0:
				var n := 12 if hp > max_hp / 2 else 16
				for i in n:
					main.spawn_projectile(global_position + Vector2(0, -10), Vector2.from_angle(anim_t + i * TAU / n) * 210.0 * spd())
				state = "recover"
				state_t = 0.8 / rage()
		"windup_quake":
			velocity.x = 0.0
			if state_t <= 0.0:
				main.shake(14)
				for d in [-1.0, 1.0]:
					for k in 2:
						main.spawn_projectile(global_position + Vector2(d * (40.0 + k * 10.0), 30.0), Vector2(d * (260.0 + k * 90.0) * spd(), 0), {"kind": "wave"})
				state = "recover"
				state_t = 0.8 / rage()
		"windup_volley":
			velocity.x = 0.0
			dir = -1 if p.global_position.x < global_position.x else 1
			if state_t <= 0.0:
				_volley()
				state = "recover"
				state_t = 0.7 / rage()
		"recover":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			if state_t <= 0.0:
				state = "idle"
				state_t = 0.35 / rage()
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	var f := float(dir)
	var tele := state.begins_with("windup")
	var lean := 0.0
	if tele:
		lean = -f * 6.0
	elif state == "charge":
		lean = f * 6.0
	var breathe := sin(anim_t * 3.0) * 1.5
	var abb := variant == 2
	var shell_col := Color(0.3, 0.35, 0.48) if not abb else Color(0.66, 0.62, 0.5)
	if tele and fmod(anim_t, 0.12) < 0.06:
		shell_col = Color(0.7, 0.35, 0.3) if state != "windup_volley" else Color(0.75, 0.45, 0.85)
	if stun_t > 0.0:
		shell_col = shell_col.darkened(0.35)
	shell_col = body_color(shell_col)
	var dark := body_color(Color(0.08, 0.07, 0.11))
	var moving := absf(velocity.x) > 10.0
	var step := sin(anim_t * 14.0) * 5.0 if moving else 0.0
	var by := 4 + breathe
	# pattes articulées : rangée du fond plus sombre
	for row in [0, 1]:
		for i in 4:
			var lx := -24.0 + i * 16.0 + (6.0 if row == 0 else 0.0)
			var sw := step if (i + row) % 2 == 0 else -step
			var col := dark.lightened(0.04) if row == 1 else dark.darkened(0.4)
			var hip := Vector2(lx + lean * 0.5, 16 + breathe * 0.5)
			var knee := Vector2(lx - f * 6 + sw * 0.4, 22)
			var foot := Vector2(lx + sw, 32)
			draw_line(hip, knee, col, 6.0)
			draw_line(knee, foot, col, 4.5)
			draw_circle(knee, 3.5, col.lightened(0.08))
			draw_line(foot, foot + Vector2(-f * 4, 0), col, 3.0)
	# ventre segmenté
	DU.poly(self, DU.ellipse(Vector2(lean, 8 + breathe), Vector2(38, 22), 28), dark.lightened(0.06))
	for i in 5:
		var sx := lean - 28 + i * 14
		draw_arc(Vector2(sx, 14 + breathe), 9.0, 0.3, PI - 0.3, 8, dark.lightened(0.18), 1.6)
	# carapace : grandes plaques, arêtes, rivets, mousse ou voile
	var c := Vector2(lean - f * 4, by)
	var shell := DU.ellipse(c, Vector2(36, 30), 30, PI, TAU)
	DU.poly(self, shell, shell_col)
	for i in 4:
		var r := 10.0 + i * 7.0
		draw_arc(c, r, PI + 0.22, TAU - 0.22, 20, shell_col.darkened(0.45), 2.2)
		draw_arc(c + Vector2(0, -1.5), r, PI + 0.4, PI + 1.3, 10, DU.lit(shell_col, 1.5, 0.08), 1.4)
	for i in 6:
		var a := PI + 0.35 + i * 0.48
		draw_circle(c + Vector2(cos(a), sin(a)) * 31.0, 1.8, shell_col.darkened(0.5))
		draw_circle(c + Vector2(cos(a), sin(a)) * 31.0 + Vector2(-0.5, -0.5), 0.8, DU.lit(shell_col, 1.7, 0.1))
	if not abb:
		# pierres et lichen accrochés au dos
		for i in 3:
			var a := PI + 1.0 + i * 0.55
			var sp := c + Vector2(cos(a), sin(a)) * 27.0
			DU.poly(self, DU.ellipse(sp, Vector2(5, 3.5), 10), Color(0.3, 0.32, 0.36))
		for i in 7:
			var a := PI + 0.7 + i * 0.25
			draw_circle(c + Vector2(cos(a), sin(a)) * 29.0, 2.2, Color(0.35, 0.55, 0.5, 0.8))
		# corne frontale
		DU.poly(self, PackedVector2Array([c + Vector2(f * 22, -18), c + Vector2(f * 30, -14), c + Vector2(f * 40, -32)]), body_color(Color(0.75, 0.72, 0.62)))
	else:
		# voile de l'Abbesse : tissu à plis qui ondule
		var w := sin(anim_t * 2.5) * 3.0
		var veil := PackedVector2Array([c + Vector2(-f * 26, -18), c + Vector2(-f * 46, 10 + w), c + Vector2(-f * 50, 26 + w), c + Vector2(-f * 34, 22), c + Vector2(-f * 18, 14)])
		DU.poly(self, veil, body_color(Color(0.86, 0.86, 0.92)))
		for k in 3:
			draw_line(c + Vector2(-f * (24 + k * 6), -12 + k * 4), c + Vector2(-f * (36 + k * 5), 20 + w), Color(0.6, 0.62, 0.72, 0.8), 1.2)
		# chapelet de perles
		for k in 7:
			var a := PI * 0.2 + k * 0.25
			DU.ball(self, c + Vector2(cos(a) * 22.0 * f, 6 + sin(a) * 10.0), 2.2, Color(0.85, 0.8, 0.7))
		# gouttes d'eau qui tombent de la carapace
		for k in 2:
			var dy := fposmod(anim_t * 30.0 + k * 17.0, 28.0)
			draw_circle(c + Vector2(-14 + k * 22, 2 + dy), 1.6, Color(0.6, 0.8, 1.0, 1.0 - dy / 28.0))
		# couronne à gemmes
		var crown := PackedVector2Array([Vector2(c.x - 20, -22 + breathe)])
		for k in 7:
			crown.append(Vector2(c.x - 20 + k * 6.6, (-38.0 if k % 2 == 1 else -26.0) - (6.0 if k == 3 else 0.0) + breathe))
		crown.append(Vector2(c.x + 20, -22 + breathe))
		DU.poly(self, crown, body_color(Color(0.95, 0.82, 0.45)))
		for k in 3:
			var gx := c.x - 13 + k * 13
			DU.ball(self, Vector2(gx, -27 + breathe), 2.6, Color(0.6, 0.4, 0.95) if k != 1 else Color(0.45, 0.85, 0.9))
	# tête : casque, mandibules, yeux
	var head := Vector2(lean + f * 34, 6 + breathe)
	var hc := body_color(Color(0.18, 0.18, 0.27) if not abb else Color(0.3, 0.27, 0.35))
	DU.poly(self, DU.ellipse(head, Vector2(15, 13), 22), hc)
	draw_arc(head, 10.0, PI + 0.3, TAU - 0.3, 10, DU.lit(hc, 1.8, 0.08), 1.6)
	var mand := body_color(Color(0.82, 0.78, 0.68))
	var open := 4.0 if tele else 0.0
	DU.poly(self, PackedVector2Array([head + Vector2(f * 8, 4), head + Vector2(f * 24, 8 - open), head + Vector2(f * 20, 12 - open), head + Vector2(f * 9, 9)]), mand)
	DU.poly(self, PackedVector2Array([head + Vector2(f * 8, 9), head + Vector2(f * 20, 18 + open), head + Vector2(f * 15, 19 + open), head + Vector2(f * 7, 12)]), mand.darkened(0.15))
	# antennes
	draw_polyline(PackedVector2Array([head + Vector2(f * 4, -10), head + Vector2(f * 12, -24), head + Vector2(f * 22, -28 + sin(anim_t * 4.0) * 2.0)]), dark.lightened(0.15), 2.0)
	var eye_col := Color(1.0, 0.45, 0.2) if state != "sleep" else Color(0.35, 0.2, 0.15)
	if abb and state != "sleep":
		eye_col = Color(0.8, 0.5, 1.0)
	if tele:
		eye_col = Color(1.0, 0.9, 0.5)
	if stun_t > 0.0:
		eye_col = Color(0.4, 0.4, 0.45)
		for i in 4:
			var a := anim_t * 4.0 + i * TAU / 4.0
			var sc := Vector2(cos(a) * 26.0, -48.0 + sin(a) * 5.0)
			DU.flat(self, DU.diamond(sc, Vector2(3.5, 4.5)), Color(1, 1, 0.7))
	if state != "sleep":
		DU.glow(self, head + Vector2(f * 5, -3), 16.0 if tele else 10.0, eye_col, 0.6)
	DU.ball(self, head + Vector2(f * 5, -3), 3.8, eye_col)
	DU.ball(self, head + Vector2(f * -2, -5), 2.6, eye_col)
	draw_circle(head + Vector2(f * 4.2, -4.2), 1.0, Color(1, 1, 0.9))

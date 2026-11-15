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
	stun_t = 1.0
	flash_t = 0.1
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
	var shell_col := Color(0.32, 0.36, 0.48) if variant == 1 else Color(0.62, 0.58, 0.45)
	if tele and fmod(anim_t, 0.12) < 0.06:
		shell_col = Color(0.7, 0.35, 0.3) if state != "windup_volley" else Color(0.75, 0.45, 0.85)
	if stun_t > 0.0:
		shell_col = shell_col.darkened(0.35)
	var dark := Color(0.08, 0.07, 0.11)
	var step := sin(anim_t * (14.0 if absf(velocity.x) > 10.0 else 0.0)) * 5.0
	for i in 4:
		var lx := -24.0 + i * 16.0
		draw_line(Vector2(lx, 18), Vector2(lx + (step if i % 2 == 0 else -step), 32), dark, 5.0)
	draw_colored_polygon(DU.ellipse(Vector2(lean, 8 + breathe), Vector2(38, 22)), body_color(dark))
	var shell := DU.ellipse(Vector2(lean - f * 4, 4 + breathe), Vector2(36, 30), 24, PI, TAU)
	draw_colored_polygon(shell, body_color(shell_col))
	for i in 4:
		draw_arc(Vector2(lean - f * 4, 4 + breathe), 10.0 + i * 7.0, PI + 0.25, TAU - 0.25, 16, body_color(shell_col.lightened(0.25)), 2.0)
	if variant == 2:
		# voile et couronne de l'Abbesse
		draw_colored_polygon(PackedVector2Array([Vector2(lean - f * 30, -10), Vector2(lean - f * 52, 26), Vector2(lean - f * 20, 18)]), body_color(Color(0.85, 0.85, 0.9, 0.8)))
		for i in 3:
			var cx := lean - f * 4 - 14 + i * 14
			draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, -24), Vector2(cx + 5, -24), Vector2(cx, -38 - (i % 2) * 6)]), body_color(Color(0.95, 0.85, 0.5)))
	var head := Vector2(lean + f * 34, 6 + breathe)
	draw_colored_polygon(DU.ellipse(head, Vector2(14, 12)), body_color(Color(0.18, 0.18, 0.26)))
	draw_line(head + Vector2(f * 8, 6), head + Vector2(f * 22, 12), body_color(Color(0.8, 0.78, 0.7)), 4.0)
	draw_line(head + Vector2(f * 8, 8), head + Vector2(f * 18, 18), body_color(Color(0.8, 0.78, 0.7)), 4.0)
	var eye_col := Color(1.0, 0.45, 0.2) if state != "sleep" else Color(0.35, 0.2, 0.15)
	if variant == 2 and state != "sleep":
		eye_col = Color(0.8, 0.5, 1.0)
	if tele:
		eye_col = Color(1.0, 0.9, 0.5)
		draw_circle(head + Vector2(f * 5, -3), 10.0, Color(1.0, 0.6, 0.2, 0.25))
	if stun_t > 0.0:
		eye_col = Color(0.4, 0.4, 0.45)
		for i in 4:
			var a := anim_t * 4.0 + i * TAU / 4.0
			draw_circle(Vector2(cos(a) * 26.0, -40.0 + sin(a) * 5.0), 3.0, Color(1, 1, 0.7))
	draw_circle(head + Vector2(f * 5, -3), 3.5, eye_col)
	draw_circle(head + Vector2(f * -2, -5), 2.5, eye_col)

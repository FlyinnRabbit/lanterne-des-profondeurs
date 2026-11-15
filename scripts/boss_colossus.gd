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
			go("windup_slam", 0.75 / rage())
		"sweep":
			go("windup_sweep", 0.5 / rage())
		"stomp":
			go("windup_stomp", 0.6 / rage())
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

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var bone := Color(0.86, 0.83, 0.74)
	if tele and fmod(anim_t, 0.14) < 0.07:
		bone = Color(1.0, 0.7, 0.6)
	if stun_t > 0.0:
		bone = bone.darkened(0.35)
	var dark := Color(0.15, 0.13, 0.12)
	var breathe := sin(anim_t * 2.0) * 2.0
	# jambes
	for k in [-1.0, 1.0]:
		draw_line(Vector2(k * 22, 20), Vector2(k * 26, 56), body_color(bone), 9.0)
		draw_circle(Vector2(k * 26, 56), 8.0, body_color(bone))
	# bassin et colonne
	draw_colored_polygon(DU.ellipse(Vector2(0, 18), Vector2(34, 12)), body_color(bone.darkened(0.15)))
	draw_line(Vector2(0, 18), Vector2(0, -30 + breathe), body_color(bone), 8.0)
	# cage thoracique
	for i in 4:
		var y := -24.0 + i * 10.0 + breathe
		draw_arc(Vector2(0, y), 30.0 - i * 3.0, PI * 0.15, PI * 0.85, 12, body_color(bone), 5.0)
		draw_arc(Vector2(0, y), 30.0 - i * 3.0, PI * 1.15, PI * 1.85, 12, body_color(bone), 5.0)
	draw_circle(Vector2(0, -8 + breathe), 7.0, Color(0.9, 0.4, 0.2, 0.6 + 0.3 * sin(anim_t * 4.0)))   # cœur braise
	# bras : levés pendant l'annonce du coup de poing
	var arm_up := state == "windup_slam" or state == "windup_stomp"
	for k in [-1.0, 1.0]:
		var sh := Vector2(k * 38, -34 + breathe)
		var hand := sh + (Vector2(k * 20, -60) if arm_up else Vector2(k * 18, 40))
		if sweep_t > 0.0 and k == f:
			hand = sh + Vector2(k * 110, 56)
		draw_line(sh, hand, body_color(bone), 10.0)
		draw_circle(hand, 15.0, body_color(bone))
		draw_circle(sh, 10.0, body_color(bone.darkened(0.1)))
	# crâne
	var sk := Vector2(f * 4, -58 + breathe)
	draw_colored_polygon(DU.ellipse(sk, Vector2(22, 20)), body_color(bone))
	draw_rect(Rect2(sk + Vector2(-12, 10), Vector2(24, 10)), body_color(bone.darkened(0.1)))
	for k in [-1.0, 1.0]:
		draw_circle(sk + Vector2(k * 8 + f * 2, -2), 6.0, dark)
		draw_circle(sk + Vector2(k * 8 + f * 3, -2), 2.5, Color(1.0, 0.5, 0.2) if state != "sleep" else Color(0.3, 0.15, 0.1))
	for i in 4:
		draw_line(sk + Vector2(-9 + i * 6, 12), sk + Vector2(-9 + i * 6, 19), dark, 2.0)
	draw_stun(-90.0)

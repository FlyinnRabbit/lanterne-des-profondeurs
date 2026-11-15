extends "res://scripts/boss_base.gd"
# L'Ombre de la Lanterne : boss final (palier 7, puis tous les 7 paliers).
# Une lanterne éteinte habitée par l'obscurité, qui flotte au-dessus de l'arène.
# Attaques : couronne de braises, balayage à hauteur de tête (s'accroupir !), pluie de cendres
# annoncée au plafond, colonnes de lumière autour du joueur.
# Phase 2 : la lanterne se brise, invoque des spectres, enchaîne les couronnes en spirale.

const WraithScript = preload("res://scripts/wraith.gd")
var hover := Vector2.ZERO
var sweep_dir := 1
var sweep_y := 0.0
var drops := []        # [x, délai] : cendres annoncées
var crack := 0.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	boss_setup(Vector2(60, 76), 72, "L'Ombre de la Lanterne")
	home.y -= 140.0
	global_position = home

func reset() -> void:
	super.reset()
	global_position = home
	drops.clear()
	crack = 0.0

func on_phase2() -> void:
	crack = 1.0
	main.flash = 0.8
	Audio.sfx("ult", 0.0, -2.0)

func telegraph() -> int:
	if state == "windup_sweep":
		return 2
	return super.telegraph()

func get_rect() -> Rect2:
	return Rect2(global_position - size / 2.0, size)

func _choose() -> void:
	face_player()
	var w := {"crown": 3, "sweep": 2.5, "ash": 2, "light": 2}
	if phase == 2:
		w["summon"] = 1.2
	match pick(w):
		"crown":
			go("windup_crown", 0.6 / rage())
		"sweep":
			go("windup_sweep", 0.75 / rage())
		"ash":
			go("windup_ash", 0.5 / rage())
		"light":
			go("windup_light", 0.6 / rage())
		"summon":
			go("windup_summon", 0.8)

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	# cendres annoncées : tombent après le délai
	for d in drops:
		d[1] -= delta
		if d[1] <= 0.0:
			main.spawn_projectile(Vector2(d[0], floor_y - 520.0), Vector2(0, 260.0), {"kind": "ember", "gravity": 500.0, "radius": 9.0, "life": 3.0})
	drops = drops.filter(func(d): return d[1] > 0.0)
	match state:
		"idle", "recover":
			hover = Vector2(pp.x + sin(anim_t * 0.7) * 160.0, floor_y - 210.0 + sin(anim_t * 1.6) * 24.0)
			hover.x = clampf(hover.x, home.x - 560.0, home.x + 200.0)
			velocity = velocity.move_toward((hover - global_position).limit_length(1.0) * 190.0 * rage(), 800.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.5 / rage())
		"windup_crown":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				var n := 10 if phase == 1 else 14
				var rings := 1 if phase == 1 else 3
				for k in rings:
					for i in n:
						var a := anim_t + i * TAU / n + k * 0.22
						main.spawn_projectile(global_position, Vector2.from_angle(a) * (190.0 - k * 30.0) * spd(), {"kind": "ember"})
				Audio.sfx("spit", 0.0, -1.0)
				go("recover", 1.0 / rage())
		"windup_sweep":
			# descend à hauteur de tête sur un côté de l'arène
			sweep_dir = 1 if pp.x < global_position.x else -1
			sweep_y = floor_y - 50.0
			var start := Vector2(pp.x - sweep_dir * 380.0, sweep_y)
			velocity = (start - global_position) * 4.0
			if state_t <= 0.0:
				global_position = start
				Audio.sfx("dash", 0.0, 2.0)
				go("sweep", 1.0)
		"sweep":
			velocity = Vector2(sweep_dir * 620.0 * rage(), 0)
			global_position.y = sweep_y
			if state_t <= 0.0:
				go("recover", 0.8 / rage())
		"windup_ash":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				var n := 5 if phase == 1 else 8
				for i in n:
					drops.append([pp.x + (i - n / 2.0) * 70.0 + randf_range(-20, 20), 0.6 + i * 0.08])
				go("recover", 1.2)
		"windup_light":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				var spots := [pp.x - 140.0, pp.x, pp.x + 140.0] if phase == 1 else [pp.x - 210.0, pp.x - 70.0, pp.x + 70.0, pp.x + 210.0]
				for i in spots.size():
					main.spawn_pillar(spots[i], floor_y, i * 0.1, {"color": Color(1.0, 0.85, 0.5)})
				go("recover", 1.0 / rage())
		"windup_summon":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_t <= 0.0:
				for i in 2:
					main.spawn_minion(WraithScript, global_position + Vector2(-90 + i * 180, 20))
				go("recover", 1.0)
	move_and_slide()

func _draw() -> void:
	var tele := telegraphing()
	var metal := body_color(Color(0.22, 0.2, 0.26))
	if tele and fmod(anim_t, 0.12) < 0.06:
		metal = Color(1, 0.95, 0.8)
	if stun_t > 0.0:
		metal = metal.darkened(0.3)
	var bob := sin(anim_t * 2.0) * 3.0
	# halo d'ombre
	draw_circle(Vector2(0, bob), 70.0, Color(0.15, 0.05, 0.25, 0.25))
	# anneau et chaîne
	draw_arc(Vector2(0, -46 + bob), 10.0, PI, TAU, 12, metal, 3.0)
	for i in 4:
		draw_arc(Vector2(0, -60 - i * 12 + bob), 4.0, 0.0, TAU, 8, Color(0.3, 0.28, 0.34), 2.0)
	# toit
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -30 + bob), Vector2(26, -30 + bob), Vector2(0, -48 + bob)]), metal)
	# cage
	var cage := Rect2(-24, -30 + bob, 48, 56)
	draw_rect(cage, Color(0.05, 0.02, 0.08, 0.9))
	# flamme d'ombre (violette, plus vive en phase 2)
	var fl := 1.0 + 0.2 * sin(anim_t * 9.0)
	var core := Color(0.6, 0.3, 1.0) if phase == 1 else Color(1.0, 0.35, 0.6)
	draw_colored_polygon(DU.ellipse(Vector2(0, -2 + bob), Vector2(12 * fl, 18 * fl)), Color(core, 0.8))
	draw_colored_polygon(DU.ellipse(Vector2(0, 2 + bob), Vector2(6, 10)), Color(1.0, 0.9, 1.0, 0.9))
	# yeux dans la flamme
	draw_circle(Vector2(-5, -4 + bob), 2.5, Color(0.05, 0.0, 0.08))
	draw_circle(Vector2(5, -4 + bob), 2.5, Color(0.05, 0.0, 0.08))
	for i in 5:
		var x := -24.0 + i * 12.0
		draw_line(Vector2(x, -30 + bob), Vector2(x, 26 + bob), metal, 3.0)
	draw_rect(Rect2(-28, 24 + bob, 56, 8), metal)
	# fissures (phase 2)
	if crack > 0.0:
		draw_line(Vector2(-18, -26 + bob), Vector2(-4, 4 + bob), Color(1.0, 0.5, 0.8), 2.0)
		draw_line(Vector2(-4, 4 + bob), Vector2(-14, 20 + bob), Color(1.0, 0.5, 0.8), 2.0)
		draw_line(Vector2(16, -24 + bob), Vector2(8, 10 + bob), Color(1.0, 0.5, 0.8), 2.0)
	# cendres annoncées : lueur au plafond
	for d in drops:
		var lp := Vector2(d[0], floor_y - 500.0) - global_position
		draw_circle(lp, 8.0 + 4.0 * sin(anim_t * 20.0), Color(1.0, 0.5, 0.2, 0.6))
	draw_stun(-70.0)

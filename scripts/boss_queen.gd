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
	var a := pick({"dive": 3, "barrage": 3, "ring": 2, "summon": 1.5})
	match a:
		"dive":
			go("windup_dive", 0.55 / rage())
		"barrage":
			shots_left = 3 if phase == 1 else 5
			go("windup_barrage", 0.45 / rage())
		"ring":
			go("windup_ring", 0.6 / rage())
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
	var flap := absf(sin(anim_t * 32.0))
	var tele := telegraphing()
	var body := Color(0.95, 0.75, 0.2) if not tele or fmod(anim_t, 0.12) > 0.06 else Color(1, 0.4, 0.3)
	if stun_t > 0.0:
		body = body.darkened(0.4)
	var dark := Color(0.12, 0.09, 0.05)
	# ailes
	for k in [-1.0, 1.0]:
		var wc := Vector2(k * 18 - f * 6, -26)
		draw_colored_polygon(DU.ellipse(wc + Vector2(k * 14, -6 * flap), Vector2(30, 10 + 12 * flap), 18), Color(0.8, 0.92, 1.0, 0.35))
	# abdomen rayé + dard
	var ab := Vector2(-f * 26, 6)
	draw_colored_polygon(DU.ellipse(ab, Vector2(30, 20)), body_color(body))
	for i in 3:
		draw_line(ab + Vector2(-f * (i * 12 - 12), -18), ab + Vector2(-f * (i * 12 - 12), 18), body_color(dark), 5.0)
	draw_colored_polygon(PackedVector2Array([ab + Vector2(-f * 26, -5), ab + Vector2(-f * 48, 4), ab + Vector2(-f * 26, 8)]), body_color(Color(0.9, 0.9, 0.85)))
	# thorax et tête
	draw_colored_polygon(DU.ellipse(Vector2(f * 8, -2), Vector2(18, 15)), body_color(dark.lightened(0.1)))
	var hd := Vector2(f * 30, -8)
	draw_colored_polygon(DU.ellipse(hd, Vector2(15, 13)), body_color(body))
	draw_circle(hd + Vector2(f * 6, -3), 5.5, Color(0.1, 0.0, 0.05))
	draw_circle(hd + Vector2(f * 7, -4), 2.5, Color(1.0, 0.3, 0.2) if not tele else Color(1, 1, 0.6))
	# couronne
	for i in 3:
		var cx := hd.x - 8 + i * 8
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 4, hd.y - 11), Vector2(cx + 4, hd.y - 11), Vector2(cx, hd.y - 22 - (i % 2) * 5)]), body_color(Color(1.0, 0.9, 0.5)))
	# pattes
	for i in 3:
		var lx := f * (2 + i * 8)
		draw_line(Vector2(lx, 10), Vector2(lx - f * 6, 24 + sin(anim_t * 8 + i) * 3), dark, 2.0)
	draw_stun(-50.0)

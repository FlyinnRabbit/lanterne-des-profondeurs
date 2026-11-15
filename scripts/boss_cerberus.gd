extends "res://scripts/boss_base.gd"
# Le Cerbère des Profondeurs (boss final possible) : chien de garde à trois têtes.
# Attaques : souffle de braises des trois têtes, bond avec onde de choc, triple morsure à hauteur
# de tête (s'accroupir !), hurlement qui fait jaillir des flammes du sol.
# Phase 2 : les têtes crachent l'une après l'autre en balayant, flammes plus nombreuses, sbires.

const CrawlerScript = preload("res://scripts/crawler.gd")
var bites := 0
var bite_t := 0.0
var breath_left := 0
var leap_target := 0.0
var head_glow := [0.0, 0.0, 0.0]

func _ready() -> void:
	boss_setup(Vector2(120, 84), 80, "Le Cerbère des Profondeurs")
	floor_snap_length = 8.0

func telegraph() -> int:
	if state == "windup_bite":
		return 2
	return super.telegraph()

# morsure : à hauteur de tête, un héros accroupi passe dessous
func bite_rect() -> Rect2:
	var fy := floor_y
	return Rect2(Vector2(global_position.x + dir * 40.0 - (90.0 if dir < 0 else 0.0), fy - 52.0), Vector2(90, 26))

func _choose() -> void:
	face_player()
	var dist: float = absf(p().global_position.x - global_position.x)
	var w := {"breath": 3, "pounce": 2.5, "howl": 1.5}
	if dist < 260.0:
		w["bite"] = 3.5
	match pick(w):
		"breath":
			breath_left = 1 if phase == 1 else 3
			go("windup_breath", 0.55 / rage())
		"pounce":
			go("windup_pounce", 0.5 / rage())
		"bite":
			bites = 3
			go("windup_bite", 0.45 / rage())
		"howl":
			go("windup_howl", 0.7 / rage())

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	velocity.y = minf(velocity.y + 1800.0 * delta, 1100.0)
	bite_t -= delta
	for i in 3:
		head_glow[i] = maxf(head_glow[i] - delta * 2.0, 0.0)
	if bite_t > 0.0 and bite_rect().intersects(pl.get_rect()) and pl.dash_t <= 0.0:
		pl.receive_hit(global_position, self)
	match state:
		"idle", "recover":
			face_player()
			var want: float = 160.0 * rage() if absf(pp.x - global_position.x) > 220.0 else 0.0
			velocity.x = move_toward(velocity.x, dir * want, 1200.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.4 / rage())
		"windup_breath":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			for i in 3:
				head_glow[i] = 1.0
			if state_t <= 0.0:
				face_player()
				# trois têtes, trois cônes de braises
				for h in 3:
					var hp2 := global_position + Vector2(dir * (50.0 + h * 6.0), -30.0 + (h - 1) * 14.0)
					var base := (pp - hp2).angle()
					for k in 3:
						var a := base + (k - 1) * 0.16 + (h - 1) * 0.12
						main.spawn_projectile(hp2, Vector2.from_angle(a) * 280.0 * spd(), {"kind": "ember"})
				Audio.sfx("spit", 0.0, 0.0)
				breath_left -= 1
				go("windup_breath" if breath_left > 0 else "recover", 0.28 if breath_left > 0 else 0.9)
		"windup_pounce":
			velocity.x = move_toward(velocity.x, 0.0, 2500.0 * delta)
			if state_t <= 0.0:
				leap_target = clampf(pp.x, home.x - 820.0, home.x + 170.0)
				velocity = Vector2((leap_target - global_position.x) * 1.6, -820.0)
				go("pounce", 1.5)
		"pounce":
			if is_on_floor() and velocity.y >= 0.0:
				main.shake(12)
				Audio.sfx("kill", 0.0, 2.0)
				for d in [-1.0, 1.0]:
					main.spawn_projectile(Vector2(global_position.x + d * 60.0, floor_y - 4.0), Vector2(d * 320.0 * spd(), 0), {"kind": "wave"})
					if phase == 2:
						main.spawn_projectile(Vector2(global_position.x + d * 60.0, floor_y - 4.0), Vector2(d * 200.0 * spd(), 0), {"kind": "wave"})
				velocity.x = 0.0
				go("recover", 0.8 / rage())
		"windup_bite":
			face_player()
			velocity.x = -dir * 30.0
			if state_t <= 0.0:
				bite_t = 0.18
				velocity.x = dir * 520.0 * rage()
				Audio.sfx("slash", 0.1, 3.0)
				bites -= 1
				go("bite", 0.25)
		"bite":
			velocity.x = move_toward(velocity.x, 0.0, 2600.0 * delta)
			if state_t <= 0.0:
				if bites > 0:
					go("windup_bite", 0.22)
				else:
					go("recover", 0.7 / rage())
		"windup_howl":
			velocity.x = 0.0
			if state_t <= 0.0:
				main.shake(8)
				Audio.sfx("ult", 0.0, -6.0)
				var n := 4 if phase == 1 else 7
				for i in n:
					var x: float = pp.x + (i - (n - 1) / 2.0) * 110.0
					main.spawn_pillar(x, floor_y, i * 0.08, {"color": Color(1.0, 0.5, 0.2), "style": "fire", "height": 120.0})
				if phase == 2:
					for k in 2:
						main.spawn_minion(CrawlerScript, global_position + Vector2(-80 + k * 160, 10))
				go("recover", 1.1 / rage())
	move_and_slide()

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var fur := body_color(Color(0.22, 0.16, 0.18))
	if tele and fmod(anim_t, 0.12) < 0.06:
		fur = Color(1.0, 0.85, 0.7)
	if stun_t > 0.0:
		fur = fur.darkened(0.3)
	var run := sin(anim_t * 10.0) * (4.0 if absf(velocity.x) > 20.0 else 0.0)
	# pattes
	for k in [-1.0, 1.0]:
		draw_line(Vector2(k * 34, 14), Vector2(k * 38 + run * k, 42), fur, 9.0)
		draw_line(Vector2(k * 18, 14), Vector2(k * 16 - run * k, 42), fur, 9.0)
	# corps et queue de flammes
	draw_colored_polygon(DU.ellipse(Vector2(-f * 4, 0), Vector2(56, 26)), fur)
	for i in 4:
		var tp := Vector2(-f * (56 + i * 8), -10 - i * 6 + sin(anim_t * 8.0 + i) * 4.0)
		draw_circle(tp, 7.0 - i, Color(1.0, 0.5 + 0.1 * i, 0.2, 0.8))
	# trois têtes
	for h in 3:
		var hc := Vector2(f * (46 + h * 6), -30 + (h - 1) * 16 + sin(anim_t * 3.0 + h) * 2.0)
		if state == "bite" or bite_t > 0.0:
			hc.x += f * 16.0
		draw_line(Vector2(f * 30, -10), hc, fur, 12.0)
		draw_colored_polygon(DU.ellipse(hc, Vector2(18, 13)), fur)
		draw_colored_polygon(PackedVector2Array([hc + Vector2(f * 10, -2), hc + Vector2(f * 28, 2), hc + Vector2(f * 10, 8)]), fur.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([hc + Vector2(-f * 6, -10), hc + Vector2(-f * 2, -24), hc + Vector2(f * 4, -10)]), fur)
		var ec := Color(1.0, 0.45, 0.15).lerp(Color(1.0, 0.95, 0.6), head_glow[h])
		draw_circle(hc + Vector2(f * 6, -3), 3.0, ec)
		if head_glow[h] > 0.0:
			draw_circle(hc + Vector2(f * 26, 3), 6.0 * head_glow[h], Color(1.0, 0.6, 0.2, 0.6))
	# collier à pointes
	for i in 5:
		var cp := Vector2(f * (22 + i * 3), -14 + i * 4)
		draw_colored_polygon(PackedVector2Array([cp + Vector2(-3, 0), cp + Vector2(3, 0), cp + Vector2(0, -7)]), Color(0.75, 0.7, 0.6))
	if bite_t > 0.0:
		var r := bite_rect()
		draw_rect(Rect2(r.position - global_position, r.size), Color(1.0, 0.85, 0.7, 0.35))
	draw_stun(-64.0)

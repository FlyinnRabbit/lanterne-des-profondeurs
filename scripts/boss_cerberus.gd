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
			go("windup_breath", tele(0.55))
		"pounce":
			go("windup_pounce", tele(0.5))
		"bite":
			bites = 3
			go("windup_bite", tele(0.45))
		"howl":
			go("windup_howl", tele(0.7))

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
	var fur := body_color(Color(0.24, 0.16, 0.18))
	if tele and fmod(anim_t, 0.12) < 0.06:
		fur = Color(1.0, 0.85, 0.7)
	if stun_t > 0.0:
		fur = fur.darkened(0.3)
	var belly := fur.lerp(Color(0.45, 0.3, 0.25), 0.4)
	var moving := absf(velocity.x) > 20.0
	var run := sin(anim_t * 10.0) * (4.0 if moving else 0.0)
	var ember := Color(1.0, 0.5, 0.15)
	DU.glow(self, Vector2(-f * 10, 0), 90.0, ember, 0.15)
	# pattes du fond (plus sombres), puis corps, puis pattes de devant
	for k in [-1.0, 1.0]:
		_paw(Vector2(k * 30 + f * 4, 10), -run * k, fur.darkened(0.4), f)
	# queue de flammes
	for i in 6:
		var tp := Vector2(-f * (54 + i * 7), -8 - i * 6 + sin(anim_t * 8.0 + i) * 4.0)
		draw_circle(tp, 9.0 - i, Color(1.0, 0.35 + 0.1 * i, 0.15, 0.5))
		draw_circle(tp, 5.0 - i * 0.6, Color(1.0, 0.8, 0.4, 0.8))
	# corps musclé : dos, ventre clair, côtes, crinière de pointes
	var body := DU.ellipse(Vector2(-f * 4, 0), Vector2(56, 26), 32)
	DU.poly(self, body, fur)
	DU.poly(self, DU.ellipse(Vector2(-f * 2, 12), Vector2(40, 10), 20, 0.0, PI), belly, false)
	for k in 4:
		draw_arc(Vector2(-f * (8 + k * 9), 2), 14.0, PI * 0.3, PI * 0.7, 6, fur.darkened(0.4), 1.4)
	for k in 9:
		var mx := -f * (40 - k * 8)
		var spike := PackedVector2Array([Vector2(mx - 5, -20 + absf(k - 4) * 0.8), Vector2(mx + 5, -21 + absf(k - 4) * 0.8), Vector2(mx - f * 4, -32 + absf(k - 4) * 1.2 + sin(anim_t * 6.0 + k))])
		DU.poly(self, spike, fur.darkened(0.25), false)
	# braises sur le dos
	for k in 3:
		var t := fposmod(anim_t * 0.7 + k * 0.33, 1.0)
		draw_circle(Vector2(-f * (10 + k * 14), -24 - t * 30.0), 1.8 * (1.0 - t), Color(1.0, 0.6, 0.2, 1.0 - t))
	for k in [-1.0, 1.0]:
		_paw(Vector2(k * 26 - f * 4, 12), run * k, fur, f)
	# collier à pointes
	draw_line(Vector2(f * 22, -18), Vector2(f * 30, 6), Color(0.3, 0.22, 0.18), 6.0)
	for i in 5:
		var cp := Vector2(f * (22 + i * 2), -16 + i * 5)
		DU.poly(self, PackedVector2Array([cp + Vector2(-3, 0), cp + Vector2(3, 0), cp + Vector2(f * 6, -4)]), Color(0.78, 0.72, 0.6))
	# trois têtes de loup
	for h in [0, 2, 1]:
		var hc := Vector2(f * (46 + h * 6), -30 + (h - 1) * 16 + sin(anim_t * 3.0 + h) * 2.0)
		if state == "bite" or bite_t > 0.0:
			hc.x += f * 16.0
		var hf := fur.darkened(0.15 if h != 1 else 0.0)
		draw_line(Vector2(f * 26, -8), hc, hf.darkened(0.3), 15.0)
		draw_line(Vector2(f * 26, -8), hc, hf, 11.0)
		_head(hc, f, hf, head_glow[h], tele)
	if bite_t > 0.0:
		var r := bite_rect()
		draw_rect(Rect2(r.position - global_position, r.size), Color(1.0, 0.85, 0.7, 0.35))
	draw_stun(-64.0)

func _paw(top: Vector2, sw: float, c: Color, f: float) -> void:
	var knee := top + Vector2(f * 6 + sw * 0.4, 16)
	var foot := top + Vector2(sw, 32)
	draw_line(top, knee, c, 11.0)
	draw_line(knee, foot, c, 8.0)
	DU.poly(self, DU.ellipse(foot + Vector2(f * 3, 0), Vector2(8, 4), 12), c.darkened(0.1))
	for k in 3:
		draw_line(foot + Vector2(f * (6 + k * 1.5), -1 + k * 1.5), foot + Vector2(f * (10 + k * 1.5), 1 + k * 1.5), Color(0.85, 0.8, 0.7), 1.4)

func _head(hc: Vector2, f: float, c: Color, glow: float, tele: bool) -> void:
	var open := 0.0
	if state == "bite" or bite_t > 0.0 or glow > 0.0:
		open = 5.0
	# crâne et oreilles
	DU.poly(self, PackedVector2Array([hc + Vector2(-f * 6, -10), hc + Vector2(-f * 1, -25), hc + Vector2(f * 4, -11)]), c)
	draw_line(hc + Vector2(-f * 2, -12), hc + Vector2(-f * 1, -21), c.lightened(0.15), 1.2)
	DU.poly(self, DU.ellipse(hc, Vector2(17, 12.5), 22), c)
	# museau et mâchoires
	DU.poly(self, PackedVector2Array([hc + Vector2(f * 8, -7), hc + Vector2(f * 27, -2), hc + Vector2(f * 28, 2), hc + Vector2(f * 10, 3)]), c.darkened(0.08))
	DU.poly(self, PackedVector2Array([hc + Vector2(f * 8, 4), hc + Vector2(f * 25, 4 + open), hc + Vector2(f * 22, 8 + open), hc + Vector2(f * 6, 9)]), c.darkened(0.25))
	draw_circle(hc + Vector2(f * 27, -1.5), 2.2, Color(0.05, 0.03, 0.03))
	if open > 0.0:
		DU.flat(self, PackedVector2Array([hc + Vector2(f * 10, 3), hc + Vector2(f * 26, 2), hc + Vector2(f * 24, 4 + open)]), Color(0.45, 0.05, 0.05))
	for k in 4:
		var tx := hc + Vector2(f * (12 + k * 3.5), 2.5)
		DU.flat(self, PackedVector2Array([tx, tx + Vector2(f * 2, 0), tx + Vector2(f * 1, 3)]), Color(0.95, 0.92, 0.82))
	# œil brûlant
	var ec := Color(1.0, 0.45, 0.15).lerp(Color(1.0, 0.95, 0.6), glow)
	DU.flat(self, DU.ellipse(hc + Vector2(f * 6, -4), Vector2(3.6, 2.4)), Color(0.05, 0.02, 0.02))
	draw_circle(hc + Vector2(f * 6.5, -4), 1.8, ec)
	DU.glow(self, hc + Vector2(f * 6, -4), 10.0, ec, 0.5)
	draw_line(hc + Vector2(f * 1, -8), hc + Vector2(f * 9, -6.5), c.darkened(0.5), 1.6)
	if glow > 0.0:
		DU.glow(self, hc + Vector2(f * 28, 3), 24.0 * glow, Color(1.0, 0.6, 0.2), 0.7)
		draw_circle(hc + Vector2(f * 26, 3), 5.0 * glow, Color(1.0, 0.85, 0.4, 0.8))

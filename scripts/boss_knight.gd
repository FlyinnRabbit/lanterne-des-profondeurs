extends "res://scripts/boss_base.gd"
# Le Chevalier Spectral : duelliste rapide en armure fantôme.
# Attaques : estoc fulgurant (ruée + entaille), téléportation dans le dos suivie d'une entaille,
# piliers spectraux qui jaillissent en ligne vers le joueur, salve de braises.
# Phase 2 : combos de deux estocs, piliers des deux côtés, téléportations plus rapides.
# (rééquilibré : préparations plus longues, ruée moins rapide, plus de temps pour riposter)

var combo := 0
var fade := 1.0
var slash_t := 0.0
var ghosts: Array = []    # images rémanentes [position, âge]

func _ready() -> void:
	boss_setup(Vector2(40, 72), 46, "Le Chevalier Spectral")
	floor_snap_length = 6.0

func get_rect() -> Rect2:
	var r := Rect2(global_position - size / 2.0, size)
	if slash_t > 0.0:
		r = r.merge(Rect2(global_position + Vector2(dir * 20.0 - (70.0 if dir < 0 else 0.0), -30), Vector2(70, 50)))
	return r

func is_harmful() -> bool:
	return super.is_harmful() and fade > 0.5

func _choose() -> void:
	face_player()
	match pick({"thrust": 3, "blink": 1.8, "pillars": 2, "embers": 1.5, "stalk": 1}):
		"thrust":
			combo = 1 if phase == 1 else 2
			go("windup_thrust", tele(0.5))
		"blink":
			go("fade_out", 0.3 / sqrt(rage()))
		"pillars":
			go("windup_pillars", tele(0.55))
		"embers":
			go("windup_embers", tele(0.45))
		"stalk":
			go("stalk", 0.8)

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	velocity.y = minf(velocity.y + 1800.0 * delta, 1000.0)
	slash_t -= delta
	for g in ghosts:
		g[1] += delta
	ghosts = ghosts.filter(func(g): return g[1] < 0.35)
	match state:
		"idle", "recover":
			velocity.x = move_toward(velocity.x, 0.0, 2200.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.35 / rage())
		"stalk":
			face_player()
			velocity.x = dir * 150.0 * rage()
			if state_t <= 0.0:
				go("idle", 0.1)
		"windup_thrust":
			face_player()
			velocity.x = -dir * 40.0
			if state_t <= 0.0:
				slash_t = 0.3
				Audio.sfx("dash", 0.1)
				go("thrust", 0.28)
		"thrust":
			velocity.x = dir * 640.0 * rage()
			if int(anim_t * 60) % 3 == 0:
				ghosts.append([global_position, 0.0])
			if state_t <= 0.0 or is_on_wall():
				combo -= 1
				if combo > 0:
					go("windup_thrust", tele(0.35))
				else:
					go("recover", 1.0 / rage())
		"fade_out":
			velocity.x = 0.0
			fade = clampf(state_t / 0.3, 0.0, 1.0)
			if state_t <= 0.0:
				# réapparaît dans le dos du joueur
				var behind: float = clampf(pp.x - float(pl.facing) * 110.0, home.x - 820.0, home.x + 150.0)
				ghosts.append([global_position, 0.0])
				global_position = Vector2(behind, floor_y - size.y / 2.0 - 2.0)
				face_player()
				Audio.sfx("dash", 0.2, -4.0)     # on l'entend revenir dans le dos
				go("fade_in", 0.3)
		"fade_in":
			fade = 1.0 - clampf(state_t / 0.3, 0.0, 1.0)
			if state_t <= 0.0:
				fade = 1.0
				combo = 1
				go("windup_thrust", tele(0.45))
		"windup_pillars":
			velocity.x = 0.0
			if state_t <= 0.0:
				var dirs := [dir] if phase == 1 else [-1, 1]
				for d in dirs:
					for i in 6:
						main.spawn_pillar(global_position.x + d * (70.0 + i * 70.0), floor_y, i * 0.12, {"color": Color(0.55, 0.85, 1.0)})
				go("recover", 1.1 / rage())
		"windup_embers":
			velocity.x = 0.0
			if state_t <= 0.0:
				var n := 5 if phase == 1 else 6
				for i in n:
					var a := (pp - global_position).angle() + (i - (n - 1) / 2.0) * 0.16
					main.spawn_projectile(global_position + Vector2(dir * 20, -20), Vector2.from_angle(a) * 300.0 * spd(), {"kind": "ember"})
				go("recover", 0.8)
	move_and_slide()

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var armor := Color(0.5, 0.6, 0.78)
	if tele and fmod(anim_t, 0.12) < 0.06:
		armor = Color(0.95, 0.97, 1.0)
	if stun_t > 0.0:
		armor = armor.darkened(0.35)
	armor = body_color(armor)
	armor.a = fade
	var spirit := Color(0.6, 0.95, 1.0, fade)
	var iron := Color(armor.darkened(0.45), fade)
	for g in ghosts:
		var gp: Vector2 = g[0] - global_position
		var ga: float = 0.3 * (1.0 - float(g[1]) / 0.35)
		DU.flat(self, DU.ellipse(gp + Vector2(0, -6), Vector2(16, 26)), Color(0.5, 0.75, 1.0, ga))
		DU.flat(self, DU.ellipse(gp + Vector2(0, -34), Vector2(11, 12)), Color(0.5, 0.75, 1.0, ga))
	DU.glow(self, Vector2(0, -10), 60.0, Color(0.5, 0.8, 1.0), 0.3 * fade)
	# cape en lambeaux, translucide
	var sway := sin(anim_t * 3.0) * 4.0
	var cape := PackedVector2Array([Vector2(-14, -26), Vector2(14, -26)])
	for k in 7:
		var t := k / 6.0
		cape.append(Vector2(lerpf(18.0, -18.0, t) - f * sway * (0.5 + t * 0.5), 34 + (6.0 if k % 2 == 0 else -4.0) + sin(anim_t * 4.0 + k) * 2.0))
	DU.flat(self, cape, Color(0.15, 0.22, 0.4, 0.75 * fade))
	draw_polyline(cape, Color(0.5, 0.75, 1.0, 0.4 * fade), 1.2)
	# jambières et solerets
	for k in [-1.0, 1.0]:
		var top := Vector2(k * 9, 12)
		draw_line(top, Vector2(k * 10, 32), iron, 8.0)
		draw_line(top, Vector2(k * 10, 32), armor, 5.0)
		DU.ball(self, Vector2(k * 9.5, 22), 4.0, armor)
		draw_line(Vector2(k * 10 - 3, 34), Vector2(k * 10 + f * 7, 34), iron, 4.0)
	# tassettes
	for k in 3:
		var tx := -12.0 + k * 8.0
		var tas := PackedVector2Array([Vector2(tx, 6), Vector2(tx + 8, 6), Vector2(tx + 7, 16), Vector2(tx + 1, 16)])
		_plate(tas, armor.darkened(0.1))
	# cuirasse : plastron bombé, arête, sigil lumineux
	var chest := PackedVector2Array([Vector2(-15, -24), Vector2(15, -24), Vector2(17, -10), Vector2(11, 8), Vector2(-11, 8), Vector2(-17, -10)])
	_plate(chest, armor)
	draw_line(Vector2(f * 1, -22), Vector2(f * 1, 6), Color(DU.lit(armor, 1.4, 0.1), fade), 1.4)
	DU.flat(self, DU.diamond(Vector2(f * 1, -10), Vector2(4, 6)), spirit)
	DU.glow(self, Vector2(f * 1, -10), 12.0, spirit, 0.5 * fade)
	draw_line(Vector2(-12, 4), Vector2(12, 4), iron, 3.0)
	# épaulières
	for k in [-1.0, 1.0]:
		var ep := Vector2(k * 17, -22)
		var pa := DU.ellipse(ep, Vector2(9, 6), 16, PI, TAU)
		pa.append(ep + Vector2(k * 8, 4))
		pa.append(ep + Vector2(-k * 8, 4))
		_plate(pa, armor.lightened(0.05))
	# heaume : visière en T lumineuse, panache spectral
	var hm := Vector2(f * 2, -36)
	var helm := PackedVector2Array([hm + Vector2(-12, 10), hm + Vector2(-13, -4), hm + Vector2(-8, -13), hm + Vector2(0, -15), hm + Vector2(8, -13), hm + Vector2(13, -4), hm + Vector2(12, 10), hm + Vector2(0, 13)])
	_plate(helm, armor.lightened(0.08))
	draw_line(hm + Vector2(0, -15), hm + Vector2(0, 12), Color(DU.lit(armor, 1.4, 0.1), fade), 1.2)
	draw_line(hm + Vector2(-9, -2), hm + Vector2(9, -2), Color(0.02, 0.03, 0.06, fade), 4.0)
	draw_line(hm + Vector2(f * 1, -2), hm + Vector2(f * 1, 8), Color(0.02, 0.03, 0.06, fade), 4.0)
	draw_line(hm + Vector2(-8, -2), hm + Vector2(8, -2), spirit, 2.0)
	draw_line(hm + Vector2(f * 1, -2), hm + Vector2(f * 1, 7), spirit, 2.0)
	DU.glow(self, hm + Vector2(0, -2), 16.0, spirit, 0.5 * fade)
	var plume := PackedVector2Array()
	for k in 8:
		var t := k / 7.0
		plume.append(hm + Vector2(-f * t * 22.0, -14.0 - sin(t * PI) * 8.0 + t * 6.0 + sin(anim_t * 4.0 + t * 3.0) * 2.0 * t))
	draw_polyline(plume, Color(0.55, 0.85, 1.0, 0.75 * fade), 4.0)
	draw_polyline(plume, Color(0.85, 0.97, 1.0, 0.6 * fade), 1.5)
	# épée longue (levée pendant l'annonce) : lame lumineuse, garde, pommeau
	var hand := Vector2(f * 16, -4)
	var tip := hand + (Vector2(f * 10, -52) if tele else Vector2(f * 54, 6))
	if slash_t > 0.0:
		tip = hand + Vector2(f * 70, -4)
		draw_arc(hand, 60.0, (-0.9 if f > 0 else PI - 0.9), (0.9 if f > 0 else PI + 0.9), 16, Color(0.7, 0.95, 1.0, 0.7), 6.0)
	var d := (tip - hand).normalized()
	var nrm := d.orthogonal()
	var blade := PackedVector2Array([hand + d * 6.0 + nrm * 3.0, tip - d * 6.0 + nrm * 2.4, tip, tip - d * 6.0 - nrm * 2.4, hand + d * 6.0 - nrm * 3.0])
	DU.flat(self, blade, Color(0.82, 0.93, 1.0, fade))
	draw_line(hand + d * 6.0, tip - d * 4.0, Color(1, 1, 1, 0.8 * fade), 1.0)
	DU.glow(self, hand.lerp(tip, 0.6), 26.0, Color(0.6, 0.9, 1.0), 0.35 * fade)
	draw_line(hand + d * 5.0 + nrm * 9.0, hand + d * 5.0 - nrm * 9.0, Color(0.55, 0.5, 0.65, fade), 4.0)
	draw_line(hand - d * 4.0, hand + d * 4.0, Color(0.3, 0.25, 0.35, fade), 4.0)
	draw_circle(hand - d * 6.0, 3.0, spirit)
	DU.ball(self, hand, 4.5, armor)
	draw_stun(-62.0)

func _plate(pts: PackedVector2Array, c: Color) -> void:
	if c.a > 0.95:
		DU.poly(self, pts, c)
	else:
		DU.flat(self, pts, c)
		draw_polyline(pts, Color(0.75, 0.9, 1.0, c.a * 0.6), 1.0)

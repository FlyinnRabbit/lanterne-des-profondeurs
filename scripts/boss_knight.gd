extends "res://scripts/boss_base.gd"
# Le Chevalier Spectral : duelliste rapide en armure fantôme.
# Attaques : estoc fulgurant (ruée + entaille), téléportation dans le dos suivie d'une entaille,
# piliers spectraux qui jaillissent en ligne vers le joueur, salve de braises.
# Phase 2 : combos de trois estocs, piliers des deux côtés, téléportations plus rapides.

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
	match pick({"thrust": 3, "blink": 2.5, "pillars": 2, "embers": 1.5, "stalk": 1}):
		"thrust":
			combo = 1 if phase == 1 else 3
			go("windup_thrust", 0.4 / rage())
		"blink":
			go("fade_out", 0.3 / sqrt(rage()))
		"pillars":
			go("windup_pillars", 0.55 / rage())
		"embers":
			go("windup_embers", 0.45 / rage())
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
			velocity.x = dir * 760.0 * rage()
			if int(anim_t * 60) % 3 == 0:
				ghosts.append([global_position, 0.0])
			if state_t <= 0.0 or is_on_wall():
				combo -= 1
				if combo > 0:
					go("windup_thrust", 0.22)
				else:
					go("recover", 0.7 / rage())
		"fade_out":
			velocity.x = 0.0
			fade = clampf(state_t / 0.3, 0.0, 1.0)
			if state_t <= 0.0:
				# réapparaît dans le dos du joueur
				var behind: float = clampf(pp.x - float(pl.facing) * 110.0, home.x - 820.0, home.x + 150.0)
				ghosts.append([global_position, 0.0])
				global_position = Vector2(behind, floor_y - size.y / 2.0 - 2.0)
				face_player()
				go("fade_in", 0.25)
		"fade_in":
			fade = 1.0 - clampf(state_t / 0.25, 0.0, 1.0)
			if state_t <= 0.0:
				fade = 1.0
				combo = 1
				go("windup_thrust", 0.3 / rage())
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
				var n := 5 if phase == 1 else 7
				for i in n:
					var a := (pp - global_position).angle() + (i - (n - 1) / 2.0) * 0.16
					main.spawn_projectile(global_position + Vector2(dir * 20, -20), Vector2.from_angle(a) * 300.0 * spd(), {"kind": "ember"})
				go("recover", 0.8)
	move_and_slide()

func _draw() -> void:
	var f := float(dir)
	var tele := telegraphing()
	var armor := Color(0.55, 0.65, 0.85, 0.85 * fade)
	if tele and fmod(anim_t, 0.12) < 0.06:
		armor = Color(1.0, 1.0, 1.0, fade)
	if stun_t > 0.0:
		armor = armor.darkened(0.35)
	for g in ghosts:
		var gp: Vector2 = g[0] - global_position
		draw_colored_polygon(DU.ellipse(gp, Vector2(18, 34)), Color(0.5, 0.75, 1.0, 0.3 * (1.0 - g[1] / 0.35)))
	# cape fantomatique
	var sway := sin(anim_t * 3.0) * 4.0
	draw_colored_polygon(PackedVector2Array([Vector2(-14, -24), Vector2(14, -24), Vector2(18 - f * sway, 36), Vector2(0, 30), Vector2(-18 - f * sway, 36)]), Color(0.2, 0.3, 0.5, 0.6 * fade))
	# armure
	draw_colored_polygon(DU.ellipse(Vector2(0, -6), Vector2(16, 22)), body_color(armor))
	draw_line(Vector2(-10, 14), Vector2(-10, 34), body_color(armor), 6.0)
	draw_line(Vector2(10, 14), Vector2(10, 34), body_color(armor), 6.0)
	# heaume à visière en T lumineuse
	var hm := Vector2(f * 2, -34)
	draw_colored_polygon(DU.ellipse(hm, Vector2(13, 14)), body_color(armor.lightened(0.1)))
	draw_line(hm + Vector2(-8, -2), hm + Vector2(8, -2), Color(0.6, 0.95, 1.0, fade), 3.0)
	draw_line(hm + Vector2(f * 1, -2), hm + Vector2(f * 1, 8), Color(0.6, 0.95, 1.0, fade), 3.0)
	draw_line(hm + Vector2(0, -14), hm + Vector2(-f * 10, -26 + sway), Color(0.7, 0.85, 1.0, 0.7 * fade), 3.0)   # panache
	# épée longue (levée pendant l'annonce)
	var hand := Vector2(f * 16, -4)
	var tip := hand + (Vector2(f * 10, -52) if tele else Vector2(f * 54, 6))
	if slash_t > 0.0:
		tip = hand + Vector2(f * 70, -4)
		draw_arc(hand, 60.0, (-0.9 if f > 0 else PI - 0.9), (0.9 if f > 0 else PI + 0.9), 16, Color(0.7, 0.95, 1.0, 0.7), 6.0)
	draw_line(hand, tip, Color(0.85, 0.95, 1.0, fade), 4.0)
	draw_line(hand + Vector2(0, -8), hand + Vector2(0, 8), Color(0.5, 0.55, 0.7, fade), 4.0)
	draw_stun(-58.0)

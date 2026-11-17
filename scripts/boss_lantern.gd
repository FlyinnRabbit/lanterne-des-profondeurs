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
			go("windup_crown", tele(0.6))
		"sweep":
			go("windup_sweep", tele(0.75))
		"ash":
			go("windup_ash", tele(0.5))
		"light":
			go("windup_light", tele(0.6))
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
	var metal := body_color(Color(0.24, 0.21, 0.28))
	if tele and fmod(anim_t, 0.12) < 0.06:
		metal = Color(1, 0.95, 0.8)
	if stun_t > 0.0:
		metal = metal.darkened(0.3)
	var brass := body_color(Color(0.55, 0.42, 0.22))
	var bob := sin(anim_t * 2.0) * 3.0
	var core := Color(0.6, 0.3, 1.0) if phase == 1 else Color(1.0, 0.35, 0.6)
	# halo d'ombre et volutes de fumée
	DU.glow(self, Vector2(0, bob), 110.0, Color(0.25, 0.08, 0.4), 0.55)
	DU.glow(self, Vector2(0, -2 + bob), 50.0, core, 0.35)
	for k in 5:
		var t := fposmod(anim_t * 0.35 + k * 0.2, 1.0)
		var sp := Vector2(sin(anim_t + k * 1.7) * 30.0, 30.0 - t * 110.0 + bob)
		draw_circle(sp, 8.0 + t * 10.0, Color(0.12, 0.04, 0.2, 0.25 * (1.0 - t)))
	# chaîne qui monte hors de l'écran
	for i in 6:
		var cy := -60.0 - i * 11.0 + bob
		if i % 2 == 0:
			draw_arc(Vector2(0, cy), 4.5, 0.0, TAU, 10, metal.darkened(0.3), 3.0)
			draw_arc(Vector2(0, cy), 4.5, PI * 1.1, PI * 1.6, 5, DU.lit(metal, 1.8, 0.1), 1.0)
		else:
			draw_line(Vector2(0, cy - 5), Vector2(0, cy + 5), metal.darkened(0.3), 3.0)
	draw_arc(Vector2(0, -50 + bob), 10.0, PI, TAU, 14, brass, 3.5)
	# toit à pans, fleuron
	var roof := PackedVector2Array([Vector2(-30, -30 + bob), Vector2(-20, -40 + bob), Vector2(0, -50 + bob), Vector2(20, -40 + bob), Vector2(30, -30 + bob)])
	DU.poly(self, roof, metal)
	for k in 4:
		draw_line(Vector2(-22 + k * 14.5, -31 + bob), Vector2(0, -48 + bob), metal.darkened(0.45), 1.0)
	draw_rect(Rect2(-31, -32 + bob, 62, 4), brass)
	# verre fumé de la cage
	var cage := Rect2(-24, -28 + bob, 48, 52)
	draw_rect(cage, Color(0.04, 0.01, 0.07, 0.92))
	DU.vgrad(self, cage, Color(core, 0.1), Color(core, 0.25))
	# flamme d'ombre (violette, plus vive en phase 2) : couches et langues
	var fl := 1.0 + 0.2 * sin(anim_t * 9.0)
	for layer in 3:
		var sc := 1.0 - layer * 0.3
		var pts := PackedVector2Array()
		for k in 16:
			var a := k * TAU / 16.0
			var tongue := 1.0 + (0.5 + 0.3 * sin(anim_t * 11.0 + k)) * maxf(0.0, -sin(a))
			pts.append(Vector2(cos(a) * 12.0 * fl * sc, -2 + sin(a) * 15.0 * fl * sc * tongue) + Vector2(0, bob + 4))
		var col := core.lerp(Color(1, 0.92, 1), layer * 0.45)
		col.a = 0.75 + layer * 0.08
		DU.flat(self, pts, col)
	# yeux et sourire dans la flamme
	for ex in [-5.0, 5.0]:
		DU.flat(self, DU.ellipse(Vector2(ex, -2 + bob), Vector2(2.4, 3.2 if not tele else 1.4)), Color(0.05, 0.0, 0.08))
	draw_arc(Vector2(0, 4 + bob), 5.0, 0.3, PI - 0.3, 8, Color(0.05, 0.0, 0.08), 1.4)
	# barreaux ouvragés
	for i in 5:
		var x := -24.0 + i * 12.0
		draw_line(Vector2(x, -28 + bob), Vector2(x, 24 + bob), metal.darkened(0.4), 4.0)
		draw_line(Vector2(x - 0.8, -28 + bob), Vector2(x - 0.8, 24 + bob), DU.lit(metal, 1.6, 0.06), 1.2)
	draw_line(Vector2(-24, -2 + bob), Vector2(24, -2 + bob), metal.darkened(0.3), 2.0)
	# socle à griffes
	DU.poly(self, PackedVector2Array([Vector2(-30, 24 + bob), Vector2(30, 24 + bob), Vector2(26, 32 + bob), Vector2(-26, 32 + bob)]), brass)
	for k in [-1.0, 1.0]:
		DU.poly(self, PackedVector2Array([Vector2(k * 22, 32 + bob), Vector2(k * 30, 32 + bob), Vector2(k * 34, 42 + bob)]), metal)
	# fissures (phase 2)
	if crack > 0.0:
		var cc := Color(1.0, 0.5, 0.8)
		draw_polyline(PackedVector2Array([Vector2(-18, -26 + bob), Vector2(-4, 4 + bob), Vector2(-14, 20 + bob)]), cc, 2.0)
		draw_polyline(PackedVector2Array([Vector2(16, -24 + bob), Vector2(8, 10 + bob), Vector2(14, 18 + bob)]), cc, 2.0)
		DU.glow(self, Vector2(-4, 4 + bob), 20.0, cc, 0.4)
	# cendres annoncées : lueur au plafond
	for d in drops:
		var lp := Vector2(d[0], floor_y - 500.0) - global_position
		DU.glow(self, lp, 18.0, Color(1.0, 0.5, 0.2), 0.7)
		draw_circle(lp, 5.0 + 3.0 * sin(anim_t * 20.0), Color(1.0, 0.6, 0.25, 0.8))
	draw_stun(-70.0)

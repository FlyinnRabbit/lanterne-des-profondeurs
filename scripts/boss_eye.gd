extends "res://scripts/boss_base.gd"
# L'Œil d'en Dessous (boss final possible) : un œil immense entouré de tentacules, venu d'avant la
# Lanterne. Il flotte au-dessus de l'arène.
# Attaques : tentacules qui jaillissent du sol sous le joueur, rayon qui balaie l'arène à hauteur
# de tête (s'accroupir !) ou au ras du sol (sauter !), regard en spirale de spores.
# Phase 2 : l'œil s'ouvre en grand, invoque des yeux volants, rayons doubles.

const FlyerScript = preload("res://scripts/flyer.gd")
var beam_t := 0.0
var beam_y := 0.0
var beam_high := true
var beams_left := 0
var look := Vector2.ZERO
var lid := 0.6

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	boss_setup(Vector2(96, 96), 84, "L'Œil d'en Dessous")
	home.y -= 150.0
	global_position = home

func reset() -> void:
	super.reset()
	global_position = home
	beam_t = 0.0

func on_phase2() -> void:
	main.flash = 0.6
	Audio.sfx("ult", 0.0, -4.0)

func telegraph() -> int:
	if state == "windup_beam":
		return 2 if beam_high else 1
	return super.telegraph()

func beam_rect() -> Rect2:
	return Rect2(Vector2(home.x - 900.0, beam_y - 9.0), Vector2(1150.0, 18.0))

func _choose() -> void:
	var w := {"tentacles": 3, "beam": 2.5, "gaze": 2}
	if phase == 2:
		w["spawn"] = 1.2
	match pick(w):
		"tentacles":
			go("windup_tentacles", 0.5 / rage())
		"beam":
			beams_left = 1 if phase == 1 else 2
			beam_high = randf() < 0.6
			go("windup_beam", 0.9 / rage())
		"gaze":
			go("windup_gaze", 0.6 / rage())
		"spawn":
			go("windup_spawn", 0.8)

func _tick(delta: float) -> void:
	var pl = p()
	var pp: Vector2 = pl.global_position
	look = look.lerp((pp - global_position).limit_length(14.0), minf(delta * 6.0, 1.0))
	lid = move_toward(lid, 1.0 if (phase == 2 or state.begins_with("windup")) else 0.6, delta * 2.0)
	beam_t -= delta
	if beam_t > 0.0 and beam_rect().intersects(pl.get_rect()) and pl.dash_t <= 0.0:
		pl.receive_hit(Vector2(global_position.x, beam_y), self)
	match state:
		"idle", "recover":
			var hover := Vector2(clampf(pp.x, home.x - 700.0, home.x + 100.0) + sin(anim_t * 0.6) * 120.0, floor_y - 260.0 + sin(anim_t * 1.3) * 26.0)
			velocity = velocity.move_toward((hover - global_position).limit_length(1.0) * 150.0 * rage(), 600.0 * delta)
			if state == "recover" and state_t <= 0.0:
				go("idle", 0.5 / rage())
		"windup_tentacles":
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			if state_t <= 0.0:
				var n := 3 if phase == 1 else 5
				for i in n:
					var x: float = pp.x + (i - (n - 1) / 2.0) * 95.0
					main.spawn_pillar(x, floor_y, i * 0.1, {"color": Color(0.6, 0.3, 0.7), "style": "tentacle", "height": 190.0, "width": 40.0})
				go("recover", 1.1 / rage())
		"windup_beam":
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			beam_y = floor_y - (48.0 if beam_high else 10.0)
			if state_t <= 0.0:
				beam_t = 0.6
				main.shake(6)
				Audio.sfx("ult", 0.1, -6.0)
				beams_left -= 1
				go("beam", 0.6)
		"beam":
			velocity = Vector2.ZERO
			if state_t <= 0.0:
				if beams_left > 0:
					beam_high = not beam_high
					go("windup_beam", 0.5)
				else:
					go("recover", 0.9 / rage())
		"windup_gaze":
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			if state_t <= 0.0:
				var n := 12 if phase == 1 else 18
				for i in n:
					var a := anim_t * 2.0 + i * TAU / n
					main.spawn_projectile(global_position, Vector2.from_angle(a) * (170.0 + 30.0 * (i % 2)) * spd(), {"kind": "spore", "radius": 8.0})
				Audio.sfx("spit", 0.0, -2.0)
				go("recover", 1.0 / rage())
		"windup_spawn":
			velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
			if state_t <= 0.0:
				for k in 2:
					main.spawn_minion(FlyerScript, global_position + Vector2(-80 + k * 160, 40))
				go("recover", 1.0)
	move_and_slide()

func _draw() -> void:
	var tele := telegraphing()
	var flesh := body_color(Color(0.32, 0.17, 0.3))
	if stun_t > 0.0:
		flesh = flesh.darkened(0.3)
	var iris := Color(0.9, 0.35, 0.6) if phase == 1 else Color(1.0, 0.6, 0.2)
	if tele and fmod(anim_t, 0.12) < 0.06:
		iris = Color(1, 1, 1)
	DU.glow(self, Vector2.ZERO, 140.0, Color(0.5, 0.15, 0.5), 0.35)
	# tentacules : effilés, à ventouses, deux couches
	for layer in 2:
		for i in 8:
			var a := i * TAU / 8.0 + sin(anim_t * 0.7) * 0.2 + layer * TAU / 16.0
			var pts := PackedVector2Array()
			for k in 10:
				var u := k / 9.0
				var r := 40.0 + u * (70.0 - layer * 18.0)
				var wob := sin(anim_t * 3.0 + i + u * 4.0 + layer) * 12.0 * u
				pts.append(Vector2.from_angle(a + wob * 0.01) * r + Vector2.from_angle(a + PI / 2) * wob)
			var tc := flesh.darkened(0.35) if layer == 0 else flesh
			for k in 9:
				var w := lerpf(11.0, 2.0, k / 8.0) * (0.8 if layer == 0 else 1.0)
				draw_line(pts[k], pts[k + 1], tc.darkened(0.4), w + 2.0)
				draw_line(pts[k], pts[k + 1], tc, w)
			if layer == 1:
				for k in range(2, 8, 2):
					var nrm := (pts[k + 1] - pts[k]).orthogonal().normalized()
					draw_circle(pts[k] + nrm * lerpf(4.0, 1.5, k / 8.0), lerpf(2.4, 1.0, k / 8.0), Color(0.85, 0.55, 0.7))
				draw_line(pts[1], pts[7], DU.lit(tc, 1.6, 0.05), 1.0)
	# chair autour du globe, veines
	DU.ball(self, Vector2.ZERO, 50.0, flesh)
	for i in 10:
		var a := i * TAU / 10.0 + 0.2
		draw_polyline(PackedVector2Array([Vector2.from_angle(a) * 42.0, Vector2.from_angle(a + 0.08) * 47.0, Vector2.from_angle(a - 0.05) * 51.0]), flesh.darkened(0.4), 1.4)
	# globe : blanc nacré, ombre, veines rouges
	DU.ball(self, Vector2.ZERO, 40.0, Color(0.92, 0.88, 0.8))
	draw_arc(Vector2.ZERO, 36.0, 0.2, PI - 0.2, 20, Color(0.55, 0.45, 0.5, 0.5), 7.0)
	for i in 7:
		var a2 := i * TAU / 7.0
		var v := PackedVector2Array([Vector2.from_angle(a2) * 38.0, Vector2.from_angle(a2 + 0.12) * 30.0, Vector2.from_angle(a2 + 0.05) * 22.0])
		draw_polyline(v, Color(0.8, 0.25, 0.3, 0.6), 1.4)
		draw_line(v[1], v[1] + Vector2.from_angle(a2 + 0.9) * 5.0, Color(0.8, 0.25, 0.3, 0.45), 1.0)
	# iris strié, pupille en fente, reflet
	DU.glow(self, look, 30.0, iris, 0.4)
	DU.ball(self, look, 18.0, iris)
	for i in 16:
		var a := i * TAU / 16.0
		draw_line(look + Vector2.from_angle(a) * 8.0, look + Vector2.from_angle(a) * 17.0, iris.darkened(0.35), 1.0)
	draw_arc(look, 17.5, 0.0, TAU, 24, iris.darkened(0.6), 1.6)
	DU.poly(self, DU.ellipse(look, Vector2(4.5 if not tele else 3.0, 14)), Color(0.05, 0.0, 0.05), false)
	draw_circle(look + Vector2(-7, -8), 3.4, Color(1, 1, 1, 0.75))
	draw_circle(look + Vector2(5, 7), 1.6, Color(1, 1, 1, 0.4))
	# paupières charnues (s'ouvrent en phase 2 ou quand il prépare un coup)
	var cover := (1.0 - lid) * 40.0
	if cover > 0.5:
		var R := 47.0
		for side: float in [-1.0, 1.0]:
			var ly := side * (44.0 - cover)          # bord de la paupière
			var half := sqrt(maxf(R * R - ly * ly, 4.0))
			var a0 := atan2(ly, -half)
			var a1 := atan2(ly, half)
			var pts := PackedVector2Array()
			var lash := PackedVector2Array()
			for k in 17:
				var t := k / 16.0
				var x := lerpf(-half, half, t)
				lash.append(Vector2(x, ly + side * -sin(t * PI) * 5.0))
			# arc du bord du globe, de droite à gauche en passant par le haut (ou le bas)
			for k in 17:
				pts.append(Vector2.from_angle(lerpf(a1, a0, k / 16.0)) * R)
			for k in range(lash.size()):
				pts.append(lash[k])
			DU.poly(self, pts, flesh if side < 0.0 else flesh.darkened(0.1))
			draw_polyline(lash, flesh.darkened(0.6), 2.4)
	# rayon
	var br := beam_rect()
	var bp := br.position - global_position
	if state == "windup_beam":
		var a3 := 0.25 + 0.25 * absf(sin(anim_t * 16.0))
		draw_line(Vector2(bp.x, bp.y + 9), Vector2(bp.x + br.size.x, bp.y + 9), Color(1.0, 0.4, 0.8, a3), 2.0)
		DU.glow(self, look, 40.0, Color(1.0, 0.4, 0.8), a3)
	if beam_t > 0.0:
		draw_rect(Rect2(bp - Vector2(0, 4), br.size + Vector2(0, 8)), Color(1.0, 0.4, 0.8, 0.25))
		draw_rect(Rect2(bp, br.size), Color(1.0, 0.45, 0.85, 0.75))
		draw_rect(Rect2(bp + Vector2(0, 5), Vector2(br.size.x, 8)), Color(1, 1, 1, 0.85))
		draw_line(look, Vector2(look.x, bp.y + 9), Color(1.0, 0.5, 0.85, 0.6), 6.0)
	draw_stun(-70.0)

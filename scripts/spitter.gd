extends "res://scripts/enemy.gd"
# Cracheur : champignon-bulbe immobile qui gonfle puis crache une spore vers le joueur.
# Astuce : une parade renvoie la spore.

const RANGE := 460.0
const SHOT_SPEED := 270.0
var cooldown := 0.0
var windup := 0.0
var facing := 1.0

func _ready() -> void:
	size = Vector2(30, 28)
	hp = 3
	geo_value = 4
	setup_body()
	cooldown = randf_range(0.8, 2.0)

func _physics_process(delta: float) -> void:
	anim_t += delta
	flash_t -= delta
	stun_t -= delta
	velocity.y = minf(velocity.y + 1800.0 * delta, 900.0)
	velocity.x = knock.x
	knock = knock.move_toward(Vector2.ZERO, 2000.0 * delta)
	var p = main.player
	if p and not p.dead and stun_t <= 0.0:
		var to: Vector2 = p.global_position - global_position
		facing = -1.0 if to.x < 0.0 else 1.0
		if to.length() < RANGE * minf(aggro(), 1.4):
			if windup > 0.0:
				windup -= delta
				if windup <= 0.0:
					_shoot(p.global_position + Vector2(0, -6))
			else:
				cooldown -= delta
				if cooldown <= 0.0:
					windup = 0.45 / sqrt(aggro())
					cooldown = randf_range(1.8, 2.6) / aggro()
	else:
		windup = 0.0
	move_and_slide()
	queue_redraw()

func _shoot(target: Vector2) -> void:
	var from := global_position + Vector2(facing * 10.0, -12.0)
	var dir := (target - from).normalized()
	main.spawn_projectile(from, dir * SHOT_SPEED * spd())
	if elite:   # élite : salve de 3 spores
		main.spawn_projectile(from, dir.rotated(0.28) * SHOT_SPEED * spd())
		main.spawn_projectile(from, dir.rotated(-0.28) * SHOT_SPEED * spd())
	Audio.sfx("spit", 0.1, -4.0)

func _draw() -> void:
	var opening := clampf((0.45 - windup) / 0.45, 0.0, 1.0) if windup > 0.0 else 0.0
	var breathe := sin(anim_t * 3.0) * 0.04
	var f := float(facing)
	var flash := windup > 0.0 and fmod(anim_t, 0.1) < 0.05
	var stem := body_color(Color(0.2, 0.34, 0.18))
	var leaf := body_color(Color(0.26, 0.45, 0.22))
	if stun_t > 0.0:
		stem = stem.darkened(0.35)
		leaf = leaf.darkened(0.35)
	# racines dans le sol
	for k in [-1.0, 0.0, 1.0]:
		draw_polyline(PackedVector2Array([Vector2(k * 3, 10), Vector2(k * 8, 13), Vector2(k * 13, 14)]), stem.darkened(0.3), 1.6)
	# grandes feuilles dentelées à la base
	for k in [-1.0, 1.0]:
		var sw := sin(anim_t * 2.0 + k) * 1.5
		var lf := PackedVector2Array([Vector2(k * 2, 12), Vector2(k * 9, 4 + sw), Vector2(k * 14, 3 + sw), Vector2(k * 21, 8 + sw), Vector2(k * 16, 9), Vector2(k * 19, 12), Vector2(k * 10, 13)])
		DU.poly(self, lf, leaf)
		draw_line(Vector2(k * 3, 12), Vector2(k * 18, 7 + sw), leaf.lightened(0.25), 1.0)
	# tige courbe
	var head := Vector2(f * 3, -6 + breathe * 20.0)
	var stem_pts := PackedVector2Array([Vector2(-3, 12), Vector2(-2.5, 4), head + Vector2(-f * 4, 6), head + Vector2(f * 3, 7), Vector2(2.5, 4), Vector2(3, 12)])
	DU.poly(self, stem_pts, stem)
	# gousse : deux mâchoires qui s'ouvrent pendant l'annonce
	var gape := 0.25 + opening * 0.65
	var pod := body_color(Color(0.55, 0.22, 0.3) if not flash else Color(0.85, 0.5, 0.9))
	var inner := Color(0.95, 0.55, 0.85) if windup > 0.0 else Color(0.5, 0.15, 0.25)
	DU.flat(self, DU.ellipse(head + Vector2(f * 3, 0), Vector2(8, 6 * gape + 1)), Color(0.12, 0.02, 0.06))
	if windup > 0.0:
		DU.glow(self, head + Vector2(f * 5, 0), 18.0, Color(0.9, 0.5, 1.0), 0.6)
		draw_circle(head + Vector2(f * 5, 0), 3.0 * (0.5 + opening), inner)
	for k: float in [-1.0, 1.0]:
		var rot: float = k * gape * 0.9
		var jaw := PackedVector2Array()
		for i in 11:
			var t := i / 10.0
			var a := PI + t * PI
			var pt := Vector2(cos(a) * 13.0, sin(a) * 8.0 * (1.0 if k < 0 else -1.0))
			jaw.append(head + Vector2(pt.x * -f, pt.y).rotated(rot * f))
		DU.poly(self, jaw, pod)
		# dents le long de la mâchoire
		for i in 4:
			var t := 0.2 + i * 0.18
			var a := PI + t * PI
			var base := head + Vector2(cos(a) * 12.0 * -f, sin(a) * 7.0 * (1.0 if k < 0 else -1.0)).rotated(rot * f)
			var tip := base + Vector2(0, -2.6 * (1.0 if k < 0 else -1.0)).rotated(rot * f)
			draw_line(base, tip, Color(0.95, 0.9, 0.78), 1.2)
		# taches pâles sur la gousse
		for i in 3:
			var a := PI + (0.3 + i * 0.2) * PI
			draw_circle(head + Vector2(cos(a) * 7.0 * -f, sin(a) * 4.0 * (1.0 if k < 0 else -1.0)).rotated(rot * f), 1.3, pod.lightened(0.35))
	draw_stun(-26.0)
